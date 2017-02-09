//
//  MSFaceDetector.h
//  LearnOpenGLESWithGPUImage
//
//  Created by Bill on 17/2/9.
//  Copyright © 2017年 Bill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
#import <iflyMSC/IFlyFaceSDK.h>
#import "IFlyFaceImage.h"

@interface MSFaceDetector : NSObject

- (CMSampleBufferRef)faceImageSampleBufferFromPlatform:(CMSampleBufferRef)sampleBuffer;
- (CVPixelBufferRef)faceImagePixelBufferFromPlatform:(CVPixelBufferRef)pixelBuffer;

@end
