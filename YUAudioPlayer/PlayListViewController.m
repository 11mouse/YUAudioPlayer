//
//  PlayListViewController.m
//  YUAudioPlayer
//
//  Created by duan on 14-9-11.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "PlayListViewController.h"
#import "YUAudioPlayList.h"
#import "YUAudioDataLocal.h"

@interface PlayListViewController ()<UITableViewDataSource,UITableViewDelegate,YUAudioPlayListDataSource,YUAudioPlayListDelagate>
{
    UITableView *contentTableView;
    NSArray *musicArr;
    YUAudioPlayList *audioPlayList;
}
@end

@implementation PlayListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UISegmentedControl *segControl=[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"播放",@"下首",@"上首",@"暂停",@"停止",@"重载", nil]];
    segControl.frame=CGRectMake(0, 64, 320, 30);
    [segControl addTarget:self action:@selector(segControl_Events:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:segControl];
    
    musicArr=[NSArray arrayWithObjects:@"灿烂过.m4a",@"pcm测试.pcm",@"平凡之路.mp3",nil];
    contentTableView=[[UITableView alloc] initWithFrame:CGRectMake(0, 94, 320, self.view.frame.size.height-94)];
    contentTableView.dataSource=self;
    contentTableView.delegate=self;
    [self.view addSubview:contentTableView];
}

-(void)viewWillDisappear:(BOOL)animated
{
    if (audioPlayList) {
        [audioPlayList stop];
        audioPlayList=nil;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return musicArr.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    if (indexPath.row==audioPlayList.playIndex) {
        NSString *playStateStr=@"初始化";
        if (audioPlayList.state==YUAudioState_Waiting) {
            playStateStr=@"缓冲";
        }else if (audioPlayList.state==YUAudioState_Playing) {
            playStateStr=@"播放";
        }else if (audioPlayList.state==YUAudioState_Paused) {
            playStateStr=@"暂停";
        }else if (audioPlayList.state==YUAudioState_Stop) {
            playStateStr=@"停止";
        }
        cell.textLabel.text=[NSString stringWithFormat:@"%@ %@",[musicArr objectAtIndex:indexPath.row],playStateStr];
    }
    else{
        cell.textLabel.text=[musicArr objectAtIndex:indexPath.row];
    }
    
    return cell;
}

-(void)segControl_Events:(UISegmentedControl *)segControl{
    if (segControl.selectedSegmentIndex==0) {
        if (!audioPlayList) {
            audioPlayList=[[YUAudioPlayList alloc] init];
            audioPlayList.dataSource=self;
            audioPlayList.delegate=self;
        }
        [audioPlayList play];
    }else if (segControl.selectedSegmentIndex==1) {
        [audioPlayList next];
    }else if (segControl.selectedSegmentIndex==2) {
        [audioPlayList previous];
    }else if (segControl.selectedSegmentIndex==3) {
        [audioPlayList pause];
    }else if (segControl.selectedSegmentIndex==4) {
        [audioPlayList stop];
    }else if (segControl.selectedSegmentIndex==5) {
        musicArr=[NSArray arrayWithObjects:@"平凡之路.mp3",@"灿烂过.m4a",@"pcm测试.pcm", nil];
        [contentTableView reloadData];
        [audioPlayList reload];
    }
    segControl.selectedSegmentIndex=-1;
}

- (NSInteger)numOfItems:(YUAudioPlayList *)playList{
    return musicArr.count;
}
- (YUAudioDataBase *)playList:(YUAudioPlayList *)playList playIndex:(NSInteger)index{
    YUAudioDataLocal *audioData=[[YUAudioDataLocal alloc] init];
    NSString *path=[[NSBundle mainBundle] pathForResource:[musicArr objectAtIndex:index] ofType:nil];
    audioData.urlStr=path;
    return audioData;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [audioPlayList playAtIndex:indexPath.row];
}

-(void)playList:(YUAudioPlayList *)playList didPlayIndex:(NSInteger)index{
    [contentTableView reloadData];
}

-(void)playList:(YUAudioPlayList *)playList stateChanged:(YUAudioPlayerState)state error:(NSError *)error{
    [contentTableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
