//
//  YUAudioDataNT.m
//  YUAudioPlayer
//
//  Created by duan on 14-8-18.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "YUAudioDataNT.h"

#define Size_MinData

@interface YUAudioDataNT()<NSURLConnectionDelegate>
{
    NSURLConnection *connection;
    NSURLRequest *request;
    NSMutableData *currData;
    BOOL isContine;
    UInt64 fileSize;
    UInt64 seekOffset;
    UInt64 currDataSize;
}

@end

@implementation YUAudioDataNT

- (instancetype)init
{
    self = [super init];
    if (self) {
        fileSize=0;
        isContine=YES;
        seekOffset=0;
        currDataSize=0;
    }
    return self;
}

///开始
-(void)start{
    if (!connection&&self.urlStr) {
        if (self.audioDataDelegate) {
            [self.audioDataDelegate audioData_FileType:self fileType:[self hintForFileExtension:self.urlStr.pathExtension]];
        }
        [self performSelectorInBackground:@selector(startConnection) withObject:nil];
    }
}

-(void)cancel{
    if (connection) {
        [connection cancel];
        connection=nil;
        request=nil;
    }
}

-(void)seekToOffset:(UInt64)offset{
    isContine=NO;
    if (connection) {
        [connection cancel];
        connection=nil;
        request=nil;
    }
    
    seekOffset=offset;
    [self performSelectorInBackground:@selector(startConnection) withObject:nil];
}

-(void)startConnection{
    if (!connection&&self.urlStr) {
        NSMutableURLRequest *newRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.urlStr]];
        if (seekOffset>0) {
            [newRequest setValue:[NSString stringWithFormat:@"bytes=%llu-",seekOffset] forHTTPHeaderField:@"Range"];
        }
        request=newRequest;
        connection=[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        [connection start];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    fileSize=seekOffset+response.expectedContentLength;
    seekOffset=0;
    self.audioProperty.fileSize=fileSize;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    if (self.audioDataDelegate) {
        if (currDataSize==0) {
            isContine=NO;
        }
        [self.audioDataDelegate audioData_Arrived:self data:data contine:isContine];
        currDataSize=currDataSize+data.length;
        if (!isContine) {
            isContine=YES;
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self audioDataError:@"connect fail" userInfo:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    if (self.audioDataDelegate) {
        [self.audioDataDelegate audioData_Finished:self error:nil];
    }
}

- (void)dealloc
{
    
}

@end
