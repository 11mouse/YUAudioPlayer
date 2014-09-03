//
//  YUAudioFile.m
//  YUAudioPlayer
//
//  Created by duan on 14-8-25.
//  Copyright (c) 2014年 duan. All rights reserved.
//

#import "YUAudioFile.h"

@interface YUAudioFile()
{
    AudioFileID	audioFileID;
}
@end

@implementation YUAudioFile

-(void)stop{
    AudioFileClose(audioFileID);
    audioFileID=nil;
}

-(void)createAudioFile{
    if (_recordUrlStr==nil) {
        
    }
    if (audioFileID==nil) {
        
        CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)_recordUrlStr, NULL);
        
        AudioStreamBasicDescription audioDesc=_audioProperty.audioDesc;
        OSStatus status = AudioFileCreateWithURL(url, kAudioFileCAFType, &audioDesc, kAudioFileFlags_EraseFile, &audioFileID);
        CFRelease(url);
        if (status!=noErr) {
            [self.audioProperty error:YUAudioError_AF_CreateFail];
        }
    }
}

-(NSError*)writePackets:(UInt32)inNumBytes inPacketDescs:(const AudioStreamPacketDescription*)inPacketDescs inStartingPacket:(SInt64)inStartingPacket ioNumPackets:(UInt32*)ioNumPackets inBuffer:(const void*)inBuffer{
    if (!audioFileID) {
        [self createAudioFile];
    }
    OSStatus status = AudioFileWritePackets(audioFileID, FALSE, inNumBytes,
                          inPacketDescs, inStartingPacket, ioNumPackets, inBuffer);
    NSError *error=nil;
    if (status!=noErr) {
        error=[NSError errorWithDomain:[self.audioProperty errorDomaim:YUAudioError_AF_PacketWriteFail] code:YUAudioError_AF_PacketWriteFail userInfo:nil];
    }
    return error;
}

-(void)setEncoderCookie{
    UInt32 willEatTheCookie = false;
    OSStatus err = AudioFileGetPropertyInfo(audioFileID, kAudioFilePropertyMagicCookieData, NULL, &willEatTheCookie);
    if (err == noErr && willEatTheCookie) {
        err = AudioFileSetProperty(audioFileID, kAudioFilePropertyMagicCookieData, _audioProperty.cookieSize, _audioProperty.magicData);
    }
}

@end
