//
//  YUAudioProperty.m
//  YUAudioPlayer
//
//  Created by duan on 14-8-21.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "YUAudioProperty.h"

@implementation YUAudioProperty

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fileSize=0;
        _packetMaxSize=0;
    }
    return self;
}

@end
