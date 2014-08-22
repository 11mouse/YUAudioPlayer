//
//  ViewController.m
//  YUAudioPlayer
//
//  Created by duan on 14-8-18.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "ViewController.h"
#import "YUAudioPlayer.h"
#import <CommonCrypto/CommonDigest.h>
@interface ViewController ()<YUAudioPlayerDelegate>
{
    YUAudioPlayer *audioPlayer;
    NSTimer *timer;
    UILabel *timeLabel;
    UILabel *stateLabel;
    UISlider *slider;
    UIButton *playBtn;
}
@end

@implementation ViewController
            
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(10, 90, 100, 30);
    [btn setTitle:@"播放本地" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnL_Events) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(200, 90, 100, 30);
    [btn setTitle:@"播放网络" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnN_Events) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(200, 120, 100, 30);
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnPause_Events) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    playBtn=btn;
    
    stateLabel=[[UILabel alloc] initWithFrame:CGRectMake(10, 150, 300, 30)];
    stateLabel.textColor=[UIColor blackColor];
    stateLabel.font=[UIFont systemFontOfSize:12];
    [self.view addSubview:stateLabel];
    
    timeLabel=[[UILabel alloc] initWithFrame:CGRectMake(10, 190, 300, 30)];
    timeLabel.textColor=[UIColor blackColor];
    timeLabel.font=[UIFont systemFontOfSize:12];
    [self.view addSubview:timeLabel];
    
    slider=[[UISlider alloc] initWithFrame:CGRectMake(10, 240, 300, 20)];
    [slider addTarget:self action:@selector(slider_Events) forControlEvents:UIControlEventTouchUpInside];
    slider.maximumValue=1;
    slider.minimumValue=0;
    [self.view addSubview:slider];
    
    timer=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timer_Interval) userInfo:nil repeats:YES];
}

-(void)audioPlayer_StateChanged:(YUAudioPlayerState)playerState error:(NSError*)error{
    NSMutableString *str=[NSMutableString string];
    if (playerState==YUState_Waiting) {
        [str appendString:@"缓冲"];
        [playBtn setTitle:@"" forState:UIControlStateNormal];
        playBtn.enabled=NO;
    }
    if (playerState==YUState_Paused) {
        [str appendString:@"暂停"];
        [playBtn setTitle:@"播放" forState:UIControlStateNormal];
        playBtn.enabled=YES;
    }
    if (playerState==YUState_Playing) {
        [str appendString:@"播放"];
        [playBtn setTitle:@"暂停" forState:UIControlStateNormal];
        playBtn.enabled=YES;
    }
    if (playerState==YUState_Stop) {
        [str appendString:@"停止"];
        [playBtn setTitle:@"" forState:UIControlStateNormal];
        playBtn.enabled=NO;
    }
    if (error) {
        [str appendString:error.domain];
    }
    stateLabel.text=str;
}

-(void)slider_Events{
    if (slider.value==0) {
        return;
    }
    [audioPlayer seekToTime:slider.value];
}

-(void)timer_Interval{
    timeLabel.text=[NSString stringWithFormat:@"%f / %f",audioPlayer.currentTime,audioPlayer.duration];
    slider.maximumValue=audioPlayer.duration;
    slider.minimumValue=0;
    slider.value=audioPlayer.currentTime;
}

-(void)btnPause_Events{
    if (audioPlayer&&audioPlayer.state==YUState_Playing) {
        [audioPlayer pause];
    }else
    if (audioPlayer&&audioPlayer.state==YUState_Paused) {
        [audioPlayer play];
    }
}

-(void)btnL_Events{
    if (audioPlayer) {
        [audioPlayer stop];
        audioPlayer=nil;
    }
    if (!audioPlayer) {
        NSString *path=[[NSBundle mainBundle] pathForResource:@"pfzl" ofType:@"mp3"];
        audioPlayer=[[YUAudioPlayer alloc] init];
        audioPlayer.audioPlayerDelegate=self;
        [audioPlayer playWithUrl:path];
    }
}

-(void)btnN_Events{
    if (audioPlayer) {
        [audioPlayer stop];
        audioPlayer=nil;
    }
    if (!audioPlayer) {
        NSString *path=@"http://music.baidu.com/data/music/file?link=http://yinyueshiting.baidu.com/data2/music/119386968/14945107241200128.mp3?xcode=e042ad9583729e93bb63d23e3b7c5dd51ab3ef6f35894a4f&song_id=14945107";
        audioPlayer=[[YUAudioPlayer alloc] init];
        audioPlayer.audioPlayerDelegate=self;
        [audioPlayer playWithUrl:path];
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
