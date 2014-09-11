//
//  YUAudioRecorder.h
//  YUAudioPlayer
//  录音类，提供音频录制功能，作为YUAudioQueue,YUAudioFile的中转组织者
//  Created by duan on 14-8-25.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUAudioProperty.h"

@protocol YUAudioRecorderDelegate <NSObject>

-(void)audioRecorder_Error:(NSError*)error;

@end

@interface YUAudioRecorder : NSObject

@property(nonatomic,readonly) NSString* recordFilePath;
@property(nonatomic,assign) id<YUAudioRecorderDelegate> audioRecorderDelegate;

-(void)startWithUrl:(NSString*)fileUrlStr withAudioDesc:(YURecordFormat)recordDesc;
-(void)stop;

+(YURecordFormat) makeRecordFormat:(Float64)sampleRate formatID:(YUFormatID)formatID bits:(UInt32)bits channel:(UInt32) channel;

@end
