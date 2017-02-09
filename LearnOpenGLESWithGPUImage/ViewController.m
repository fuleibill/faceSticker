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
#import "IFlyFaceImage.h"
#import "CanvasView.h"
#import "IFlyFaceResultKeys.h"
#import "CalculatorTools.h"
#import "LFLiveKit.h"
//#import "MSAudioEncoder.h"
//#import "MSH264Encoder.h"
//#import "MSRtmpService.h"



@interface ViewController () <GPUImageVideoCameraDelegate>
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
//@property (nonatomic , strong) MSGPUImageMovieWriter *movieWriter;
//@property (nonatomic , strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic , strong) GPUImageUIElement *faceView;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic , strong) GPUImageAlphaBlendFilter *blendFilter;
/**
 人脸识别
 */
@property (nonatomic, retain ) IFlyFaceDetector *faceDetector;
@property (nonatomic , strong) CanvasView   *viewCanvas;
/**
 Device orientation
 */
@property (nonatomic) CMMotionManager *motionManager;
@property (nonatomic) UIInterfaceOrientation interfaceOrientation;

@property (nonatomic) GPUImageBeautifyFilter *beautifyFilter;

/**
 Movie Encoder
*/
//@property(nonatomic, retain) MSH264Encoder* videoEncoder;
//@property(nonatomic, retain) MSAudioEncoder* audioEncoder;

@property (nonatomic) BOOL isLive;
@property (nonatomic) UILabel *rtmpLabel;

// rtmp push stream
@property (nonatomic, strong) LFLiveDebug *debugInfo;
@property (nonatomic, strong) LFLiveSession *session;

@end


@implementation ViewController{
}

@synthesize beautifyFilter;
@synthesize isLive;
@synthesize rtmpLabel;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    isLive = NO;

    // 人脸识别
    self.viewCanvas = [[CanvasView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width / 480 * 640)];
    self.viewCanvas.backgroundColor = [UIColor clearColor];
    self.viewCanvas.headMap = [UIImage imageNamed:@"newyearHear"];
    self.viewCanvas.allbackgroundMap = [UIImage imageNamed:@"newyearBack"];
    self.viewCanvas.clipsToBounds = YES;
    self.faceDetector = [IFlyFaceDetector sharedInstance];
    
    if(self.faceDetector){
        [self.faceDetector setParameter:@"1" forKey:@"detect"];
        [self.faceDetector setParameter:@"1" forKey:@"align"];
    }
    
//    NSString* strEnable=[NSString stringWithFormat:@"%@",[sender isOn]?@"1":@"0"] ;
    [self.faceDetector setParameter:@"1" forKey:@"align"];
    
//    [self.viewCanvas setBackgroundColor:[UIColor whiteColor]];
    
    // 滤镜初始化
    self.faceView = [[GPUImageUIElement alloc] initWithView:self.viewCanvas];
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.delegate = self;
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width / 480 * 640)];
    [self.view addSubview:self.filterView];
    [self.filterView setBackgroundColor:[UIColor clearColor]];
    
//    NSLog(@"self.frame is %@",NSStringFromCGRect(self.view.frame));
    
    // 响应链配置
    beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    [self.videoCamera addTarget:beautifyFilter];
    self.blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    self.blendFilter.mix = 1.0f;
    [beautifyFilter addTarget:self.blendFilter];
    [self.faceView addTarget:self.blendFilter];
    [beautifyFilter addTarget:self.filterView];
    
    [self.videoCamera startCameraCapture];
    
    // 结束回调
    @try {
        __weak typeof (self) weakSelf = self;
        [beautifyFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
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
    [self.view addSubview:self.viewCanvas];

    [self configButton];
    
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
    
    IFlyFaceImage* faceImg=[self faceImageFromSampleBuffer:sampleBuffer];
    //识别结果，json数据
    NSString* strResult=[self.faceDetector trackFrame:faceImg.data withWidth:faceImg.width height:faceImg.height direction:(int)faceImg.direction];
    
//    NSLog(@"strResult is %ld",faceImg.direction);
    
    //此处清理图片数据，以防止因为不必要的图片数据的反复传递造成的内存卷积占用
    faceImg.data=nil;
    
    //    [self praseTrackResult:strResult OrignImage:faceImg];
    NSMethodSignature *sig = [self methodSignatureForSelector:@selector(praseTrackResult:OrignImage:)];
    if (!sig) return;
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:self];
    [invocation setSelector:@selector(praseTrackResult:OrignImage:)];
    [invocation setArgument:&strResult atIndex:2];
    [invocation setArgument:&faceImg atIndex:3];
    [invocation retainArguments];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil  waitUntilDone:NO];
    
    faceImg=nil;
}

/*
 人脸识别
 */
-(void)praseTrackResult:(NSString*)result OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!result){
        return;
    }
    
    @try {
        NSError* error;
        NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* faceDic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        resultData=nil;
        if(!faceDic){
            return;
        }
        
        NSString* faceRet=[faceDic objectForKey:KCIFlyFaceResultRet];
        NSArray* faceArray=[faceDic objectForKey:KCIFlyFaceResultFace];
        faceDic=nil;
        
        int ret=0;
        if(faceRet){
            ret=[faceRet intValue];
        }
        //没有检测到人脸或发生错误
        if (ret || !faceArray || [faceArray count]<1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideFace];
            } ) ;
            return;
        }
        
        //检测到人脸
        NSMutableArray *arrPersons = [NSMutableArray array] ;

        for(id faceInArr in faceArray){
            
            if(faceInArr && [faceInArr isKindOfClass:[NSDictionary class]]){
                
                NSDictionary* positionDic=[faceInArr objectForKey:KCIFlyFaceResultPosition];
                NSString* rectString=[self praseDetect:positionDic OrignImage: faceImg];
                positionDic=nil;
                
                NSDictionary* landmarkDic=[faceInArr objectForKey:KCIFlyFaceResultLandmark];
                NSMutableArray* strPoints=[self praseAlign:landmarkDic OrignImage:faceImg];
                landmarkDic=nil;
                
                NSMutableDictionary *dicPerson = [NSMutableDictionary dictionary] ;
                if(rectString){
                    [dicPerson setObject:rectString forKey:RECT_KEY];
                }
                if(strPoints){
                    [dicPerson setObject:strPoints forKey:POINTS_KEY];
                }
                
                strPoints=nil;
                
                [dicPerson setObject:@"0" forKey:RECT_ORI];
                [arrPersons addObject:dicPerson] ;
                
                dicPerson=nil;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showFaceLandmarksAndFaceRectWithPersonsArray:arrPersons];
                } ) ;
            }
        }
        faceArray=nil;
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
    }
    
}


/*
 检测面部特征点
 */
-(NSMutableArray*)praseAlign:(NSDictionary* )landmarkDic OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!landmarkDic){
        return nil;
    }
    // 判断摄像头方向
    BOOL isFrontCamera = self.videoCamera.cameraPosition == AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = self.view.frame.size.width / faceImg.height;
    CGFloat heightScaleBy = self.view.frame.size.height / faceImg.width;
    
    NSMutableArray *arrStrPoints = [NSMutableArray array] ;
    NSEnumerator* keys=[landmarkDic keyEnumerator];
    for(id key in keys){
        id attr=[landmarkDic objectForKey:key];
        if(attr && [attr isKindOfClass:[NSDictionary class]]){
            
            id attr=[landmarkDic objectForKey:key];
            CGFloat x=[[attr objectForKey:KCIFlyFaceResultPointX] floatValue];
            CGFloat y=[[attr objectForKey:KCIFlyFaceResultPointY] floatValue];
            
            CGPoint p = CGPointMake(y,x);
            
            if(!isFrontCamera){
                p=pSwap(p);
                p=pRotate90(p, faceImg.height, faceImg.width);
            }
            
            p=pScale(p, widthScaleBy, heightScaleBy);
            
            [arrStrPoints addObject:NSStringFromCGPoint(p)];
            
        }
    }
    return arrStrPoints;
    
}



#pragma mark - 人脸识别相关方法
// 检测到人脸
- (void) showFaceLandmarksAndFaceRectWithPersonsArray:(NSMutableArray *)arrPersons{
    if (self.viewCanvas.hidden) {
        self.viewCanvas.hidden = NO ;
    }
    self.viewCanvas.arrPersons = arrPersons ;
    [self.viewCanvas setNeedsDisplay];
}

// 没有检测到人脸或发生错误
- (void) hideFace {
    if (!self.viewCanvas.hidden) {
        [UIView animateWithDuration:1.0 animations:^{
            self.viewCanvas.hidden = YES ;
        }];
    }
}


/*
 检测脸部轮廓
 */
-(NSString*)praseDetect:(NSDictionary* )positionDic OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!positionDic){
        return nil;
    }
    
    // 判断摄像头方向
    BOOL isFrontCamera = self.videoCamera.cameraPosition == AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = self.view.frame.size.width / faceImg.height;
    CGFloat heightScaleBy = self.view.frame.size.height / faceImg.width;
    
    CGFloat bottom =[[positionDic objectForKey:KCIFlyFaceResultBottom] floatValue];
    CGFloat top=[[positionDic objectForKey:KCIFlyFaceResultTop] floatValue];
    CGFloat left=[[positionDic objectForKey:KCIFlyFaceResultLeft] floatValue];
    CGFloat right=[[positionDic objectForKey:KCIFlyFaceResultRight] floatValue];
    
    float cx = (left+right)/2;
    float cy = (top + bottom)/2;
    float w = right - left;
    float h = bottom - top;
    
    float ncx = cy ;
    float ncy = cx ;
    
    CGRect rectFace = CGRectMake(ncx-w/2 ,ncy-w/2 , w, h);
    
    if(!isFrontCamera){
        rectFace=rSwap(rectFace);
        rectFace=rRotate90(rectFace, faceImg.height, faceImg.width);
        
    }
    
    rectFace=rScale(rectFace, widthScaleBy, heightScaleBy);
    rectFace = CGRectMake(rectFace.origin.x, rectFace.origin.y, rectFace.size.width, rectFace.size.height);
    return NSStringFromCGRect(rectFace);
    
}


- (IFlyFaceImage *) faceImageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer{
    
    CVImageBufferRef cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferRef pixelBufRef = cvimgRef;
    
    __weak typeof(self) _self = self;
    
    [_self.session pushVideo:pixelBufRef];
    _session.warterMarkView = self.viewCanvas;
    
    //获取灰度图像数据
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    uint8_t *lumaBuffer  = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,0);
    size_t width  = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef context=CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, grayColorSpace,0);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    IFlyFaceDirectionType faceOrientation=[self faceImageOrientation];
    
    IFlyFaceImage* faceImage=[[IFlyFaceImage alloc] init];
    if(!faceImage){
        return nil;
    }
    
    CGDataProviderRef provider = CGImageGetDataProvider(cgImage);
    
    faceImage.data= (__bridge_transfer NSData*)CGDataProviderCopyData(provider);
    faceImage.width=width;
    faceImage.height=height;
    faceImage.direction=faceOrientation;
    
    CGImageRelease(cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(grayColorSpace);
    
    return faceImage;
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

#pragma mark - 判断视频帧方向
-(IFlyFaceDirectionType)faceImageOrientation {
    IFlyFaceDirectionType faceOrientation=IFlyFaceDirectionTypeLeft;
    BOOL isFrontCamera = self.videoCamera.cameraPosition == AVCaptureDevicePositionFront;
    switch (self.interfaceOrientation) {
        case UIDeviceOrientationPortrait:{//
            faceOrientation=IFlyFaceDirectionTypeLeft;
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown:{
            faceOrientation=IFlyFaceDirectionTypeRight;
        }
            break;
        case UIDeviceOrientationLandscapeRight:{
            faceOrientation=isFrontCamera?IFlyFaceDirectionTypeUp:IFlyFaceDirectionTypeDown;
        }
            break;
        default:{//
            faceOrientation=isFrontCamera?IFlyFaceDirectionTypeDown:IFlyFaceDirectionTypeUp;
        }
            break;
    }
    
    return faceOrientation;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark -- config button usage

- (void)configButton{
    
    CGFloat buttonWidth = self.view.frame.size.width / 5;
    CGFloat buttonHeight = self.view.frame.size.width / 480 * 640 + 5;
    
    self.firstStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.firstStyleButton.frame = CGRectMake(buttonWidth * 0, buttonHeight, buttonWidth, buttonWidth + 20);
    UILabel *firstLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonWidth/8, buttonWidth, buttonWidth - buttonWidth/4, 20)];
    [firstLabel setText:@"广告魔法"];
    [firstLabel setTextColor:[UIColor grayColor]];
    [firstLabel setTextAlignment:NSTextAlignmentCenter];
    [firstLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.firstStyleButton addSubview:firstLabel];
    [self.firstStyleButton setImage:[UIImage imageNamed:@"elemeIcon"] forState:UIControlStateNormal];
    self.firstStyleButton.imageEdgeInsets = UIEdgeInsetsMake(buttonWidth/8,buttonWidth/8,buttonWidth/8 + 20,buttonWidth/8);
    self.firstStyleButton.tag = 100;
    [self.firstStyleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.firstStyleButton];
    
    self.secondStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.secondStyleButton.frame = CGRectMake(buttonWidth * 1, buttonHeight, buttonWidth, buttonWidth + 20);
    [self.secondStyleButton setImage:[UIImage imageNamed:@"cocacolaIcon"] forState:UIControlStateNormal];
    self.secondStyleButton.imageEdgeInsets = UIEdgeInsetsMake(buttonWidth/8,buttonWidth/8,buttonWidth/8 + 20,buttonWidth/8);
    UILabel *secondLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonWidth/8, buttonWidth, buttonWidth - buttonWidth/4, 20)];
    [secondLabel setText:@"品牌魔法"];
    [secondLabel setTextColor:[UIColor grayColor]];
    [secondLabel setTextAlignment:NSTextAlignmentCenter];
    [secondLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.secondStyleButton addSubview:secondLabel];
    self.secondStyleButton.tag = 101;
    [self.secondStyleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.secondStyleButton];
    
    self.thirdStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.thirdStyleButton.frame = CGRectMake(buttonWidth * 2, buttonHeight, buttonWidth, buttonWidth + 20);
    [self.thirdStyleButton setImage:[UIImage imageNamed:@"newYearIcon"] forState:UIControlStateNormal];
    self.thirdStyleButton.imageEdgeInsets = UIEdgeInsetsMake(buttonWidth/8,buttonWidth/8,buttonWidth/8 + 20,buttonWidth/8);
    UILabel *thirdLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonWidth/8, buttonWidth, buttonWidth - buttonWidth/4, 20)];
    [thirdLabel setText:@"新年魔法"];
    [thirdLabel setTextColor:[UIColor grayColor]];
    [thirdLabel setTextAlignment:NSTextAlignmentCenter];
    [thirdLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.thirdStyleButton addSubview:thirdLabel];
    self.thirdStyleButton.tag = 102;
    [self.thirdStyleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.thirdStyleButton];
    
    self.fourthStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fourthStyleButton.frame = CGRectMake(buttonWidth * 3, buttonHeight, buttonWidth, buttonWidth + 20);
    [self.fourthStyleButton setImage:[UIImage imageNamed:@"earIcon"] forState:UIControlStateNormal];
    self.fourthStyleButton.imageEdgeInsets = UIEdgeInsetsMake(buttonWidth/8,buttonWidth/8,buttonWidth/8 + 20,buttonWidth/8);
    UILabel *fourthLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonWidth/8, buttonWidth, buttonWidth - buttonWidth/4, 20)];
    [fourthLabel setText:@"趣味魔法"];
    [fourthLabel setTextColor:[UIColor grayColor]];
    [fourthLabel setTextAlignment:NSTextAlignmentCenter];
    [fourthLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.fourthStyleButton addSubview:fourthLabel];
    self.fourthStyleButton.tag = 103;
    [self.fourthStyleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.fourthStyleButton];
    
    self.fifthStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fifthStyleButton.frame = CGRectMake(buttonWidth * 4, buttonHeight, buttonWidth, buttonWidth + 20);
    [self.fifthStyleButton setImage:[UIImage imageNamed:@"seaIcon"] forState:UIControlStateNormal];
    self.fifthStyleButton.imageEdgeInsets = UIEdgeInsetsMake(buttonWidth/8,buttonWidth/8,buttonWidth/8 + 20,buttonWidth/8);
    UILabel *fifthLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonWidth/8, buttonWidth, buttonWidth - buttonWidth/4, 20)];
    [fifthLabel setText:@"少女魔法"];
    [fifthLabel setTextColor:[UIColor grayColor]];
    [fifthLabel setTextAlignment:NSTextAlignmentCenter];
    [fifthLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.fifthStyleButton addSubview:fifthLabel];
    self.fifthStyleButton.tag = 104;
    [self.fifthStyleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.fifthStyleButton];
    
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
    
    self.videoSaveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.videoSaveButton.frame = CGRectMake(buttonWidth * 0, buttonHeight + buttonWidth + 30 , buttonWidth, buttonWidth/3);
    UILabel *videoSaveLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,buttonWidth,buttonWidth/2)];
    [videoSaveLabel setText:@"switch"];
    [videoSaveLabel setTextColor:[UIColor lightGrayColor]];
    [videoSaveLabel setTextAlignment:NSTextAlignmentCenter];
    [videoSaveLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.videoSaveButton addSubview:videoSaveLabel];
    self.videoSaveButton.tag = 106;
    [self.videoSaveButton addTarget:self action:@selector(saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.videoSaveButton];
}

- (void)styleButtonTapped:(UIButton *)sender{
    
    [self configAllViewTransparent];
    @try {
        switch (sender.tag) {
            case 100:
                self.viewCanvas.backgroundMap = [UIImage imageNamed:@"eleme-bg"];
                self.viewCanvas.leftEarMap = [UIImage imageNamed:@"elemeLeftEar"];
                self.viewCanvas.rightEarMap = [UIImage imageNamed:@"elemeRightEar"];
                break;
            case 101:
                self.viewCanvas.leftEarMap = [UIImage imageNamed:@"cococolaLeftEar"];
                self.viewCanvas.rightEarMap = [UIImage imageNamed:@"cococolaRightEar"];
                self.viewCanvas.backgroundMap = [UIImage imageNamed:@"cococolaBg"];
                break;
            case 102:
                self.viewCanvas.headMap = [UIImage imageNamed:@"newyearHear"];
                self.viewCanvas.allbackgroundMap = [UIImage imageNamed:@"newyearBack"];
                break;
            case 103:
                self.viewCanvas.leftEarMap = [UIImage imageNamed:@"leftEarMeng"];
                self.viewCanvas.rightEarMap = [UIImage imageNamed:@"rightEarMeng"];
                self.viewCanvas.noseMap = [UIImage imageNamed:@"strawberryLeft"];
                break;
            case 104:
                self.viewCanvas.backgroundMap = [UIImage imageNamed:@"seaback"];
                self.viewCanvas.facialTextureMap = [UIImage imageNamed:@"seaface"];
                self.viewCanvas.bodyMap = [UIImage imageNamed:@"seabody"];
                break;
            case 105:
                
                break;
            default:
                break;
        }
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
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

- (void)saveButtonTapped:(UIButton *)sender{
    
    [self.videoCamera rotateCamera];
//    // 录像文件
//    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
//    unlink([pathToMovie UTF8String]);
//    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
//    
//    // 配置录制信息
//    movieWriter = [[MSGPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480, 640)];
//    movieWriter.delegate = self;
//    
////    movieWriter.encodingLiveVideo = YES;
//    
//    [self.blendFilter addTarget:movieWriter];
//    // 保存到相册
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [beautifyFilter removeTarget:movieWriter];
//        [movieWriter finishRecording];
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToMovie))
//        {
//            [library writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error)
//             {
//                 dispatch_async(dispatch_get_main_queue(), ^{
//
//                     if (error) {
//                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil
//                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                         [alert show];
//                     } else {
//                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil
//                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                         [alert show];
//                     }
//                 });
//             }];
//        }
//        else {
//            NSLog(@"error mssg)");
//        }
//    });
}

- (void)configAllViewTransparent{
    self.viewCanvas.noseMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.headMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.eyesMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.bodyMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.mouthMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.leftEarMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.rightEarMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.backgroundMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.allbackgroundMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.facialTextureMap = [UIImage imageNamed:@"transparentBack"];
}

@end
