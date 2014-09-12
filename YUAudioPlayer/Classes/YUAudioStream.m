//
//  YUAudioStream.m
//  YUAudioPlayer
//
//  Created by duan on 14-8-18.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "YUAudioStream.h"

#define BitRateEstimationMaxPackets 5000
#define BitRateEstimationMinPackets 50

@interface YUAudioStream()
{
    AudioFileStreamID _audioFileStreamID;
    NSInteger packetCount;
    NSInteger packetDataSize;
    NSInteger bitRate;
    NSInteger dataOffset;
    double packetDuration;
    BOOL isSeeking;
    BOOL shouldExit;
}

@end
@implementation YUAudioStream

- (instancetype)init
{
    self = [super init];
    if (self) {
        packetCount=0;
        packetDataSize=0;
        bitRate=0;
        dataOffset=0;
        packetDuration=0;
        isSeeking=NO;
//        NSLog(@"AudioFileStreamOpen");
        OSStatus status= AudioFileStreamOpen((__bridge void *)(self), propertyListenerProc, packetsProc, 0, &_audioFileStreamID);
        if (status!=noErr)
        {
            [self.audioProperty error:YUAudioError_AFS_OpenFail];
        }
        shouldExit=NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioDataExited:) name:Noti_AudioDataExited object:nil];
    }
    return self;
}

- (instancetype)initWithFileType:(AudioFileTypeID)fileTypeID
{
    self = [super init];
    if (self) {
        packetCount=0;
        packetDataSize=0;
        bitRate=0;
        dataOffset=0;
        packetDuration=0;
        isSeeking=NO;
//        NSLog(@"AudioFileStreamOpen");
        OSStatus status= AudioFileStreamOpen((__bridge void *)(self), propertyListenerProc, packetsProc, fileTypeID, &_audioFileStreamID);
        if (status!=noErr)
        {
            [self.audioProperty error:YUAudioError_AFS_OpenFail];
        }
        shouldExit=NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioDataExited:) name:Noti_AudioDataExited object:nil];
    }
    return self;
}

-(void)audioStreamParseBytes:(NSData*)data flags:(UInt32)flags{
    if (_audioFileStreamID) {
        OSStatus status= AudioFileStreamParseBytes(_audioFileStreamID, (UInt32)data.length, data.bytes, flags);;
        if (status!=noErr)
        {
            [self.audioProperty error:YUAudioError_AFS_ParseFail];
        }
    }
}

-(void)getSeekToOffset:(double)seekToTime{
    self.seekByteOffset = dataOffset +
    (seekToTime / self.duration) * (_audioProperty.fileSize - dataOffset);
    
    if (self.seekByteOffset > _audioProperty.fileSize - 2 * _audioProperty.packetMaxSize)
    {
        self.seekByteOffset = _audioProperty.fileSize - 2 * _audioProperty.packetMaxSize;
    }
    self.seekTime=seekToTime;
    isSeeking=YES;
}

-(void)close{
    shouldExit=YES;
}

//释放资源
-(void)audioDataExited:(NSNotification*)noti{
    if (shouldExit) {
        if (noti&&noti.userInfo&&[noti.userInfo objectForKey:@"audioVersion"]) {
            NSNumber* dataVersionNum=[noti.userInfo objectForKey:@"audioVersion"];
            if ([dataVersionNum integerValue]==self.audioVersion) {
//                NSLog(@"AudioFileStreamClose");
                AudioFileStreamClose(_audioFileStreamID);
                _audioFileStreamID=nil;
                [[NSNotificationCenter defaultCenter] removeObserver:self];
            }
        }
    }
}

#pragma mark audioStream Proc

void propertyListenerProc(void *inClientData,AudioFileStreamID inAudioFileStream,AudioFileStreamPropertyID inPropertyID,UInt32 *ioFlags){
    YUAudioStream *audioStream=(__bridge YUAudioStream*)inClientData;
    
    [audioStream propertyListener:inPropertyID];
}

void packetsProc(void *inClientData,UInt32 inNumberBytes,UInt32	inNumberPackets,const void *inInputData,AudioStreamPacketDescription *inPacketDescriptions){
    YUAudioStream *audioStream=(__bridge YUAudioStream*)inClientData;
    [audioStream packets:inClientData bytesNum:inNumberBytes packetsNum:inNumberPackets inputData:inInputData packesDescs:inPacketDescriptions];
}

#pragma mark audioStream Proc OC func

-(void)propertyListener:(AudioFileStreamPropertyID)inPropertyID{
    OSStatus status;
     if (inPropertyID==kAudioFileStreamProperty_DataFormat) {
         UInt32 asbdSize = sizeof(_audioDesc);
         status = AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_DataFormat, &asbdSize, &_audioDesc);
         if (_audioDesc.mSampleRate>0) {
             packetDuration=_audioDesc.mFramesPerPacket/_audioDesc.mSampleRate;
         }
         if (status!=noErr)
         {
             return;
         }
     }else if(inPropertyID==kAudioFileStreamProperty_PacketSizeUpperBound){
         if (_audioProperty.packetMaxSize==0) {
             UInt32 sizeOfUInt32 = sizeof(UInt32);
             UInt32 packetMaxSize=0;
             AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_PacketSizeUpperBound, &sizeOfUInt32, &packetMaxSize);
             _audioProperty.packetMaxSize=packetMaxSize;
         }
     }else if(inPropertyID==kAudioFileStreamProperty_MaximumPacketSize){
         if (_audioProperty.packetMaxSize==0) {
             UInt32 sizeOfUInt32 = sizeof(UInt32);
             UInt32 packetMaxSize=0;
             AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_MaximumPacketSize, &sizeOfUInt32, &packetMaxSize);
             _audioProperty.packetMaxSize=packetMaxSize;
         }
     }else if(inPropertyID==kAudioFileStreamProperty_DataOffset){
         UInt32 sizeOfUInt32 = sizeof(NSInteger);
         AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_PacketSizeUpperBound, &sizeOfUInt32, &dataOffset);
     }else if(inPropertyID==kAudioFileStreamProperty_BitRate){
         UInt32 sizeOfUInt32 = sizeof(NSInteger);
         AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_PacketSizeUpperBound, &sizeOfUInt32, &bitRate);
     }else if(inPropertyID==kAudioFileStreamProperty_ReadyToProducePackets){
         UInt32 cookieSize;
         Boolean writable;
         OSStatus ignorableError;
         ignorableError = AudioFileStreamGetPropertyInfo(_audioFileStreamID, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
         if (ignorableError)
         {
             cookieSize=0;
             _audioProperty.cookieSize=0;
         }
         if (cookieSize>0) {
             void* cookieData = calloc(1, cookieSize);
             ignorableError = AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
             if (ignorableError)
             {
                 
             }
             _audioProperty.magicData=cookieData;
             _audioProperty.cookieSize=cookieSize;
             
             if (self.audioStreamDelegate) {
                 [self.audioStreamDelegate audioStream_ReadyToProducePackets];
             }
             
             free(cookieData);
         }
         else{
             if (self.audioStreamDelegate) {
                 [self.audioStreamDelegate audioStream_ReadyToProducePackets];
             }
         }
     }
}

-(void)packets:(void *)inClientData bytesNum:(UInt32)inNumberBytes packetsNum:(UInt32)inNumberPackets inputData:(const void *)inInputData packesDescs:(AudioStreamPacketDescription *)inPacketDescriptions{
    packetCount+=inNumberPackets;
    packetDataSize+=inNumberBytes;
    if (self.audioStreamDelegate) {
        [self.audioStreamDelegate audioStream_Packets:[NSData dataWithBytes:inInputData length:inNumberBytes] packetNum:inNumberPackets packetDescs:inPacketDescriptions];
    }
}

#pragma mark Property

-(double)duration{
    double calculatedBitRate = [self calculatedBitRate];
    
    if (calculatedBitRate == 0 || _audioProperty.fileSize == 0)
    {
        return 0.0;
    }
    
    return (_audioProperty.fileSize-dataOffset) / (calculatedBitRate * 0.125);
}

- (double)calculatedBitRate
{
    if (packetDuration && packetCount > BitRateEstimationMinPackets)
    {
        double averagePacketByteSize = packetDataSize / packetCount;
        return 8.0 * averagePacketByteSize / packetDuration;
    }
    
    if (bitRate)
    {
        return (double)bitRate;
    }
    
    return 0;
}

-(void)logProperty:(AudioFileStreamPropertyID)propertyID{
    NSString *propertyStr=@"";
    switch (propertyID) {
        case kAudioFileStreamProperty_ReadyToProducePackets:
            propertyStr=@"ReadyToProducePackets";
            break;
        case kAudioFileStreamProperty_FileFormat:
            propertyStr=@"FileFormat";
            break;
        case kAudioFileStreamProperty_DataFormat:
            propertyStr=@"DataFormat";
            break;
        case kAudioFileStreamProperty_FormatList:
            propertyStr=@"FormatList";
            break;
        case kAudioFileStreamProperty_MagicCookieData:
            propertyStr=@"MagicCookieData";
            break;
        case kAudioFileStreamProperty_AudioDataByteCount:
            propertyStr=@"AudioDataByteCount";
            break;
        case kAudioFileStreamProperty_AudioDataPacketCount:
            propertyStr=@"AudioDataPacketCount";
            break;
        case kAudioFileStreamProperty_MaximumPacketSize:
            propertyStr=@"MaximumPacketSize";
            break;
        case kAudioFileStreamProperty_DataOffset:
            propertyStr=@"DataOffset";
            break;
        case kAudioFileStreamProperty_ChannelLayout:
            propertyStr=@"ChannelLayout";
            break;
        case kAudioFileStreamProperty_PacketToFrame:
            propertyStr=@"PacketToFrame";
            break;
        case kAudioFileStreamProperty_FrameToPacket:
            propertyStr=@"FrameToPacket";
            break;
        case kAudioFileStreamProperty_PacketToByte:
            propertyStr=@"PacketToByte";
            break;
        case kAudioFileStreamProperty_ByteToPacket:
            propertyStr=@"ByteToPacket";
            break;
        case kAudioFileStreamProperty_PacketTableInfo:
            propertyStr=@"PacketTableInfo";
            break;
        case kAudioFileStreamProperty_PacketSizeUpperBound:
            propertyStr=@"PacketSizeUpperBound";
            break;
        case kAudioFileStreamProperty_AverageBytesPerPacket:
            propertyStr=@"AverageBytesPerPacket";
            break;
        case kAudioFileStreamProperty_BitRate:
            propertyStr=@"BitRate";
            break;
        case kAudioFileStreamProperty_InfoDictionary:
            propertyStr=@"InfoDictionary";
            break;
        default:
            break;
    }
    NSLog(@"kAudioFileStreamProperty_%@",propertyStr);
}

- (void)dealloc
{
    
}

@end
