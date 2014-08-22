//
//  YUAudioQueue.h
//  YUAudioPlayer
//
//  Created by duan on 14-8-18.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUAudioProperty.h"

@interface YUAudioQueue : NSObject

@property(nonatomic,readonly) double currentTime;
@property(nonatomic) double seekTime;
@property(nonatomic) BOOL loadFinished;
@property(nonatomic,retain) YUAudioProperty* audioProperty;
- (instancetype)initWithAudioDesc:(AudioStreamBasicDescription)audioDesc;

-(void)start;

-(void)pause;

-(void)stop;

-(void)enqueueBuffer:(NSData *)data packetNum:(UInt32)packetCount packetDescs:(AudioStreamPacketDescription *)inPacketDescs;

-(void)seeked;

@end
