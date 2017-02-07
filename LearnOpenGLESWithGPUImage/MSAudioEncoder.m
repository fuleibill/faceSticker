//
//  MSAudioEncoder.m
//  SimpleVideoFilter
//
//  Created by liyue-g on 16/8/18.
//  Copyright © 2016年 Cell Phone. All rights reserved.
//

#import "MSAudioEncoder.h"

@interface MSAudioEncoder ()

@property (nonatomic) NSUInteger sampleRate;
@property (nonatomic) int channels;
@property (nonatomic) AudioConverterRef audioConverter;
@property (nonatomic) uint8_t *aacBuffer;
@property (nonatomic) int aacBufferSize;
@property (nonatomic) char *pcmBuffer;
@property (nonatomic) size_t pcmBufferSize;
@property (nonatomic) NSUInteger bitrate;
@property (nonatomic) dispatch_queue_t encoderQueue;

@end

@implementation MSAudioEncoder
{
    MSEncoderAudioDataReadyBlock dataReadyBlock;
}

- (instancetype)initWithBitrate:(NSUInteger)bitrate
                     sampleRate:(NSUInteger)sampleRate
                       channels:(NSUInteger)channels
                    onDataReady:(MSEncoderAudioDataReadyBlock)dataReady
{
    if (self = [super init])
    {
        self.bitrate = bitrate;
        self.sampleRate = sampleRate;
        self.channels = (int)channels;
        dataReadyBlock = dataReady;
        [self initAACEncoder];
    }
    
    return self;
}

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CFRetain(sampleBuffer);
    dispatch_async(self.encoderQueue, ^{
        if (!self.audioConverter)
        {
            [self setupAACEncoderFromSampleBuffer:sampleBuffer];
        }
        
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        CFRetain(blockBuffer);
        OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &_pcmBufferSize, &_pcmBuffer);
        NSError *error = nil;
        if (status != kCMBlockBufferNoErr)
        {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        
        memset(self.aacBuffer, 0, self.aacBufferSize);
        AudioBufferList outAudioBufferList = {0};
        outAudioBufferList.mNumberBuffers = 1;
        outAudioBufferList.mBuffers[0].mNumberChannels = 1;
        outAudioBufferList.mBuffers[0].mDataByteSize = self.aacBufferSize;
        outAudioBufferList.mBuffers[0].mData = self.aacBuffer;
        AudioStreamPacketDescription *outPacketDescription = NULL;
        UInt32 ioOutputDataPacketSize = 1;
        status = AudioConverterFillComplexBuffer(self.audioConverter, inInputDataProc, (__bridge void *)(self), &ioOutputDataPacketSize, &outAudioBufferList, outPacketDescription);
        
        if (status == 0)
        {
            if(dataReadyBlock)
                dataReadyBlock(outAudioBufferList.mBuffers[0].mData, outAudioBufferList.mBuffers[0].mDataByteSize);
        }
        else
        {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }

        CFRelease(sampleBuffer);
        CFRelease(blockBuffer);
        
    });
}

- (void)dealloc
{
    dataReadyBlock = NULL;
    self.encoderQueue = nil;
    
    AudioConverterDispose(self.audioConverter);
    self.audioConverter = NULL;
    
    free(self.pcmBuffer);
    self.pcmBufferSize = 0;
    self.pcmBuffer = NULL;
    
    free(self.aacBuffer);
    self.aacBuffer = NULL;
}

- (void)initAACEncoder
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if(audioSession != nil)
    {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [audioSession setActive:YES error:nil];
    }
    
    self.encoderQueue = dispatch_queue_create("aac_encoder_queue", DISPATCH_QUEUE_SERIAL);
    self.audioConverter = NULL;
    self.pcmBufferSize = 0;
    self.pcmBuffer = NULL;
    self.aacBufferSize = 1024;
    self.aacBuffer = (uint8_t*)malloc(self.aacBufferSize);
    memset(self.aacBuffer, 0, self.aacBufferSize);
}

- (void)setupAACEncoderFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    AudioStreamBasicDescription inAudioStreamBasicDescription = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer));
    
    AudioStreamBasicDescription outAudioStreamBasicDescription = {0}; // Always initialize the fields of a new audio stream basic description structure to zero, as shown here: ...
    
    // The number of frames per second of the data in the stream, when the stream is played at normal speed. For compressed formats, this field indicates the number of frames per second of equivalent decompressed data. The mSampleRate field must be nonzero, except when this structure is used in a listing of supported formats (see “kAudioStreamAnyRate”).
    if (self.sampleRate != 0)
    {
        outAudioStreamBasicDescription.mSampleRate = self.sampleRate;
    }
    else
    {
        outAudioStreamBasicDescription.mSampleRate = inAudioStreamBasicDescription.mSampleRate;
    }
    outAudioStreamBasicDescription.mFormatID = kAudioFormatMPEG4AAC; // kAudioFormatMPEG4AAC_HE does not work. Can't find `AudioClassDescription`. `mFormatFlags` is set to 0.
    outAudioStreamBasicDescription.mFormatFlags =kMPEG4Object_AAC_LC; // Format-specific flags to specify details of the format. Set to 0 to indicate no format flags. See “Audio Data Format Identifiers” for the flags that apply to each format.
    outAudioStreamBasicDescription.mBytesPerPacket = 0; // The number of bytes in a packet of audio data. To indicate variable packet size, set this field to 0. For a format that uses variable packet size, specify the size of each packet using an AudioStreamPacketDescription structure.
    outAudioStreamBasicDescription.mFramesPerPacket = 1024; // The number of frames in a packet of audio data. For uncompressed audio, the value is 1. For variable bit-rate formats, the value is a larger fixed number, such as 1024 for AAC. For formats with a variable number of frames per packet, such as Ogg Vorbis, set this field to 0.
    outAudioStreamBasicDescription.mBytesPerFrame = 0; // The number of bytes from the start of one frame to the start of the next frame in an audio buffer. Set this field to 0 for compressed formats. ...
    
    // The number of channels in each frame of audio data. This value must be nonzero.
    if (self.channels != 0) {
        outAudioStreamBasicDescription.mChannelsPerFrame = inAudioStreamBasicDescription.mChannelsPerFrame;
    } else {
        outAudioStreamBasicDescription.mChannelsPerFrame = self.channels;
    }
    
    outAudioStreamBasicDescription.mBitsPerChannel = 0; // ... Set this field to 0 for compressed formats.
    outAudioStreamBasicDescription.mReserved = 0; // Pads the structure out to force an even 8-byte alignment. Must be set to 0.
    AudioClassDescription *description = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
    
    OSStatus status = AudioConverterNewSpecific(&inAudioStreamBasicDescription, &outAudioStreamBasicDescription, 1, description, &_audioConverter);
    if (status != 0) {
        NSLog(@"setup converter: %d", (int)status);
    }
    
    if (self.bitrate != 0) {
        UInt32 ulBitRate = (UInt32)self.bitrate;
        UInt32 ulSize = sizeof(ulBitRate);
        AudioConverterSetProperty(_audioConverter, kAudioConverterEncodeBitRate, ulSize, & ulBitRate);
    }
}

- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type
                                           fromManufacturer:(UInt32)manufacturer
{
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    OSStatus st;
    
    UInt32 size;
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (st) {
        NSLog(@"error getting audio format propery info: %d", (int)(st));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    st = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier,
                                &size,
                                descriptions);
    if (st) {
        NSLog(@"error getting audio format propery: %d", (int)(st));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    
    return nil;
}

static OSStatus inInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{
    MSAudioEncoder *encoder = (__bridge MSAudioEncoder *)(inUserData);
    UInt32 requestedPackets = *ioNumberDataPackets;

    size_t copiedSamples = [encoder copyPCMSamplesIntoBuffer:ioData];
    if (copiedSamples < requestedPackets)
    {
        *ioNumberDataPackets = 0;
        return -1;
    }
    
    *ioNumberDataPackets = 1;
    return noErr;
}

- (size_t) copyPCMSamplesIntoBuffer:(AudioBufferList*)ioData {
    size_t originalBufferSize = _pcmBufferSize;
    if (!originalBufferSize) {
        return 0;
    }
    ioData->mBuffers[0].mData = _pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = (int)_pcmBufferSize;
    _pcmBuffer = NULL;
    _pcmBufferSize = 0;
    return originalBufferSize;
}

@end




