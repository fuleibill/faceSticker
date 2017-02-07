//
//  MSAudioEncoder.h
//  SimpleVideoFilter
//
//  Created by liyue-g on 16/8/18.
//  Copyright © 2016年 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^MSEncoderAudioDataReadyBlock)(void* buffer, int32_t bufferLen);

@interface MSAudioEncoder : NSObject

- (instancetype)initWithBitrate:(NSUInteger)bitrate
                      sampleRate:(NSUInteger)sampleRate
                        channels:(NSUInteger)channels
                     onDataReady:(MSEncoderAudioDataReadyBlock)dataReady;

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
