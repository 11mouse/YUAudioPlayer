//
//  YUAudioPlayer.h
//  YUAudioPlayer
//  播放器类，提供音频播放功能，作为YUAudioQueue,YUAudioStream,YUAudioData,YUAudioProperty的中转组织者
//  Created by duan on 14-8-18.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUAudioDataBase.h"
#import "YUAudioProperty.h"

@protocol YUAudioPlayerDelegate <NSObject>

-(void)audioPlayer_StateChanged:(YUAudioPlayerState)playerState error:(NSError*)error;

@end

@interface YUAudioPlayer : NSObject

@property(nonatomic,readonly) double duration;
@property(nonatomic,readonly) double currentTime;
@property(nonatomic,readonly) YUAudioPlayerState state;
@property(nonatomic,assign) id<YUAudioPlayerDelegate> audioPlayerDelegate;

-(void) playWithUrl:(NSString*)urlStr;

-(void) playWithAudioData:(YUAudioDataBase*)audioData;

-(void)play;
-(void)pause;
-(void)stop;

-(void)seekToTime:(double)seekToTime;

@end
