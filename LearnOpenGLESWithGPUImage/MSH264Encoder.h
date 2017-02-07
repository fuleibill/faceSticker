//
//  MSH264Encoder.h
//  SimpleVideoFilter
//
//  Created by liyue-g on 16/8/18.
//  Copyright © 2016年 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

typedef void (^MSEncoderH264DataReadyBlock)(void* buffer, int32_t bufferLen, uint64_t timestamp, BOOL isKeyFrame);
typedef void (^MSEncoderSPSPPSReadyBlock)(char* spspps, int spsppsSize);

@interface MSH264Encoder : NSObject

- (instancetype)initWithWidth:(NSUInteger)width
                       height:(NSUInteger)height
             keyFrameInterval:(NSUInteger)interval
                      bitrate:(NSUInteger)bitrate
                          fps:(NSUInteger)fps
                onSPSPPSReady:(MSEncoderSPSPPSReadyBlock)spsppsReady
                  onDataReady:(MSEncoderH264DataReadyBlock)dataReady;

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)encodePixelBuffer:(CVPixelBufferRef)buffer;

@property (nonatomic, assign) BOOL needSPSPPS;

@end
