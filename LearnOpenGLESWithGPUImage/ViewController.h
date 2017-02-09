//
//  ViewController.h
//  LearnOpenGLESWithGPUImage
//
//  Created by Bill on 17/2/5.
//  Copyright © 2016年 Bill. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "MSGPUImageMovieWriter.h"

@interface ViewController : UIViewController <GPUImageMovieWriterDelegate>
{
//    MSGPUImageMovieWriter *movieWriter;
    GPUImageMovieWriter *movieWriter;
}


@end

