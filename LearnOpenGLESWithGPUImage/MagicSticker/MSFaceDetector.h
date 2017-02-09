//
//  MSFaceDetector.h
//  LearnOpenGLESWithGPUImage
//
//  Created by Bill on 17/2/9.
//  Copyright © 2017年 Bill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import <iflyMSC/IFlyFaceSDK.h>
#import "IFlyFaceImage.h"
#import "IFlyFaceResultKeys.h"

@interface MSFaceDetector : UIView

- (MSFaceDetector *)initWithViewRect:(CGRect)viewRect;

- (void)faceImageSampleBufferFromPlatform:(CMSampleBufferRef)sampleBuffer isFront:(BOOL)isFront;
- (void)faceImagePixelBufferFromPlatform:(CVPixelBufferRef)pixelBuffer isFront:(BOOL)isFront;

@end
