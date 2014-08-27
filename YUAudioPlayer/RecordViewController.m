//
//  RecordViewController.m
//  YUAudioPlayer
//
//  Created by duan on 14-8-25.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "RecordViewController.h"
#import "YUAudioRecorder.h"
#define Length_RecordList 5
#define Time_Record 40
@interface RecordViewController ()
{
    UISegmentedControl *formatSeg;
    UISegmentedControl *sampleRateSeg;
    UISegmentedControl *bitsSeg;
    UISegmentedControl *channelsSeg;
    
    YUAudioRecorder *audioRecorder;
    
    YURecordFormat recordFormatList[Length_RecordList];
    NSTimer *recordTimer;
    double recordTime;
    NSInteger currFormatIndex;
}

@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor=[UIColor whiteColor];
    formatSeg=[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"pcm",@"aac",@"amr", nil]];
    formatSeg.frame=CGRectMake(0, 80, 320, 30);
    formatSeg.selectedSegmentIndex=0;
    [self.view addSubview:formatSeg];
    
    sampleRateSeg=[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"8000",@"16000",@"22050",@"32000",@"44100", nil]];
    sampleRateSeg.frame=CGRectMake(0, 115, 320, 30);
    sampleRateSeg.selectedSegmentIndex=0;
    [self.view addSubview:sampleRateSeg];
    
    bitsSeg=[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"8",@"16",@"24",@"32", nil]];
    bitsSeg.frame=CGRectMake(0, 150, 320, 30);
    bitsSeg.selectedSegmentIndex=0;
    [self.view addSubview:bitsSeg];
    
    channelsSeg=[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"1",@"2", nil]];
    channelsSeg.frame=CGRectMake(60, 185, 200, 30);
    channelsSeg.selectedSegmentIndex=0;
    [self.view addSubview:channelsSeg];
    
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(10, 235, 100, 30);
    [btn setTitle:@"录音" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnRecord_Events) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(10, 265, 100, 30);
    [btn setTitle:@"结束" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnStop_Events) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(10, 300, 100, 30);
    [btn setTitle:@"测试所有" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnAll_Events) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
//    YURecordFormat recordFormat=[YUAudioRecorder makeRecordFormat:44100 formatID:YUFormat_M4A bits:16 channel:2];
//    NSLog(@"%d",recordFormat.mChannelsPerFrame);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)btnRecord_Events{
    YUFormatID mFormatID=YUFormat_PCM;
    NSString *exeStr=@"pcm";
    switch (formatSeg.selectedSegmentIndex) {
        case 1:
            mFormatID=YUFormat_AAC;
            exeStr=@"m4a";
            break;
        case 2:
            mFormatID=YUFormat_AMR;
            exeStr=@"pcm";
            break;
        default:
            break;
    }
    
    Float64 mSampleRate=8000;
    switch (sampleRateSeg.selectedSegmentIndex) {
        case 1:
            mSampleRate=16000;
            break;
        case 2:
            mSampleRate=22050;
            break;
        case 3:
            mSampleRate=32000;
            break;
        case 4:
            mSampleRate=44100;
            break;
        default:
            break;
    }
    UInt32 mBitsPerChannel=8;
    if (bitsSeg.selectedSegmentIndex==1) {
        mBitsPerChannel=16;
    }else if (bitsSeg.selectedSegmentIndex==2) {
        mBitsPerChannel=24;
    }else if (bitsSeg.selectedSegmentIndex==3) {
        mBitsPerChannel=32;
    }
    UInt32 mChannelsPerFrame=1;
    if (channelsSeg.selectedSegmentIndex==1) {
        mChannelsPerFrame=2;
    }
    if (audioRecorder) {
        [audioRecorder stop];
        audioRecorder=nil;
    }
    if (!audioRecorder) {
        audioRecorder=[[YUAudioRecorder alloc] init];
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cacheDir = [paths objectAtIndex:0];
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    NSLog(@"%@",cacheDir);
    [dateformatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *timeStr=[dateformatter stringFromDate:[NSDate date]];
    NSString *pathStr=[NSString stringWithFormat:@"%@/%@.%@",cacheDir,timeStr,exeStr];
    [audioRecorder startWithUrl:pathStr withAudioDesc:[YUAudioRecorder makeRecordFormat:mSampleRate formatID:mFormatID bits:mBitsPerChannel channel:mChannelsPerFrame]];
}

-(void)btnStop_Events{
    if (audioRecorder) {
        [audioRecorder stop];
        audioRecorder=nil;
    }
    
}

-(void)btnAll_Events{
    if (recordTimer) {
        [recordTimer invalidate];
        recordTimer=nil;
        if (audioRecorder) {
            [audioRecorder stop];
            audioRecorder=nil;
        }
        
    }else
    {
        recordFormatList[0]=[YUAudioRecorder makeRecordFormat:8000 formatID:YUFormat_PCM bits:8 channel:1];
        recordFormatList[1]=[YUAudioRecorder makeRecordFormat:16000 formatID:YUFormat_PCM bits:8 channel:1];
        recordFormatList[2]=[YUAudioRecorder makeRecordFormat:8000 formatID:YUFormat_AAC bits:8 channel:1];
        recordFormatList[3]=[YUAudioRecorder makeRecordFormat:16000 formatID:YUFormat_AAC bits:8 channel:1];
        recordFormatList[4]=[YUAudioRecorder makeRecordFormat:8000 formatID:YUFormat_AMR bits:8 channel:1];
        
        currFormatIndex=0;
        recordTime=0;
        recordTimer=[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(recordTimer_Interval) userInfo:nil repeats:YES];
    }
}

-(void)recordTimer_Interval{
    if (!audioRecorder) {
        YURecordFormat recordFormat=recordFormatList[currFormatIndex];
        NSString *exeStr=@"pcm";
        switch (recordFormat.mFormatID) {
            case YUFormat_AAC:
                exeStr=@"aac";
                break;
            case YUFormat_AMR:
                exeStr=@"pcm";
                break;
            default:
                break;
        }
        audioRecorder=[[YUAudioRecorder alloc] init];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString* cacheDir = [paths objectAtIndex:0];
        if (currFormatIndex==0) {
            NSLog(@"%@",cacheDir);
        }
        NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
        [dateformatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *timeStr=[dateformatter stringFromDate:[NSDate date]];
        NSString *pathStr=[NSString stringWithFormat:@"%@/%@.%@",cacheDir,timeStr,exeStr];
        [audioRecorder startWithUrl:pathStr withAudioDesc:recordFormat];
    }
    recordTime=recordTime+0.1;
    if (recordTime>Time_Record) {
        NSString *recordUrl=audioRecorder.recordFilePath;
        recordTime=0;
        [audioRecorder stop];
        audioRecorder=nil;
        
        NSError *error;
        NSDictionary *fileAttDic=[[NSFileManager defaultManager] attributesOfItemAtPath:recordUrl error:&error];
        long fileSize=[[fileAttDic objectForKey:NSFileSize] longValue];
        YURecordFormat recordFormat=recordFormatList[currFormatIndex];
        NSLog(@"%@ %f %ld",recordUrl.lastPathComponent,recordFormat.mSampleRate,fileSize);
        
        currFormatIndex++;
        if (currFormatIndex==Length_RecordList) {
            [recordTimer invalidate];
            recordTimer=nil;
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
