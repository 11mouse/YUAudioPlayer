//
//  YUAudioPlayList.m
//  YUAudioPlayer
//
//  Created by duan on 14-9-11.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "YUAudioPlayList.h"

@interface YUAudioPlayList()
{
    YUAudioPlayer *_audioPlayer;
}
@end

@implementation YUAudioPlayList

- (instancetype)init
{
    self = [super init];
    if (self) {
        _playIndex=0;
        _count=-1;
    }
    return self;
}

-(YUAudioPlayer *)currAudioPlayer{
    return _audioPlayer;
}

-(void)play{
    if (_audioPlayer) {
        [_audioPlayer play];
    }else{
        [self playAtIndex:_playIndex];
    }
    
}

-(void)playAtIndex:(NSInteger)index{
    if (_count<0) {
        if (_dataSource) {
            _count=[_dataSource numOfItems:self];
        }
    }
    if (index<0) {
        return;
    }
    if (index>=_count) {
        return;
    }
    _playIndex=index;
    if (_dataSource) {
        YUAudioDataBase *audioData=[_dataSource playList:self playIndex:_playIndex];
        if (!_audioPlayer) {
            _audioPlayer=[[YUAudioPlayer alloc] init];
        }
        [_audioPlayer playWithAudioData:audioData];
    }
}
-(void)next{
    [self playAtIndex:_playIndex+1];
}
-(void)previous{
    [self playAtIndex:_playIndex-1];
}
-(void)pause{
    if (_audioPlayer) {
        [_audioPlayer pause];
    }
}
-(void)stop{
    if (_audioPlayer) {
        [_audioPlayer stop];
        _audioPlayer=nil;
    }
}

-(void)reload{
    if (_dataSource) {
        _count=[_dataSource numOfItems:self];
    }
    _playIndex=0;
    [self playAtIndex:_playIndex];
}

- (void)dealloc
{
    
}

@end

