//
//  YUAudioProperty.h
//  YUAudioPlayer
//
//  Created by duan on 14-8-21.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define Num_Buffers 3
#define Num_Descs 512
#define Size_DefaultBufferSize 2048

#define Dur_RecordBuffer 0.5
#define Size_RecordBufferSize 2048

typedef enum{
    YUState_Waiting=0,
    YUState_Playing,
    YUState_Paused,
    YUState_Stop
}YUAudioPlayerState;

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

@interface YUAudioProperty : NSObject

@property(nonatomic) UInt64 fileSize;
@property(nonatomic) UInt32 packetMaxSize;
@property(nonatomic) void* magicData;
@property(nonatomic) UInt32 cookieSize;
@property(nonatomic) YUAudioPlayerState state;
@property(nonatomic,retain) NSError* error;

@property(nonatomic) AudioStreamBasicDescription audioDesc;

@end
