//
//  MSH264Encoder.m
//  SimpleVideoFilter
//
//  Created by liyue-g on 16/8/18.
//  Copyright © 2016年 Cell Phone. All rights reserved.
//

#import "MSH264Encoder.h"
#import <VideoToolbox/VideoToolbox.h>

MSH264Encoder* m_self;

@interface MSH264Encoder ()

@property (nonatomic) NSUInteger videoWidth;
@property (nonatomic) NSUInteger videoHeigth;
@property (nonatomic) NSUInteger videoInterval;
@property (nonatomic) NSUInteger videoBitrate;
@property (nonatomic) NSUInteger videoFps;
@property (nonatomic) VTCompressionSessionRef videoCompressionSession;
@property (nonatomic) dispatch_queue_t encoderQueue;
@property (nonatomic) MSEncoderSPSPPSReadyBlock spsppsReadyBlock;
@property (nonatomic) MSEncoderH264DataReadyBlock dataReadyBlock;
@property (nonatomic) CFTimeInterval encodeStartTime;
@property (nonatomic) NSInteger frameCount;

@end

@implementation MSH264Encoder
{
   
}

- (instancetype)initWithWidth:(NSUInteger)width
                       height:(NSUInteger)height
             keyFrameInterval:(NSUInteger)interval
                      bitrate:(NSUInteger)bitrate
                          fps:(NSUInteger)fps
                onSPSPPSReady:(MSEncoderSPSPPSReadyBlock)spsppsReady
                  onDataReady:(MSEncoderH264DataReadyBlock)dataReady
{
    if (self = [super init])
    {
        m_self = self;
        self.videoWidth = width;
        self.videoHeigth = height;
        self.videoInterval = interval;
        self.videoBitrate = bitrate;
        self.videoFps = fps;
        self.spsppsReadyBlock = spsppsReady;
        self.dataReadyBlock = dataReady;
        self.needSPSPPS = YES;
        self.encodeStartTime = CFAbsoluteTimeGetCurrent()*1000;
        self.frameCount = 0;
        
        _encoderQueue = dispatch_queue_create("com.huajiao.queue.vtencoder", DISPATCH_QUEUE_SERIAL);
        
        [self initH26Encoder];
    }
    
    return self;
}

- (void)dealloc
{
    self.encoderQueue = NULL;
    self.spsppsReadyBlock = NULL;
    self.dataReadyBlock = NULL;
    
    VTCompressionSessionInvalidate(self.videoCompressionSession);
    self.videoCompressionSession = NULL;
}

- (void)encodePixelBuffer:(CVPixelBufferRef)buffer
{
    //控制编码帧数
    CFTimeInterval curTime = CFAbsoluteTimeGetCurrent()*1000;
    float frameCount = (curTime - self.encodeStartTime)/(1000.0/self.videoFps);
    if (frameCount < self.frameCount)
        return;
    
    dispatch_sync(_encoderQueue, ^{
        OSStatus ret;
        self.frameCount++;
        ret = VTCompressionSessionEncodeFrame(self.videoCompressionSession, buffer, CMTimeMake(self.frameCount/self.videoFps, (int32_t)self.videoFps), kCMTimeInvalid, NULL, NULL,  NULL);
        if (ret != noErr)
        {
            NSLog(@"Encode frame error, result = %d, %s", ret, vtbGetErrorString(ret));
        }
    });
}

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
//    dispatch_sync(_encoderQueue, ^{
//        CVImageBufferRef image = CMSampleBufferGetImageBuffer(sampleBuffer);
//        if (image)
//        {
//            OSStatus ret;
//            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//            ret = VTCompressionSessionEncodeFrame(self.videoCompressionSession, image, pts, kCMTimeInvalid, NULL, NULL,  NULL);
//            if (ret != noErr)
//            {
//                NSLog(@"Encode frame error, result = %d, %s", ret, vtbGetErrorString(ret));
//            }
//        }
//    });
}

- (void)initH26Encoder
{
    dispatch_sync(_encoderQueue, ^{
        const size_t attributes_size = 3;
        CFTypeRef keys[attributes_size] = {kCVPixelBufferOpenGLESCompatibilityKey, kCVPixelBufferIOSurfacePropertiesKey, kCVPixelBufferPixelFormatTypeKey};
        CFDictionaryRef io_surface_value = CFDictionaryCreate(kCFAllocatorDefault, nil, nil, 0, nil, nil);
        int64_t nv12type = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        CFNumberRef pixel_format = CFNumberCreate(nil, kCFNumberLongType, &nv12type);
        CFTypeRef values[attributes_size] = {kCFBooleanTrue, io_surface_value, pixel_format};
        CFDictionaryRef source_attributes = CFDictionaryCreate(kCFAllocatorDefault, keys, values, attributes_size, nil, nil);
        
        OSStatus status = 0;
        status = VTCompressionSessionCreate(
                                            kCFAllocatorDefault,
                                            (int)_videoWidth,
                                            (int)_videoHeigth,
                                            kCMVideoCodecType_H264,
                                            NULL,
                                            source_attributes,
                                            NULL,
                                            didCompress,
                                            (__bridge void * _Nullable)(self),
                                            &_videoCompressionSession
                                            );
        if (source_attributes)
        {
            CFRelease(source_attributes);
            source_attributes = nil;
        }
        
        if (io_surface_value)
        {
            CFRelease(io_surface_value);
            io_surface_value = nil;
        }
        
        if (pixel_format)
        {
            CFRelease(pixel_format);
            pixel_format = nil;
        }
        
        if (status != noErr)
        {
            NSLog(@"Create VTCompressionSession, status = %d, %s", (int)status, vtbGetErrorString(status));
        }
        
        
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
        
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef _Nonnull)(@(_videoInterval)));
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_ColorPrimaries, kCVImageBufferColorPrimaries_ITU_R_709_2);
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_TransferFunction, kCVImageBufferTransferFunction_ITU_R_709_2);
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_YCbCrMatrix, kCVImageBufferYCbCrMatrix_ITU_R_709_2);
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef _Nonnull)(@(_videoBitrate)));
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef _Nonnull)(@(_videoFps)));
        VTSessionSetProperty(_videoCompressionSession, kVTCompressionPropertyKey_MaxFrameDelayCount, (__bridge CFTypeRef _Nonnull)(@((_videoInterval))));
    });
}

static void didCompress(void* encoderOpaque, void* requestOpaque, OSStatus status, VTEncodeInfoFlags info, CMSampleBufferRef sampleBuffer)
{
    if (status != noErr || !sampleBuffer)
    {
        NSLog(@"Compress frame error, error = %d, %s", (int)status, vtbGetErrorString(status));
        return;
    }
    
    CMBlockBufferRef block = CMSampleBufferGetDataBuffer(sampleBuffer);
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, false);
    
    bool isKeyframe = false;
    if(attachments != NULL)
    {
        CFDictionaryRef attachment;
        CFBooleanRef dependsOnOthers;
        attachment = (CFDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        dependsOnOthers = (CFBooleanRef)CFDictionaryGetValue(attachment, kCMSampleAttachmentKey_DependsOnOthers);
        isKeyframe = (dependsOnOthers == kCFBooleanFalse);
    }
    
    if (isKeyframe && m_self.needSPSPPS)
    {
        m_self.encodeStartTime = CFAbsoluteTimeGetCurrent()*1000;
        [m_self setVideoSPSPPS:sampleBuffer];
    }
    
    char* bufferData;
    size_t bufferSize;
    CMBlockBufferGetDataPointer(block, 0, NULL, &bufferSize, &bufferData);
    
    int rLen = 0;
    int nalSize = 0;
    unsigned char *data;
    unsigned char *newData;
    int newDataOffset = 0;
    int newDataStartPos = 0;
    
    data = (unsigned char *)bufferData + rLen;
    newData = (unsigned char *)bufferData + rLen;
    
    while (rLen < bufferSize)
    {
        rLen += 4;
        nalSize = (((uint32_t)data[0] << 24) | ((uint32_t)data[1] << 16) | ((uint32_t)data[2] << 8) | (uint32_t)data[3]);
        rLen += nalSize;
        
        int nalType = data[4] & 0x1f;
        if(nalType == 1 || nalType == 5)
        {
            newData[newDataStartPos+newDataOffset] = 0;
            newData[newDataStartPos+newDataOffset+1] = 0;
            newData[newDataStartPos+newDataOffset+2] = 0;
            newData[newDataStartPos+newDataOffset+3] = 1;
            newDataOffset += nalSize + 4;
        }
        else
        {
            newDataStartPos = rLen;
        }
        
        data = (unsigned char *)bufferData + rLen;
    }
    
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (m_self.dataReadyBlock)
        m_self.dataReadyBlock((uint8_t *)&newData[newDataStartPos], newDataOffset, pts.value/pts.timescale, isKeyframe);
}

- (void)setVideoSPSPPS:(CMSampleBufferRef)sampleBuffer
{
    // Send the SPS and PPS.
    CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
    size_t spsSize, ppsSize;
    size_t parmCount;
    const uint8_t* sps, *pps;
    
    CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sps, &spsSize, &parmCount, 0 );
    CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pps, &ppsSize, &parmCount, 0 );
    
    unsigned char* spspps = (unsigned char *)malloc(spsSize + ppsSize + 8);
    spspps[0] = 0;
    spspps[1] = 0;
    spspps[2] = 0;
    spspps[3] = 1;
    spspps[spsSize + 4] = 0;
    spspps[spsSize + 5] = 0;
    spspps[spsSize + 6] = 0;
    spspps[spsSize + 7] = 1;
    memcpy(&spspps[4], sps, spsSize);
    memcpy(&spspps[spsSize + 8], pps, ppsSize);
    
    if (self.spsppsReadyBlock)
        self.spsppsReadyBlock((char *)spspps, (int)(spsSize + ppsSize + 8));
    
    free(spspps);
}

static const char *vtbGetErrorString(OSStatus status)
{
    switch (status) {
        case kVTInvalidSessionErr:                      return "kVTInvalidSessionErr";
        case kVTVideoDecoderBadDataErr:                 return "kVTVideoDecoderBadDataErr";
        case kVTVideoDecoderUnsupportedDataFormatErr:   return "kVTVideoDecoderUnsupportedDataFormatErr";
        case kVTVideoDecoderMalfunctionErr:             return "kVTVideoDecoderMalfunctionErr";
        case kVTVideoEncoderMalfunctionErr:             return "kVTVideoEncoderMalfunctionErr";
        case kVTPixelTransferNotSupportedErr:           return "kVTPixelTransferNotSupportedErr";
        default:                                        return "UNKNOWN";
    }
}

@end






