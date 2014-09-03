//
//  YUAudioDataLocal.m
//  YUAudioPlayer
//
//  Created by duan on 14-8-18.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "YUAudioDataLocal.h"

@interface YUAudioDataLocal()
{
    NSFileHandle *filehandle;
    NSInteger readLength;
    UInt64 fileSize;
    UInt64 currOffset;
    NSTimer *fileTimer;
    BOOL isContine;
    UInt64 newOffset;
}

@end

@implementation YUAudioDataLocal

- (instancetype)init
{
    self = [super init];
    if (self) {
        readLength=4096;
        isContine=YES;
        newOffset=0;
    }
    return self;
}

///开始
-(void)start{
    if(!self.urlStr){
        return;
    }
    if (self.audioDataDelegate) {
        [self.audioDataDelegate audioData_FileType:[self hintForFileExtension:self.urlStr.pathExtension]];
    }
    NSThread *thread=[[NSThread alloc] initWithTarget:self selector:@selector(startTimer) object:nil];
    [thread start];
}

-(void)seekToOffset:(UInt64)offset{
    isContine=NO;
    newOffset=offset;
}

-(void)startTimer{
    if([[NSFileManager defaultManager] fileExistsAtPath:self.urlStr]){
        NSError *error;
        NSDictionary *fileAttDic=[[NSFileManager defaultManager] attributesOfItemAtPath:self.urlStr error:&error];
        fileSize=[[fileAttDic objectForKey:NSFileSize] longValue];
        if (fileSize>0) {
            self.audioProperty.fileSize=fileSize;
            filehandle=[NSFileHandle fileHandleForReadingAtPath:self.urlStr];
            currOffset=0;
            if (!fileTimer) {
                NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
                fileTimer=[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fileTimer_intval:) userInfo:nil repeats:YES];
                [runLoop run];
            }
        }
    }
    else{
        [self audioDataError:@"file not exists" userInfo:nil];
    }
}

///取消
-(void)cancel{
    if (fileTimer) {
        [fileTimer invalidate];
        fileTimer=nil;
    }
    if (filehandle) {
        [filehandle closeFile];
        filehandle=nil;
    }
}

-(void)fileTimer_intval:(NSTimer*)currTimer{
    if (!fileTimer) {
        return;
    }
    if (newOffset>0) {
        currOffset=newOffset;
    }
    UInt64 currReadLength=readLength;
    if (currOffset+readLength>fileSize) {
        currReadLength=fileSize-currOffset;
    }
    if (newOffset>0){
        [filehandle seekToFileOffset:newOffset];
        newOffset=0;
    }
    NSData* data=[filehandle readDataOfLength:(NSUInteger)currReadLength];
    if (self.audioDataDelegate&&fileTimer) {
        [self.audioDataDelegate audioData_Arrived:data contine:isContine];
    }
    currOffset+=readLength;
    if (currOffset>=fileSize) {
        if (fileTimer) {
            [fileTimer invalidate];
            fileTimer=nil;
        }
    }
    if (!isContine) {
        isContine=YES;
    }
    if (!fileTimer) {
        if (self.audioDataDelegate) {
            [self.audioDataDelegate audioData_Finished:nil];
            [filehandle closeFile];
            filehandle=nil;
        }
    }
}

- (void)dealloc
{
    
}

@end
