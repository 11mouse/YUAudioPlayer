//
//  YUAudioRecorder.m
//  YUAudioPlayer
//
//  Created by duan on 14-8-25.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "YUAudioRecorder.h"
#import "YUAudioQueue.h"
#import "YUAudioFile.h"

@interface YUAudioRecorder()<YUAudioQueueDelegate>
{
    YUAudioQueue *audioQueue;
    YUAudioFile *audioFile;
}
@property(nonatomic,retain) YUAudioProperty *audioProperty;

@end

@implementation YUAudioRecorder

- (instancetype)initWithAudioDesc:(YURecordFormat)recordDesc{
    self = [super init];
    if (self) {
        [self addObserver:self forKeyPath:@"audioProperty.error" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"audioProperty.error"])
    {
        if (self.audioProperty.error) {
            if (audioQueue) {
                [audioQueue stopRecord];
                audioQueue=nil;
            }
            if (audioFile) {
                [audioFile stop];
                audioFile=nil;
            }
            if (self.audioRecorderDelegate) {
                [self.audioRecorderDelegate audioRecorder_Error:self.audioProperty.error];
            }
            self.audioProperty=nil;
        }
        
    }
}

-(NSString *)recordFilePath{
    if (audioFile) {
        return audioFile.recordUrlStr;
    }
    return nil;
}

-(void)startWithUrl:(NSString*)fileUrlStr withAudioDesc:(YURecordFormat)recordDesc{
    if (audioQueue&&self.audioProperty&&audioFile) {
        [self stop];
    }
    if (!self.audioProperty) {
        self.audioProperty=[[YUAudioProperty alloc] init];
        AudioStreamBasicDescription audioDesc;
        audioDesc.mFormatID=recordDesc.mFormatID;
        if (recordDesc.mFormatID==YUFormat_AMR) {
            recordDesc.mSampleRate=8000;
            recordDesc.mChannelsPerFrame=1;
        }
        audioDesc.mSampleRate=recordDesc.mSampleRate;
        audioDesc.mChannelsPerFrame=recordDesc.mChannelsPerFrame;
        if (recordDesc.mFormatID==YUFormat_PCM) {
            audioDesc.mBitsPerChannel=recordDesc.mBitsPerChannel;
            audioDesc.mBytesPerPacket =(audioDesc.mBitsPerChannel / 8) * audioDesc.mChannelsPerFrame;
            audioDesc.mBytesPerFrame =audioDesc.mBytesPerPacket;
            audioDesc.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
            audioDesc.mFramesPerPacket=1;
        }
        if (recordDesc.mFormatID==YUFormat_AAC||recordDesc.mFormatID==YUFormat_AMR)
        {
            audioDesc.mBitsPerChannel=0;
            audioDesc.mFramesPerPacket=0;
            audioDesc.mBytesPerPacket =0;
            audioDesc.mBytesPerFrame=0;
            audioDesc.mReserved=0;
        }
        
        _audioProperty.audioDesc=audioDesc;
    }
    if (!audioQueue) {
        audioQueue=[[YUAudioQueue alloc] initWithAudioDesc:_audioProperty.audioDesc mode:YES];
        audioQueue.audioQueueDelegate=self;
        audioQueue.audioProperty=self.audioProperty;
    }
    if (!audioFile) {
        audioFile=[[YUAudioFile alloc] init];
        audioFile.recordUrlStr=fileUrlStr;
        audioFile.audioProperty=self.audioProperty;
        audioFile.recordUrlStr=fileUrlStr;
    }
    [audioQueue startRecord];
}

-(void)stop{
    if (audioQueue) {
        [audioQueue stopRecord];
        audioQueue=nil;
    }
    if (audioFile) {
        [audioFile stop];
        audioFile=nil;
    }
    self.audioProperty=nil;
}

-(NSError *)audioQueue_RecordPackets:(UInt32)inNumBytes inPacketDescs:(const AudioStreamPacketDescription *)inPacketDescs inStartingPacket:(SInt64)inStartingPacket ioNumPackets:(UInt32 *)ioNumPackets inBuffer:(const void *)inBuffer{
    return [audioFile writePackets:inNumBytes inPacketDescs:inPacketDescs inStartingPacket:inStartingPacket ioNumPackets:ioNumPackets inBuffer:inBuffer];
}

-(void)setEncoderCookie{
    [audioFile setEncoderCookie];
}


+(YURecordFormat) makeRecordFormat:(Float64)sampleRate formatID:(YUFormatID)formatID bits:(UInt32)bits channel:(UInt32) channel{
    struct YURecordFormat recordFormat;
    recordFormat.mSampleRate=sampleRate;
    recordFormat.mFormatID=formatID;
    recordFormat.mBitsPerChannel=bits;
    recordFormat.mChannelsPerFrame=channel;
    return recordFormat;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"audioProperty.error"];
}

@end
