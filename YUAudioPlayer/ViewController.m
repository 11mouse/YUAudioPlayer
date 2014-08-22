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
        NSString *path=[[NSBundle mainBundle] pathForResource:@"pfzl" ofType:@"mp3"];//[self GetAudioUrlFromQualityKey:@"2012070611fOV.m4a" quality:@"MM" cnd:@"cc.cdn.jing.fm"];//@"http://shoutmedia.abc.net.au:10326";//[[NSBundle mainBundle] pathForResource:@"2012070905LcV" ofType:@"m4a"];
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
        NSString *path=[self GetAudioUrlFromQualityKey:@"2012070611fOV.m4a" quality:@"MM" cnd:@"cc.cdn.jing.fm"];//[[NSBundle mainBundle] pathForResource:@"pfzl" ofType:@"mp3"];//@"http://shoutmedia.abc.net.au:10326";//[[NSBundle mainBundle] pathForResource:@"2012070905LcV" ofType:@"m4a"];
        audioPlayer=[[YUAudioPlayer alloc] init];
        audioPlayer.audioPlayerDelegate=self;
        [audioPlayer playWithUrl:path];
    }
    
}

-(void)btnDuration_Events:(UIButton*)btn{
    [btn setTitle:[NSString stringWithFormat:@"%f",audioPlayer.duration] forState:UIControlStateNormal];
}

-(NSString*)GetAudioUrlFromQualityKey:(NSString*)audioID quality:(NSString*)qualityKey cnd:(NSString*)cdn
{
    NSTimeInterval serverTimeInterval=[NSDate date].timeIntervalSince1970;
    NSString *str1=[audioID substringWithRange:NSMakeRange(0, 4)];
    NSString *str2=[audioID substringWithRange:NSMakeRange(4, 4)];
    NSString *str3=[audioID substringWithRange:NSMakeRange(8, 2)];
    NSString *str4=[audioID substringWithRange:NSMakeRange(10, 2)];
    NSString *currTimeStr=nil;
    NSString *uri=[NSString stringWithFormat:@"/%@/%@/%@/%@/%@%@",str1,str2,str3,str4,qualityKey,audioID];
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    
    [dateformatter setDateFormat:@"yyyyMMddHHmm"];
    dateformatter.timeZone=[NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSLocale *cnLocal=[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    [dateformatter setLocale:cnLocal];
    //    [cnLocal release];
    if (serverTimeInterval>0) {
        NSDate *serverDate=[NSDate dateWithTimeIntervalSince1970:serverTimeInterval];
        NSDate *bjDate=[serverDate dateByAddingTimeInterval:8*60*60];
        currTimeStr=[dateformatter stringFromDate:bjDate];
    }
    else
    {
        
        NSDate *gmtDate=[NSDate date];
        NSDate *bjDate=[gmtDate dateByAddingTimeInterval:8*60*60];
        currTimeStr=[dateformatter stringFromDate:bjDate];
    }
    //    [dateformatter release];
    NSString *key=nil;
    if ([@"cc.cdn.jing.fm" isEqualToString:cdn]) {
        key=@"Zwm8JCTa6x3YhVzL";
    }
    else
    {
        key=@"KupKVv)#4ktKufaT3&XmpV8dDENib)cq";
    }
    
    NSString *md5Str=[NSString stringWithFormat:@"%@%@%@",key,currTimeStr,uri];
    NSString *md5=[self md5:md5Str];
    NSString *url=[NSString stringWithFormat:@"http://%@/%@/%@%@",cdn,currTimeStr,md5,uri];
    return url;
}

- (NSString *) md5:(NSString*)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
