//
//  YUAudioFile.h
//  YUAudioPlayer
//
//  Created by duan on 14-8-25.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUAudioProperty.h"

@interface YUAudioFile : NSObject

@property(nonatomic,retain) NSString *recordUrlStr;
@property(nonatomic,retain) YUAudioProperty *audioProperty;

-(void)stop;

-(NSError*)writePackets:(UInt32)inNumBytes inPacketDescs:(const AudioStreamPacketDescription*)inPacketDescs inStartingPacket:(SInt64)inStartingPacket ioNumPackets:(UInt32*)ioNumPackets inBuffer:(const void*)inBuffer;
-(void)setEncoderCookie;


@end
