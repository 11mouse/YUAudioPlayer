//
//  YUAudioPlayList.h
//  YUAudioPlayer
//  播放列表类，提供播放列表功能，封装播放器，在列表播放中重用YUAudioPlayer，YUAudioProperty
//  Created by duan on 14-9-11.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YUAudioPlayer.h"
@protocol YUAudioPlayListDataSource;
@protocol YUAudioPlayListDelagate;

@interface YUAudioPlayList : NSObject

-(void)play;
-(void)playAtIndex:(NSInteger)index;
-(void)next;
-(void)previous;
-(void)pause;
-(void)stop;
-(void)reload;

@property(assign,nonatomic) id<YUAudioPlayListDataSource> dataSource;
@property(assign,nonatomic) id<YUAudioPlayListDelagate> delegate;
@property(assign,nonatomic,readonly) NSInteger playIndex;
@property(assign,nonatomic,readonly) NSInteger count;
@property(assign,nonatomic,readonly) YUAudioPlayerState state;

@end


@protocol YUAudioPlayListDataSource<NSObject>

@required
- (NSInteger)numOfItems:(YUAudioPlayList *)playList;
- (YUAudioDataBase *)playList:(YUAudioPlayList *)playList playIndex:(NSInteger)index;

@end

@protocol YUAudioPlayListDelagate<NSObject>

@required
- (void)playList:(YUAudioPlayList *)playList didPlayIndex:(NSInteger)index;
- (void)playList:(YUAudioPlayList *)playList stateChanged:(YUAudioPlayerState)state error:(NSError*)error;

@end
