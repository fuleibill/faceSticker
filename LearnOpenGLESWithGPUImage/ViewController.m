//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by Bill on 17/2/5.
//  Copyright © 2016年 Bill. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import "GPUImageBeautifyFilter.h"
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <iflyMSC/IFlyFaceSDK.h>
#import <CoreMotion/CMMotionManager.h>

#import "LFGPUImageEmptyFilter.h"
#import "LFGPUImageBeautyFilter.h"

#import "CalculatorTools.h"
#import "LFLiveKit.h"
#import "UIControl+YYAdd.h"
#import "UIView+YYAdd.h"
#import "MagicStickerHeaders.h"
#import "MSFaceDetector.h"

@interface ViewController () <GPUImageVideoCameraDelegate,LFLiveSessionDelegate>

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
//@property (nonatomic , strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic , strong) GPUImageUIElement *faceView;
@property (nonatomic , strong) GPUImageView *gpuImageView;

@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *output;
@property (nonatomic , strong) GPUImageAlphaBlendFilter *blendFilter;

/**
 Device orientation
 */
@property (nonatomic) CMMotionManager *motionManager;
@property (nonatomic) UIInterfaceOrientation interfaceOrientation;

@property (nonatomic) LFGPUImageBeautyFilter *beautifyFilter;

/**
 Movie Encoder
*/
//@property(nonatomic, retain) MSH264Encoder* videoEncoder;
//@property(nonatomic, retain) MSAudioEncoder* audioEncoder;

// rtmp push stream
@property (nonatomic, strong) LFLiveDebug *debugInfo;
@property (nonatomic, strong) LFLiveSession *session;
@property (nonatomic, strong) UIButton *beautyButton;
@property (nonatomic) UILabel *rtmpLabel;

@property (nonatomic) BOOL isFrontCamera;
@property (nonatomic) BOOL isLive;
@property (nonatomic) UIButton *rtmpButton;

@end


@implementation ViewController{
}

//@synthesize beautifyFilter;
@synthesize isLive;
@synthesize rtmpLabel;
@synthesize isFrontCamera;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    isLive = NO;

   //    [self.viewCanvas setBackgroundColor:[UIColor whiteColor]];
    
    // 直播滤镜初始化
    self.output = [[LFGPUImageEmptyFilter alloc] init];
    // 滤镜初始化
//    self.faceView = [[GPUImageUIElement alloc] initWithView:self.viewCanvas];
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.delegate = self;
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.gpuImageView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width / 480 * 640)];
    [self.view addSubview:self.gpuImageView];
    [self.gpuImageView setBackgroundColor:[UIColor clearColor]];
    
//    NSLog(@"self.frame is %@",NSStringFromCGRect(self.view.frame));
    
    // 响应链配置
    self.filter = [[GPUImageBeautifyFilter alloc] init];
    self.beautifyFilter = (LFGPUImageBeautyFilter*)self.filter;
    [self.videoCamera addTarget:self.beautifyFilter];
    self.blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    self.blendFilter.mix = 1.0f;
    [self.filter addTarget:self.blendFilter];
    [self.faceView addTarget:self.blendFilter];
    [self.filter addTarget:self.gpuImageView];
    [self.filter addTarget:self.output];
    [self.output addTarget:self.gpuImageView];
    
    [self.output addTarget:self.filter];
//    [self.filter forceProcessingAtSize:CGSizeMake(640, 480)];
//    [self.output forceProcessingAtSize:CGSizeMake(640, 480)];
//    [self.blendFilter forceProcessingAtSize:CGSizeMake(640, 480)];
    
    [self.videoCamera startCameraCapture];
    
    // 结束回调
    @try {
        __weak typeof (self) weakSelf = self;
        [self.filter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
            //        NSLog(@"update ui");
            __strong typeof (self) strongSelf = weakSelf;
            dispatch_async([GPUImageContext sharedContextQueue], ^{
                [strongSelf.faceView updateWithTimestamp:time];
            });
        }];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }

    // 最后添加，保证在最上层
//    [self.view addSubview:self.viewCanvas];

    [self configButton];
    [self.view addSubview:self.beautyButton];
    // rtmp
    /***   默认分辨率368 ＊ 640  音频：44.1 iphone6以上48  双声道  方向竖屏 ***/
    LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration new];
//    videoConfiguration.videoSize = CGSizeMake(360, 640);
    videoConfiguration.videoSize = CGSizeMake(640, 480);
    videoConfiguration.videoBitRate = 800*1024;
    videoConfiguration.videoMaxBitRate = 1000*1024;
    videoConfiguration.videoMinBitRate = 500*1024;
    videoConfiguration.videoFrameRate = 24;
    videoConfiguration.videoMaxKeyframeInterval = 48;
    videoConfiguration.outputImageOrientation = UIInterfaceOrientationPortrait;
    videoConfiguration.autorotate = YES;
//    videoConfiguration.sessionPreset = LFCaptureSessionPreset540x960;
    _session = [[LFLiveSession alloc] initWithAudioConfiguration:[LFLiveAudioConfiguration defaultConfiguration] videoConfiguration:videoConfiguration captureType:LFLiveInputMaskVideo];
    
}



#pragma mark -- CMSampleBufferRef获取method
-(void) willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
//    __weak typeof(self) _self = self;
//    @autoreleasepool {
//        GPUImageFramebuffer *imageFramebuffer = self.output.framebufferForOutput;
//        CVPixelBufferRef pixelBuffer = [imageFramebuffer pixelBuffer];
////        if (pixelBuffer && _self.delegate && [_self.delegate respondsToSelector:@selector(captureOutput:pixelBuffer:)]) {
////            [_self.delegate captureOutput:_self pixelBuffer:pixelBuffer];
////        }
//        CVImageBufferRef cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer);
//        CVPixelBufferRef pixelBufRef = cvimgRef;
//        [_self.session pushVideo:pixelBuffer];
//    }
//    MSFaceDetector *faceImage = [[MSFaceDetector alloc] initWithViewRect:self.view.frame];
    
    MSFaceDetector *faceImage = [[MSFaceDetector alloc] initWithFrame:self.view.frame];
    [faceImage faceImageSampleBufferFromPlatform:sampleBuffer isFront:YES];
    
    
}


- (void)updateCM {
    // 这里使用CoreMotion来获取设备方向以兼容iOS7.0设备 检测当前设备的方向 Home键向上还是向下。。。。
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = .2;
    self.motionManager.gyroUpdateInterval = .2;
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 if (!error) {
                                                     [self updateAccelertionData:accelerometerData.acceleration];
                                                 }
                                                 else{
                                                     NSLog(@"%@", error);
                                                 }
                                             }];
}


#pragma mark  - 判断当前设备的方向
- (void)updateAccelertionData:(CMAcceleration)acceleration{
    UIInterfaceOrientation orientationNew;
    
    if (acceleration.x >= 0.75) {
        orientationNew = UIInterfaceOrientationLandscapeLeft;
    }
    else if (acceleration.x <= -0.75) {
        orientationNew = UIInterfaceOrientationLandscapeRight;
    }
    else if (acceleration.y <= -0.75) {
        orientationNew = UIInterfaceOrientationPortrait;
    }
    else if (acceleration.y >= 0.75) {
        orientationNew = UIInterfaceOrientationPortraitUpsideDown;
    }
    else {
        // Consider same as last time
        return;
    }
    
    if (orientationNew == self.interfaceOrientation)
        return;
    
    self.interfaceOrientation = orientationNew;
}

- (void)rtmpButtonTapped:(UIButton *)sender{
    
    __weak typeof(self) _self = self;
    if (isLive) {
        [rtmpLabel setText:@"Live"];
        [_self.session stopLive];
        isLive = NO;
        
    }else{
        // 录像文件
        NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
        unlink([pathToMovie UTF8String]);
        NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
        
        // 配置录制信息
        movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480, 640)];
        movieWriter.delegate = self;
        
        // 开始录制
        [movieWriter startRecording];
        
        [rtmpLabel setText:@"Stop Live"];
        
        LFLiveStreamInfo *stream = [LFLiveStreamInfo new];
        stream.url = @"rtmp://192.168.3.32/hls/magicSticker";
        
        [_self.session setRunning:YES];
        [_self.session startLive:stream];
        
        isLive = YES;
    }
    //    [self.blendFilter addTarget:movieWriter];
    //    [self.videoCamera setDelegate:movieWriter];
    //    [self.videoCamera setAudioEncodingTarget:(GPUImageMovieWriter *)movieWriter];
}

- (UIButton *)beautyButton {
    if (!_beautyButton) {
        _beautyButton = [UIButton new];
        _beautyButton.size = CGSizeMake(44, 44);
        _beautyButton.origin = CGPointMake(self.view.frame.size.width - 10 - _beautyButton.width, 20);
        [_beautyButton setImage:[UIImage imageNamed:@"camra_beauty"] forState:UIControlStateNormal];
        [_beautyButton setImage:[UIImage imageNamed:@"camra_beauty_close"] forState:UIControlStateSelected];
        _beautyButton.exclusiveTouch = YES;
        __weak typeof(self) _self = self;
        [_beautyButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            _self.session.beautyFace = !_self.session.beautyFace;
            _self.beautyButton.selected = !_self.session.beautyFace;
        }];
    }
    return _beautyButton;
}


- (void)configButton{
    
    CGFloat buttonWidth = self.view.frame.size.width / 5;
    CGFloat buttonHeight = self.view.frame.size.width / 480 * 640 + 5;
    
    self.rtmpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rtmpButton.frame = CGRectMake(buttonWidth * 1, buttonHeight + buttonWidth + 30 , buttonWidth * 3, buttonWidth/2);
    [self.rtmpButton setBackgroundColor:[UIColor lightGrayColor]];
    [self.rtmpButton.layer setCornerRadius:buttonWidth/4];
    rtmpLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,buttonWidth * 3,buttonWidth/2)];
    [rtmpLabel setText:@"Live"];
    [rtmpLabel setTextColor:[UIColor whiteColor]];
    [rtmpLabel setTextAlignment:NSTextAlignmentCenter];
    [rtmpLabel setFont:[UIFont systemFontOfSize:16.0f]];
    [self.rtmpButton addSubview:rtmpLabel];
    self.rtmpButton.tag = 105;
    [self.rtmpButton addTarget:self action:@selector(rtmpButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.rtmpButton];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



@end
