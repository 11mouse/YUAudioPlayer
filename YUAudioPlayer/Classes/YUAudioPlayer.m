//
//  YUAudioPlayer.m
//  YUAudioPlayer
//
//  Created by duanjitong on 14-8-18.
//  Copyright (c) 2014年 duanjitong. All rights reserved.
//

#import "YUAudioPlayer.h"
#import "YUAudioDataNT.h"
#import "YUAudioDataLocal.h"
#import "YUAudioQueue.h"
#import "YUAudioStream.h"

@interface YUAudioPlayer()<YUAudioDataDelegate,YUAudioStreamDelegate>{
    
}
@property(nonatomic,retain) YUAudioDataBase *audioData;
@property(nonatomic,retain) YUAudioQueue *audioQueue;
@property(nonatomic,retain) YUAudioStream *audioStream;
@property(nonatomic,retain) YUAudioProperty* audioProperty;
@end

@implementation YUAudioPlayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.audioProperty=[[YUAudioProperty alloc] init];
        [self addObserver:self forKeyPath:@"audioProperty.state" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
        [self addObserver:self forKeyPath:@"audioProperty.error" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"audioProperty.state"])
    {
        if (self.audioPlayerDelegate) {
            [self.audioPlayerDelegate audioPlayer_StateChanged:_audioProperty.state error:_audioProperty.error];
            if (_audioProperty.error) {
                _audioProperty.error=nil;
            }
        }
    }
    if([keyPath isEqualToString:@"audioProperty.error"])
    {
        if (_audioProperty.error) {
            [self performSelectorOnMainThread:@selector(stop) withObject:nil waitUntilDone:NO];
        }
        
    }
}

#pragma mark Play Pause Stop


-(void) playWithUrl:(NSString*)urlStr{
    YUAudioDataBase *audioData;
    if([urlStr.lowercaseString hasPrefix:@"http"]){
        audioData=[[YUAudioDataNT alloc] init];
    }else{
        audioData=[[YUAudioDataLocal alloc] init];
    }
    audioData.urlStr=urlStr;
    [self playWithAudioData:audioData];
}

-(void) playWithAudioData:(YUAudioDataBase*)audioData{
    if(!audioData){
        ///播放错误
        return;
    }
    self.audioData=audioData;
    self.audioData.audioProperty=self.audioProperty;
    self.audioData.audioDataDelegate=self;
    [self.audioData start];
    _audioProperty.state=YUState_Waiting;
}

-(void)play{
    if (_audioQueue) {
        [_audioQueue start];
    }
}

-(void)pause{
    if (_audioQueue) {
        [_audioQueue pause];
    }
}

-(void)stop{
    if (_audioQueue) {
        [_audioQueue stop];
    }
    if (_audioData) {
        _audioData.audioDataDelegate=nil;
        [_audioData cancel];
    }
    if (_audioStream) {
        _audioStream.audioStreamDelegate=nil;
        [_audioStream close];
    }
}

-(void)seekToTime:(double)seekToTime{
    if (!_audioStream) {
        return;
    }
    if (!_audioQueue) {
        return;
    }
    [_audioStream getSeekToOffset:seekToTime];
    _audioQueue.seekTime=self.audioStream.seekTime;
    __block YUAudioPlayer *gcdSelf=self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [gcdSelf.audioData seekToOffset:gcdSelf.audioStream.seekByteOffset];
    });
}

-(double)duration{
    if (!_audioStream) {
        return 0;
    }
    return _audioStream.duration;
}

-(double)currentTime{
    if (!_audioQueue) {
        return 0;
    }
    return _audioQueue.currentTime;
}

-(YUAudioPlayerState)state{
    return _audioProperty.state;
}

#pragma mark YUAudioDataDelegate

-(void)audioData_FileType:(AudioFileTypeID)fileTypeHint{
    if (!_audioStream) {
        self.audioStream=[[YUAudioStream alloc] initWithFileType:fileTypeHint];
        _audioStream.audioProperty=self.audioProperty;
        _audioStream.audioStreamDelegate=self;
    }
}

-(void)audioData_Arrived:(NSData *)data contine:(BOOL)isContine{
    UInt32 flags=0;
    if (!isContine) {
        flags=kAudioFileStreamParseFlag_Discontinuity;
        [self.audioQueue seeked];
    }
    [self.audioStream audioStreamParseBytes:data flags:flags];
}

-(void)audioData_Finished:(NSError *)error{
    if (_audioQueue) {
        _audioQueue.loadFinished=YES;
    }
}

#pragma mark YUAudioStreamDelegate

-(void)audioStream_audioDesc{
    if (!self.audioQueue) {
        self.audioQueue=[[YUAudioQueue alloc] initWithAudioDesc:self.audioStream.audioDesc];
        _audioQueue.audioProperty=self.audioProperty;
    }
}

-(void)audioStream_ReadyToProducePackets{
    [self.audioQueue start];
}

-(void)audioStream_Packets:(NSData *)data packetNum:(UInt32)packetCount packetDescs:(AudioStreamPacketDescription *)inPacketDescs{
    [self.audioQueue enqueueBuffer:data packetNum:packetCount packetDescs:inPacketDescs];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"audioProperty.state"];
    [self removeObserver:self forKeyPath:@"audioProperty.error"];
}

@end
