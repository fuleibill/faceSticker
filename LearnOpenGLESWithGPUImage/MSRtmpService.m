//
//  MSRtmpService.m
//  SimpleVideoFilter
//
//  Created by liyue-g on 16/8/18.
//  Copyright © 2016年 Cell Phone. All rights reserved.
//

#import "MSRtmpService.h"
#import "avencoder.h"

@interface MSRtmpService ()

@property (nonatomic) BOOL alreadySetVideoRtmpParams;
@property (nonatomic) BOOL alreadySetAudioRtmpParams;
@property (nonatomic) NSTimeInterval audioTimestamp;
@property (nonatomic) NSTimeInterval videoTimestamp;
@property (nonatomic) dispatch_queue_t rtmpQueue;
@property (nonatomic) BOOL alreadyStartSend;
@property (nonatomic) NSInteger connectState;
@property (nonatomic) NSInteger videoFps;
@property (nonatomic) NSInteger audioSampleRate;

@end

@implementation MSRtmpService

+ (instancetype)sharedInstance
{
    static MSRtmpService *service = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        service = [[self alloc] init];
    });
    
    return service;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _rtmpQueue = dispatch_queue_create("rtmp_queue", NULL);
    }
    
    return self;
}

- (MSLiveResult)createRtmp:(NSString *)url key:(NSString *)key
{
    self.alreadySetVideoRtmpParams = NO;
    self.alreadySetAudioRtmpParams = NO;
    self.alreadyStartSend = NO;
    
    const char* serverUrl = [url UTF8String];
    const char* serverKey = [key UTF8String];
    int serverUrlLength = (int)strlen(serverUrl);
    int serverKeyLength = (int)strlen(serverKey);
    __block int result = 1;
    
    dispatch_sync(_rtmpQueue, ^{
        result = create();
        setRtmpParams((char *)serverUrl, serverUrlLength, (char *)serverKey, serverKeyLength, "", 0, "", 0);
    });
    
    if (result == 0)
    {
        NSLog(@"Rtmp create failed");
        return MSLiveResultFailed;
    }
    else
    {
        return MSLiveResultSuccess;
    }
}

- (void)closeRtmp
{
    dispatch_async(_rtmpQueue, ^{
        stop();
        destroy();
    });
}

- (BOOL)isConnecting
{
    __block int connecting = 1;
    dispatch_sync(_rtmpQueue, ^{
        connecting = isconnected();
    });
    return connecting == 1 ? YES:NO;
}

- (void)setVideoWidth:(int)videoWidth
               height:(int)videoHeight
                  fps:(int)fps
                  bps:(int)bps
               spspps:(char *)spspps
           spsppsSize:(int)spsppsSize
{
    dispatch_sync(_rtmpQueue, ^{
        if (!_alreadySetVideoRtmpParams)
        {
            _alreadySetVideoRtmpParams = YES;
            self.videoFps = fps;
            setVideoParams(videoWidth, videoHeight, fps, bps, spspps, spsppsSize);
        }
        
        [self startSendRtmpData];
    });
}

- (void)setAudioBps:(int)bps
           channels:(int)channels
         sampleSize:(int)sampleSize
         sampleRate:(int)sampleRate
          aacHeader:(char*)aacHeader
      aacHeaderSize:(int)aacHeaderSize
{
    dispatch_sync(_rtmpQueue, ^{
        if (!_alreadySetAudioRtmpParams)
        {
            _alreadySetAudioRtmpParams = YES;
            self.audioSampleRate = sampleRate;
            setAudioParams(bps, channels, sampleSize, sampleRate, aacHeader, aacHeaderSize);
        }
        
        [self startSendRtmpData];
    });
}

- (void)startSendRtmpData
{
    if (_alreadySetAudioRtmpParams && _alreadySetVideoRtmpParams)
    {
        if (!_alreadyStartSend)
        {
            _alreadyStartSend = YES;
            start_send();
        }
    }
}

int vcount;
- (void)pushVideoPts:(uint64_t)pts
                data:(uint8_t *)data
                size:(int)size
          isKeyFrame:(BOOL)isKeyFrame
{
    if (!_alreadyStartSend)
    {
        return;
    }
    
    vcount++;
    
    _videoTimestamp += 1000000.0/self.videoFps;
    dispatch_sync(_rtmpQueue, ^{
        NSLog(@"video: %f, %d", _videoTimestamp , vcount);
        push_video(_videoTimestamp, data, size, isKeyFrame);
    });
}

int acount;
- (void)pushAudioData:(uint8_t *)data
                 size:(int)size
{
    if (!_alreadyStartSend)
    {
        return;
    }
    
    acount++;
    
    if (_alreadySetAudioRtmpParams && _alreadyStartSend)
    {
        _audioTimestamp += 1024*1000/self.audioSampleRate;
        dispatch_sync(_rtmpQueue, ^{
//        NSLog(@"-------- audio: %f, %d", _audioTimestamp, acount);
            push_audio(_audioTimestamp, data, size);
        });
    }
}

@end









