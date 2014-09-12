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
    BOOL exit;
    NSRunLoop *threadRunLoop;
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
        exit=NO;
    }
    return self;
}

///开始
-(void)start{
    if(!self.urlStr){
        return;
    }
    if (self.audioDataDelegate) {
        [self.audioDataDelegate audioData_FileType:self fileType:[self hintForFileExtension:self.urlStr.pathExtension]];
    }
    exit=NO;
//    [self performSelectorInBackground:@selector(startTimer) withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startTimer) toTarget:self withObject:nil];
    
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
                fileTimer=[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fileTimer_intval) userInfo:nil repeats:YES];
                threadRunLoop=[NSRunLoop currentRunLoop];
                [threadRunLoop run];
            }
        }
        else{
            [self audioDataError:@"file read error" userInfo:nil];
        }
    }
    else{
        [self audioDataError:@"file not exists" userInfo:nil];
    }
}

///取消
-(void)cancel{
    exit=YES;
    
}

-(void)fileTimer_intval{
    if (!fileTimer) {
        return;
    }
    if (exit) {
        if (fileTimer) {
            [fileTimer invalidate];
            fileTimer=nil;
        }
        if (filehandle) {
            [filehandle closeFile];
            filehandle=nil;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:Noti_AudioDataExited object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:self.audioVersion] forKey:@"audioVersion"]];
        if (self.audioDataDelegate) {
            [self.audioDataDelegate audioData_ShouldExit:self];
        }
        CFRunLoopStop([threadRunLoop getCFRunLoop]);//必须停止，要不线程一直不会被释放
        return;
    }
    if (!filehandle) {
        return;
    }
    if (newOffset>0) {
        currOffset=newOffset;
    }
    UInt64 currReadLength=readLength;
    if (currOffset+readLength>fileSize) {
        currReadLength=fileSize-currOffset;
    }
    if (currOffset==0) {
        isContine=NO;
    }
    if (newOffset>0){
        [filehandle seekToFileOffset:newOffset];
        newOffset=0;
    }
    NSData* data=[filehandle readDataOfLength:(NSUInteger)currReadLength];
    if (self.audioDataDelegate&&fileTimer) {
        [self.audioDataDelegate audioData_Arrived:self data:data contine:isContine];
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
            [self.audioDataDelegate audioData_Finished:self error:nil];
            [filehandle closeFile];
            filehandle=nil;
        }
    }
}

- (void)dealloc
{
    
}

@end
