//
//  YUAudioProperty.m
//  YUAudioPlayer
//
//  Created by duan on 14-8-21.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "YUAudioProperty.h"

@interface YUAudioProperty(){
    NSDictionary *errorDic;
}
@end

@implementation YUAudioProperty

- (instancetype)init
{
    self = [super init];
    if (self) {
        _state=YUAudioState_Init;
        _fileSize=0;
        _packetMaxSize=0;
        errorDic=[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"YUAudioError" ofType:@"plist"]];
    }
    return self;
}

-(void)setState:(YUAudioPlayerState)state{
    if (_state!=state) {
        _state=state;
        if (_audioPropertyDelegate) {
            [_audioPropertyDelegate audioProperty_StateChanged:_state];
        }
    }
}

-(void)setError:(NSError *)error{
    _error=error;
    if (_error&&_audioPropertyDelegate) {
        [_audioPropertyDelegate audioProperty_Error:_error];
    }
}

-(void)error:(YUAudioError)errorType{
    if (!errorDic&&![errorDic objectForKey:[NSString stringWithFormat:@"%d",errorType]]) {
        self.error=[NSError errorWithDomain:@"no desc" code:errorType userInfo:nil];
    }else{
        self.error=[NSError errorWithDomain:[errorDic objectForKey:[NSString stringWithFormat:@"%d",errorType]] code:errorType userInfo:nil];
    }
}

-(NSString*)errorDomaim:(YUAudioError)errorType{
    if (!errorDic&&![errorDic objectForKey:[NSString stringWithFormat:@"%d",errorType]]) {
        return @"";
    }else{
        return [errorDic objectForKey:[NSString stringWithFormat:@"%d",errorType]];
    }
}

-(void)clean{
    self.fileSize=0;
    self.packetMaxSize=0;
    self.magicData=NULL;
    self.cookieSize=0;
    self.state=YUAudioState_Init;
    self.error=nil;
}

- (void)dealloc
{
    
}

@end
