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
    //playmode parm
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
    
    //recordmode parm
    BOOL isRecordMode;
    UInt32 ioPacketNum;
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
        isRecordMode=NO;
    }
    return self;
}

- (instancetype)initWithAudioDesc:(AudioStreamBasicDescription)audioDesc mode:(BOOL)recordMode{
    if (isRecordMode) {
        self = [super init];
        if (self) {
            isRecordMode=YES;
        }
        return self;
    }else{
        self =[self initWithAudioDesc:audioDesc];
        return self;
    }
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

#pragma mark 播放: 开始 暂停 停止

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
    AudioQueueReset(audioQueue);
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

#define mark 播放: 缓冲区加入队列及播放结束

-(void)enqueueBuffer:(NSData *)data packetNum:(UInt32)packetCount packetDescs:(AudioStreamPacketDescription *)inPacketDescs{
    if (inPacketDescs) {
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
    else{
        size_t offset = 0;
        NSUInteger dataLength=data.length;
        while (dataLength)
        {
            size_t bufSpaceRemaining = bufferSize - currBufferFillOffset;
            if (bufSpaceRemaining < dataLength)
            {
                [self putBufferToQueue];
            }
            
            @synchronized(self)
            {
                if (isSeeking) {
                    return;
                }
                if (_audioProperty.state==YUState_Stop) {
                    return;
                }
                
                bufSpaceRemaining = bufferSize - currBufferFillOffset;
                size_t copySize;
                if (bufSpaceRemaining < dataLength)
                {
                    copySize = bufSpaceRemaining;
                }
                else
                {
                    copySize = dataLength;
                }
                if (currBufferFillOffset > bufferSize)
                {
                    return;
                }
                AudioQueueBufferRef fillBuf = audioQueueBuffer[currBufferIndex];
                memcpy((char*)fillBuf->mAudioData + currBufferFillOffset, (const char*)(data.bytes + offset), copySize);
                currBufferFillOffset += copySize;
                currBufferPacketCount = 0;
                dataLength -= copySize;
                offset += copySize;
            }
        }
    }
}

-(void)putBufferToQueue{
    if (userState==userPlay||userState==userInit) {
        [self audioStart];
    }
    
    AudioQueueBufferRef outBufferRef=audioQueueBuffer[currBufferIndex];
     OSStatus status;
    if (currBufferPacketCount>0) {
        status=AudioQueueEnqueueBuffer(audioQueue, outBufferRef, currBufferPacketCount, bufferDescs);
    }
    else{
        status=AudioQueueEnqueueBuffer(audioQueue, outBufferRef, 0, NULL);
    }
    if (status!=noErr)
    {
        NSError *error=[NSError errorWithDomain:@"AudioQueueBuffer Enqueue error" code:status userInfo:nil];
        _audioProperty.error=error;
//        [conditionLock signal];
//        [conditionLock unlock];
        return;
    }
    [conditionLock lock];
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

#pragma mark 录音: 开始 停止

-(void)startRecord{
    [self createRecordQueue];
    ioPacketNum=0;
    AudioQueueStart(audioQueue, NULL);
}

-(void)createRecordQueue{
    if (!audioQueue) {
        AudioStreamBasicDescription audioDesc=_audioProperty.audioDesc;
        OSStatus status=AudioQueueNewInput(&audioDesc,inputBufferHandler,(__bridge void *)(self),NULL, NULL,0, &audioQueue);
        if (status!=noErr) {
            
        }
        
        UInt32 size = sizeof(audioDesc);
        AudioQueueGetProperty(audioQueue, kAudioQueueProperty_StreamDescription,
                              &audioDesc, &size);
        _audioProperty.audioDesc=audioDesc;
        bufferSize=Size_RecordBufferSize;
        
        for (int i = 0; i < Num_Buffers; ++i) {
            OSStatus status= AudioQueueAllocateBuffer(audioQueue, bufferSize, &audioQueueBuffer[i]);
            if (status==noErr) {
                status=AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer[i], 0, NULL);
                if (status==noErr){
                    
                }
            }
        }
    }
}
 
-(void)stopRecord{
    if (audioQueue) {
        AudioQueueStop(audioQueue, true);
        AudioQueueDispose(audioQueue, true);
        audioQueue=nil;
    }
}

-(void)getEncoderCookieToFile
{
    UInt32 propertySize;
    OSStatus err = AudioQueueGetPropertySize(audioQueue, kAudioQueueProperty_MagicCookie, &propertySize);
    
    if (err == noErr && propertySize > 0) {
        void* cookieData = calloc(1, propertySize);
        UInt32 magicCookieSize;
        AudioQueueGetProperty(audioQueue, kAudioQueueProperty_MagicCookie, cookieData, &propertySize);
        _audioProperty.cookieSize=magicCookieSize;
        _audioProperty.magicData=cookieData;
        if (self.audioQueueDelegate) {
            [self.audioQueueDelegate setEncoderCookie];
        }
        free(cookieData);
    }
}


-(UInt32)recordBufferSize
{
    UInt32 packets, frames, bytes = 0;
    frames = (UInt32)ceil(Dur_RecordBuffer * _audioProperty.audioDesc.mSampleRate);
    
    if (_audioProperty.audioDesc.mBytesPerFrame > 0)
        bytes = frames * _audioProperty.audioDesc.mBytesPerFrame;
    else {
        UInt32 maxPacketSize;
        if (_audioProperty.audioDesc.mBytesPerPacket > 0)
            maxPacketSize = _audioProperty.audioDesc.mBytesPerPacket;
        else {
            UInt32 propertySize = sizeof(maxPacketSize);
            AudioQueueGetProperty(audioQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize,
                                  &propertySize);
        }
        if (_audioProperty.audioDesc.mFramesPerPacket > 0)
            packets = frames / _audioProperty.audioDesc.mFramesPerPacket;
        else
            packets = frames;
        if (packets == 0)
            packets = 1;
        bytes = packets * maxPacketSize;
    }
    return bytes;
}


void inputBufferHandler(void *inUserData,AudioQueueRef inAQ,AudioQueueBufferRef inBuffer,const AudioTimeStamp *          inStartTime,UInt32 inNumberPacketDescriptions,const AudioStreamPacketDescription *inPacketDescs)
{
    YUAudioQueue *audioQueue=(__bridge YUAudioQueue*)inUserData;
    [audioQueue inputBuffer:inAQ inBuffer:inBuffer inStartTime:inStartTime inNumberPacketDescriptions:inNumberPacketDescriptions inPacketDescs:inPacketDescs];
}

-(void)inputBuffer:(AudioQueueRef)inAQ inBuffer:(AudioQueueBufferRef)inBuffer inStartTime:(const AudioTimeStamp *)inStartTime inNumberPacketDescriptions:(UInt32)inNumberPacketDescriptions inPacketDescs:(const AudioStreamPacketDescription *)inPacketDescs{
    
    if (self.audioQueueDelegate) {
        [self.audioQueueDelegate audioQueue_RecordPackets:inBuffer->mAudioDataByteSize inPacketDescs:inPacketDescs inStartingPacket:ioPacketNum ioNumPackets:&inNumberPacketDescriptions inBuffer:inBuffer->mAudioData];
        ioPacketNum+=inNumberPacketDescriptions;
    }
    AudioQueueEnqueueBuffer(audioQueue, inBuffer, 0, NULL);
}

- (void)dealloc
{
    [self audioStop];
    [self cleanUp];
}

@end
