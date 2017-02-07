//
//  MSRtmpService.h
//  SimpleVideoFilter
//
//  Created by liyue-g on 16/8/18.
//  Copyright © 2016年 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MSLiveResult)
{
    MSLiveResultSuccess,
    MSLiveResultFailed,
};

@interface MSRtmpService : NSObject

+ (instancetype)sharedInstance;

- (MSLiveResult)createRtmp:(NSString *)url key:(NSString *)key;
- (void)closeRtmp;
- (BOOL)isConnecting;

- (void)setVideoWidth:(int)videoWidth
               height:(int)videoHeight
                  fps:(int)fps
                  bps:(int)bps
               spspps:(char *)spspps
           spsppsSize:(int)spsppsSize;

- (void)setAudioBps:(int)bps
           channels:(int)channels
         sampleSize:(int)sampleSize
         sampleRate:(int)sampleRate
          aacHeader:(char*)aacHeader
      aacHeaderSize:(int)aacHeaderSize;

- (void)pushVideoPts:(uint64_t)pts
                data:(uint8_t *)data
                size:(int)size
          isKeyFrame:(BOOL)isKeyFrame;

- (void)pushAudioData:(uint8_t *)data
                 size:(int)size;

@end
