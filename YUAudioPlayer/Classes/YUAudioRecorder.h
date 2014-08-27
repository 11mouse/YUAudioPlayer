//
//  YUAudioRecorder.h
//  YUAudioPlayer
//
//  Created by duan on 14-8-25.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUAudioProperty.h"

@interface YUAudioRecorder : NSObject

@property(nonatomic,readonly) NSString* recordFilePath;

-(void)startWithUrl:(NSString*)fileUrlStr withAudioDesc:(YURecordFormat)recordDesc;
-(void)stop;

+(YURecordFormat) makeRecordFormat:(Float64)sampleRate formatID:(YUFormatID)formatID bits:(UInt32)bits channel:(UInt32) channel;

@end
