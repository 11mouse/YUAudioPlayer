//
//  YUAudioStream.h
//  YUAudioPlayer
//  音频流类。接收来自音频数据源YUAudioData的数据流解析为音频帧，然后转发给YUAudioQueue播放
//  Created by duan on 14-8-18.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUAudioProperty.h"

@protocol YUAudioStreamDelegate <NSObject>

-(void)audioStream_ReadyToProducePackets;

-(void)audioStream_Packets:(NSData*)data packetNum:(UInt32)packetCount packetDescs:(AudioStreamPacketDescription *)inPacketDescs;

@end

@interface YUAudioStream : NSObject

- (instancetype)initWithFileType:(AudioFileTypeID)fileTypeID;

@property(nonatomic) AudioStreamBasicDescription audioDesc;

@property(nonatomic,readonly) double duration;
@property(nonatomic,assign) id<YUAudioStreamDelegate> audioStreamDelegate;
@property(nonatomic,retain) YUAudioProperty* audioProperty;
@property(nonatomic) UInt64 seekByteOffset;
@property(nonatomic) double seekTime;
@property(nonatomic) NSInteger audioVersion;

-(void)audioStreamParseBytes:(NSData*)data flags:(UInt32)flags;

-(void)getSeekToOffset:(double)seekToTime;

-(void)close;

@end
