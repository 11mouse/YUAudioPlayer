//
//  YUAudioQueue.m
//  YUAudioPlayer
//
//  Created by duan on 14-8-18.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "YUAudioQueue.h"

typedef enum {
    userInit=0,
    userPlay,
    userPause,
    userStop
}AudioUserState;

@interface YUAudioQueue()
{
    AudioQueueRef audioQueue;
    AudioQueueBufferRef audioQueueBuffer[Num_Buffers];
    bool bufferUserd[Num_Buffers];
    AudioStreamPacketDescription bufferDescs[Num_Descs];
    UInt32 bufferSize;
    UInt32 currBufferIndex;
    UInt32 currBufferFillOffset;
    UInt32 currBufferPacketCount;
    NSCondition *conditionLock;
    UInt32 bufferUseNum;
    BOOL isStart;
    BOOL isSeeking;
    AudioUserState userState;
}
@property(nonatomic) AudioStreamBasicDescription audioDesc;
@end
@implementation YUAudioQueue

#pragma mark 初始化

- (instancetype)initWithAudioDesc:(AudioStreamBasicDescription)audioDesc
{
    self = [super init];
    if (self) {
        self.audioDesc=audioDesc;
        conditionLock=[[NSCondition alloc] init];
        _seekTime=0;
        isStart=NO;
        isSeeking=NO;
        _loadFinished=NO;
        userState=userInit;
    }
    return self;
}

-(void)createQueue{
    if(!audioQueue){
        OSStatus status = AudioQueueNewOutput (&_audioDesc,audioQueueOutputCallback,(__bridge void *)(self),NULL,NULL,0,&audioQueue);
        if (status!=noErr) {
             NSError *error=[NSError errorWithDomain:@"AudioQueue init error" code:status userInfo:nil];
            _audioProperty.error=error;
            return;
        }
        AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, audioQueueIsRunningCallback, (__bridge void *)(self));
        currBufferIndex=0;
        currBufferFillOffset=0;
        currBufferPacketCount=0;
        bufferUseNum=0;
        if (_audioProperty.cookieSize>0) {
            AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie,_audioProperty.magicData, _audioProperty.cookieSize);
        }
        
        [self initQueueBuffer];
    }
}

-(void)initQueueBuffer{
    if (_audioProperty.packetMaxSize==0) {
        bufferSize=Size_DefaultBufferSize;
    }
    else{
        bufferSize=_audioProperty.packetMaxSize;
    }
    
    for (unsigned int i = 0; i < Num_Buffers; ++i)
    {
        OSStatus status = AudioQueueAllocateBuffer(audioQueue, bufferSize, &audioQueueBuffer[i]);
        if (status!=noErr)
        {
            NSError *error=[NSError errorWithDomain:@"AudioQueueBuffer alloc Error" code:status userInfo:nil];
            _audioProperty.error=error;
            return;
        }
    }
}

#pragma mark 开始 暂停 停止

-(void)start{
    _audioProperty.state=YUState_Playing;
    if (!audioQueue) {
        [self createQueue];
    }
    userState=userPlay;
    [self audioStart];
}

-(void)audioStart{
    if (!isStart){
        OSStatus  status=AudioQueueStart(audioQueue, NULL);
        if (status!=noErr)
        {
            NSError *error=[NSError errorWithDomain:@"AudioQueue Start Error" code:status userInfo:nil];
            _audioProperty.error=error;
            return;
        }
        isStart=YES;
    }
}

-(void)pause{
    _audioProperty.state=YUState_Paused;
    userState=userPause;
    [self audioPause];
}

-(void)audioPause{
    if (isStart){
        OSStatus status= AudioQueuePause(audioQueue);
        if (status!=noErr)
        {
            NSError *error=[NSError errorWithDomain:@"AudioQueue Pause Error" code:status userInfo:nil];
            _audioProperty.error=error;
            return;
        }
        isStart=NO;
    }
}

-(void)stop{
    _audioProperty.state=YUState_Stop;
    userState=userStop;
    [self audioStop];
    [self cleanUp];
}

-(void)audioStop{
    isStart=NO;
    OSStatus status= AudioQueueStop(audioQueue, true);
    if (status!=noErr)
    {
        NSError *error=[NSError errorWithDomain:@"AudioQueue stop error" code:status userInfo:nil];
        _audioProperty.error=error;
        return;
    }
}

-(double)currentTime{
    AudioTimeStamp queueTime;
    Boolean discontinuity;
    OSStatus status = AudioQueueGetCurrentTime(audioQueue, NULL, &queueTime, &discontinuity);
    if (status!=noErr) {
        return 0;
    }
    else{
        return _seekTime+ queueTime.mSampleTime/self.audioDesc.mSampleRate;
    }
}
-(void)setSeekTime:(double)seekTime{
    _seekTime=seekTime;
    isSeeking=YES;
    [conditionLock lock];
    [conditionLock signal];
    [conditionLock unlock];
    [self stop];
}

-(void)seeked
{
    isSeeking=NO;
    [conditionLock lock];
    for (NSInteger i=0;i<Num_Buffers;i++) {
        bufferUserd[i]=false;
    }
    currBufferPacketCount=0;
    currBufferFillOffset=0;
    bufferUseNum=0;
    currBufferIndex=0;
    [conditionLock signal];
    [conditionLock unlock];
}

-(void)cleanUp{
    if (audioQueue) {
        AudioQueueRemovePropertyListener(audioQueue, kAudioQueueProperty_IsRunning, audioQueueIsRunningCallback, (__bridge void *)(self));
        for (NSInteger i=0;i<Num_Buffers;i++) {
            AudioQueueFreeBuffer(audioQueue, audioQueueBuffer[i]);
        }
        AudioQueueDispose(audioQueue, true);
        audioQueue=NULL;
    }
    currBufferPacketCount=0;
    currBufferFillOffset=0;
    bufferUseNum=0;
    currBufferIndex=0;
    userState=userInit;
    [conditionLock lock];
    [conditionLock signal];
    [conditionLock unlock];
}

#define mark 缓冲区加入队列及播放结束

-(void)enqueueBuffer:(NSData *)data packetNum:(UInt32)packetCount packetDescs:(AudioStreamPacketDescription *)inPacketDescs{
    for (NSInteger i=0;i<packetCount;i++) {
        if (isSeeking) {
            return;
        }
        AudioStreamPacketDescription packetDesc=inPacketDescs[i];
        if (currBufferFillOffset+packetDesc.mDataByteSize>=bufferSize) {
            [self putBufferToQueue];
        }
        if (isSeeking) {
            return;
        }
        if (_audioProperty.state==YUState_Stop) {
            return;
        }
        AudioQueueBufferRef outBufferRef=audioQueueBuffer[currBufferIndex];
        memcpy(outBufferRef->mAudioData+currBufferFillOffset, data.bytes+packetDesc.mStartOffset, packetDesc.mDataByteSize);
        outBufferRef->mAudioDataByteSize=currBufferFillOffset+packetDesc.mDataByteSize;
        bufferDescs[currBufferPacketCount]=packetDesc;
        bufferDescs[currBufferPacketCount].mStartOffset=currBufferFillOffset;
        currBufferFillOffset=currBufferFillOffset+packetDesc.mDataByteSize;
        
        currBufferPacketCount++;
    }
}

-(void)putBufferToQueue{
    if (userState==userPlay||userState==userInit) {
        [self audioStart];
    }
    [conditionLock lock];
    AudioQueueBufferRef outBufferRef=audioQueueBuffer[currBufferIndex];
     OSStatus status= AudioQueueEnqueueBuffer(audioQueue, outBufferRef, currBufferPacketCount, bufferDescs);
    if (status!=noErr)
    {
        NSError *error=[NSError errorWithDomain:@"AudioQueueBuffer Enqueue error" code:status userInfo:nil];
        _audioProperty.error=error;
        [conditionLock unlock];
        return;
    }
    bufferUseNum++;
   bufferUserd[currBufferIndex]=true;
    currBufferIndex++;
    
    if (currBufferIndex>=Num_Buffers) {
        currBufferIndex=0;
    }
    
    currBufferPacketCount=0;
    currBufferFillOffset=0;
    
    while (bufferUserd[currBufferIndex]) {
        [conditionLock wait];
    }
    [conditionLock unlock];
}

void audioQueueOutputCallback (void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    
    YUAudioQueue *audioQueue=(__bridge YUAudioQueue*)inUserData;
    [audioQueue audioQueueOutput:inAQ inBuffer:inBuffer];
}

-(void)audioQueueOutput:(AudioQueueRef)inAQ inBuffer:(AudioQueueBufferRef)inBuffer{
    
     [conditionLock lock];
    NSInteger index=-1;
    for (NSInteger i=0;i<Num_Buffers;i++) {
        if (audioQueueBuffer[i]==inBuffer) {
            index=i;
            break;
        }
    }
    if (bufferUseNum-1==0) {
        if (_loadFinished) {
            [self audioStop];
            [self cleanUp];
        }else{
            [self audioPause];
        }
    }
    
    if (index==-1) {
        [conditionLock signal];
        [conditionLock unlock];
        return;
    }
    
    
    bufferUserd[index]=false;
    bufferUseNum--;
    [conditionLock signal];
    [conditionLock unlock];
}

void audioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
    YUAudioQueue *audioQueue=(__bridge YUAudioQueue*)inUserData;
    [audioQueue audioQueueIsRunning:inID];
}

-(void)audioQueueIsRunning:(AudioQueuePropertyID)inID{
    UInt32 isRunning = 0;
    UInt32 size = sizeof(UInt32);
    AudioQueueGetProperty(audioQueue, inID, &isRunning, &size);
    if (isRunning == 0)
    {
        //NSLog(@"停止");
    }else{
        //NSLog(@"运行");
    }
}

- (void)dealloc
{
    [self audioStop];
    [self cleanUp];
}

@end
