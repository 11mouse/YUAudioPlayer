//
//  YUAudioDataBase.h
//  YUAudioPlayer
//  音频数据源基类，提供了返回音频数据的协议，及供YUAudioPlayer控制的开始及取消方法
//  Created by duan on 14-8-18.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUAudioProperty.h"
@class YUAudioDataBase;

@protocol YUAudioDataDelegate <NSObject>
-(void) audioData_FileType:(YUAudioDataBase*)currAudioData fileType:(AudioFileTypeID)fileTypeHint;
-(void) audioData_Arrived:(YUAudioDataBase*)currAudioData data:(NSData*)data contine:(BOOL)isContine;
-(void) audioData_Finished:(YUAudioDataBase*)currAudioData error:(NSError*)error;
-(void) audioData_ShouldExit:(YUAudioDataBase*)currAudioData;
@end

@interface YUAudioDataBase : NSObject

@property(nonatomic,retain) NSString *urlStr;
@property(nonatomic,retain) YUAudioProperty* audioProperty;
@property(nonatomic,assign) id<YUAudioDataDelegate> audioDataDelegate;
@property(nonatomic) NSInteger audioVersion;

///开始
-(void)start;
///取消
-(void)cancel;

-(void)seekToOffset:(UInt64)offset;

- (AudioFileTypeID)hintForFileExtension:(NSString *)fileExtension;

-(void)audioDataError:(NSString*)errorDomain userInfo:(NSDictionary*)userInfo;
@end
