//
//  YUAudioQueue.h
//  YUAudioPlayer
//
//  Created by duan on 14-8-18.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUAudioProperty.h"

@protocol YUAudioQueueDelegate <NSObject>

-(NSError*)audioQueue_RecordPackets:(UInt32)inNumBytes inPacketDescs:(const AudioStreamPacketDescription*)inPacketDescs inStartingPacket:(SInt64)inStartingPacket ioNumPackets:(UInt32*)ioNumPackets inBuffer:(const void*)inBuffer;
-(void)setEncoderCookie;
@end

@interface YUAudioQueue : NSObject

@property(nonatomic,readonly) double currentTime;
@property(nonatomic) double seekTime;
@property(nonatomic) BOOL loadFinished;
@property(nonatomic,retain) YUAudioProperty* audioProperty;
@property(nonatomic) id<YUAudioQueueDelegate> audioQueueDelegate;


- (instancetype)initWithAudioDesc:(AudioStreamBasicDescription)audioDesc;

- (instancetype)initWithAudioDesc:(AudioStreamBasicDescription)audioDesc mode:(BOOL)recordMode;

-(void)start;

-(void)pause;

-(void)stop;

-(void)enqueueBuffer:(NSData *)data packetNum:(UInt32)packetCount packetDescs:(AudioStreamPacketDescription *)inPacketDescs;

-(void)seeked;


-(void)startRecord;
-(void)stopRecord;

@end
