//
//  YUAudioProperty.h
//  YUAudioPlayer
//  音频属性类，包含音频属性、错误处理、播放状态，及枚举和宏的定义
//  Created by duan on 14-8-21.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define Num_Buffers 16 //缓冲区数量
#define Num_Descs 512 //复用的包描述数量
#define Size_DefaultBufferSize 2048 //默认缓冲区大小

#define Dur_RecordBuffer 0.5 //录音每次时间
#define Size_RecordBufferSize 2048 //录音缓冲区默认大小

#define Noti_AudioDataExited @"Noti_AudioDataExited"

typedef enum{
    YUAudioState_Init=0,
    YUAudioState_Waiting,
    YUAudioState_Playing,
    YUAudioState_Paused,
    YUAudioState_Stop
}YUAudioPlayerState;

typedef enum{
    YUAudioError_noErr=0,
    YUAudioError_AD_Nil,
    YUAudioError_AQ_InitFail,
    YUAudioError_AQB_AllocFail,
    YUAudioError_AQ_StartFail,
    YUAudioError_AQ_PauseFail,
    YUAudioError_AQ_StopFail,
    YUAudioError_AQB_EnqueueFail,
    YUAudioError_AQR_StartFail,
    YUAudioError_AQR_InitFail,
    YUAudioError_AQR_EnqueueBufferFail,
    YUAudioError_AFS_OpenFail,
    YUAudioError_AFS_ParseFail,
    YUAudioError_AF_CreateFail,
    YUAudioError_AF_PacketWriteFail,
    YUAudioError_AD_CustomError
}YUAudioError;//AD:AudioData; AQ:AudioQueue; AQB:AudioQueue Buffer;
//AQR:AQB:AudioQueue Record; AFS:AudioFileStream; AF:AudioFile

typedef enum{
    YUFormat_PCM= 'lpcm',
    YUFormat_AAC= 'aac ',
    YUFormat_AMR= 'samr'
}YUFormatID;

typedef struct YURecordFormat{
    Float64             mSampleRate;
    YUFormatID       mFormatID;
    UInt32              mBitsPerChannel;
    UInt32              mChannelsPerFrame;
}YURecordFormat;

@protocol YUAudioPropertyDelegate <NSObject>

-(void)audioProperty_Error:(NSError*)error;
-(void)audioProperty_StateChanged:(YUAudioPlayerState)state;

@end

@interface YUAudioProperty : NSObject

@property(nonatomic) UInt64 fileSize;
@property(nonatomic) UInt32 packetMaxSize;
@property(nonatomic) void* magicData;
@property(nonatomic) UInt32 cookieSize;
@property(nonatomic) YUAudioPlayerState state;
@property(nonatomic,retain) NSError* error;
@property(nonatomic) id<YUAudioPropertyDelegate> audioPropertyDelegate;
@property(nonatomic) AudioStreamBasicDescription audioDesc;

-(void)error:(YUAudioError)errorType;
-(NSString*)errorDomaim:(YUAudioError)errorType;
-(void)clean;

@end
