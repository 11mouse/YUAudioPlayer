//
//  YUAudioDataBase.h
//  YUAudioPlayer
//  音频数据源基类，提供了返回音频数据的协议，及供YUAudioPlayer控制的开始及取消方法
//  Created by duan on 14-8-18.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUAudioProperty.h"
@protocol YUAudioDataDelegate <NSObject>
-(void) audioData_FileType:(AudioFileTypeID)fileTypeHint;
-(void) audioData_Arrived:(NSData*)data contine:(BOOL)isContine;
-(void) audioData_Finished:(NSError*)error;

@end

@interface YUAudioDataBase : NSObject

@property(nonatomic,retain) NSString *urlStr;
@property(nonatomic,retain) YUAudioProperty* audioProperty;
@property(nonatomic,assign) id<YUAudioDataDelegate> audioDataDelegate;

///开始
-(void)start;
///取消
-(void)cancel;

-(void)seekToOffset:(UInt64)offset;

- (AudioFileTypeID)hintForFileExtension:(NSString *)fileExtension;

-(void)audioDataError:(NSString*)errorDomain userInfo:(NSDictionary*)userInfo;
@end
