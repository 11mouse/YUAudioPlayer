//
//  SelectViewController.m
//  YUAudioPlayer
//
//  Created by duan on 14-8-25.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "SelectViewController.h"
#import "ViewController.h"
#import "RecordViewController.h"
#import "PlayListViewController.h"
@interface SelectViewController ()

@end

@implementation SelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor=[UIColor whiteColor];
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(10, 90, 100, 30);
    [btn setTitle:@"播放" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnPlay_Events) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(10, 150, 100, 30);
    [btn setTitle:@"录音" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnRecord_Events) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(10, 210, 100, 30);
    [btn setTitle:@"播放列表" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnPlayList_Events) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

-(void)btnPlay_Events{
    ViewController *viewController=[[ViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

-(void)btnRecord_Events{
    RecordViewController *recordViewController=[[RecordViewController alloc] init];
    [self.navigationController pushViewController:recordViewController animated:YES];
}

-(void)btnPlayList_Events{
    PlayListViewController *viewController=[[PlayListViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
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
