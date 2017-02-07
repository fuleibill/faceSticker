//
//  CanvasView.m
//  Created by sluin on 15/7/1.
//  Copyright (c) 2015年 SunLin. All rights reserved.
//

#import "CanvasView.h"

#define kDeviceHeight [UIScreen mainScreen].bounds.size.height
#define kDeviceWidth  [UIScreen mainScreen].bounds.size.width

@interface CanvasView ()

//头部贴图
@property (nonatomic,strong) UIImageView *  headMapView;
//眼睛贴图
@property (nonatomic,strong) UIImageView * eyesMapView;
//鼻子贴图
@property (nonatomic,strong) UIImageView * noseMapView;
//左耳朵贴图
@property (nonatomic,strong) UIImageView * leftEarMapView;
//右耳朵贴图
@property (nonatomic,strong) UIImageView * rightEarMapView;
//嘴巴贴图
@property (nonatomic,strong) UIImageView * mouthMapView;
//身体贴图
@property (nonatomic,strong) UIImageView * bodyMapView;
//面部贴图
@property (nonatomic,strong) UIImageView * facialTextureMapView;
//背景贴图
@property (nonatomic,strong) UIImageView * backgroundMapView;
//全背景贴图
@property (nonatomic,strong) UIImageView * allbackgroundMapView;

@end

@implementation CanvasView{
    CGContextRef context ;
}

#pragma mark -- config all mapViews

// 头部贴图
-(UIImageView *) headMapView{
    if(_headMapView == nil){
        
        _headMapView = [[UIImageView alloc] init];
        [self addSubview:_headMapView];
        
    }
    return _headMapView;
}
-(void) setHeadMap:(UIImage *)headMap{
    if (_headMap != headMap) {
        _headMap = headMap;
        self.headMapView.image = _headMap;
        
    }
}

// 眼睛贴图
-(UIImageView *) eyesMapView{
    if(_eyesMapView == nil){
        
        _eyesMapView = [[UIImageView alloc] init];
        [self addSubview:_eyesMapView];
        
    }
    return _eyesMapView;
}
-(void) setEyesMap:(UIImage *)eyesMap{
    if (_eyesMap != eyesMap) {
        _eyesMap = eyesMap;
        self.eyesMapView.image = _eyesMap;
    }
}

// 嘴巴贴图
-(UIImageView *) mouthMapView{
    if(_eyesMapView == nil){
        
        _eyesMapView = [[UIImageView alloc] init];
        [self addSubview:_eyesMapView];
        
    }
    return _eyesMapView;
}
-(void) setMouthMap:(UIImage *)mouthMap{
    if (_mouthMap != mouthMap) {
        _mouthMap = mouthMap;
        self.mouthMapView.image = _mouthMap;
    }
}

// 鼻子贴图
-(UIImageView *) noseMapView{
    if(_noseMapView == nil){
        
        _noseMapView = [[UIImageView alloc] init];
        [self addSubview:_noseMapView];
        
    }
    return _noseMapView;
}
-(void) setNoseMap:(UIImage *)noseMap{
    if (_noseMap != noseMap) {
        _noseMap = noseMap;
        self.noseMapView.image = _noseMap;
        
    }
}

// 身体贴图
-(UIImageView *) bodyMapView{
    if(_bodyMapView == nil){
        
        _bodyMapView = [[UIImageView alloc] init];
        [self addSubview:_bodyMapView];
    }
    return _bodyMapView;
}
-(void) setBodyMap:(UIImage *)bodyMap{
    if (_bodyMap != bodyMap) {
        _bodyMap = bodyMap;
        self.bodyMapView.image = _bodyMap;  
    }
}

// 左右耳朵贴图
-(UIImageView *) leftEarMapView{
    if(_leftEarMapView == nil){
        
        _leftEarMapView = [[UIImageView alloc] init];
        [self addSubview:_leftEarMapView];
        
    }
    return _leftEarMapView;
}
-(void) setLeftEarMap:(UIImage *)leftEarMap{
    if (_leftEarMap != leftEarMap) {
        _leftEarMap = leftEarMap;
        self.leftEarMapView.image = _leftEarMap;
    }
}

-(UIImageView *) rightEarMapView{
    if(_rightEarMapView == nil){
        
        _rightEarMapView = [[UIImageView alloc] init];
        [self addSubview:_rightEarMapView];
        
    }
    return _rightEarMapView;
}
-(void) setRightEarMap:(UIImage *)rightEarMap{
    if (_rightEarMap != rightEarMap) {
        _rightEarMap = rightEarMap;
        self.rightEarMapView.image = _rightEarMap;
    }
}

// 脸部贴图
-(UIImageView *) facialTextureMapView{
    if(_facialTextureMapView == nil){
        
        _facialTextureMapView = [[UIImageView alloc] init];
        [self addSubview:_facialTextureMapView];
        
    }
    return _facialTextureMapView;
}
-(void) setFacialTextureMap:(UIImage *)facialTextureMap{
    if (_facialTextureMap != facialTextureMap) {
        _facialTextureMap = facialTextureMap;
        self.facialTextureMapView.image = _facialTextureMap;
        
    }
}

// 背景贴图
-(UIImageView *) backgroundMapView{
    if(_backgroundMapView == nil){
        
        _backgroundMapView = [[UIImageView alloc] init];
        [self addSubview:_backgroundMapView];
        
    }
    return _backgroundMapView;
}
- (void) setBackgroundMap:(UIImage *)backgroundMap{
    if (_backgroundMap != backgroundMap) {
        _backgroundMap = backgroundMap;
        self.backgroundMapView.image = _backgroundMap;
    }
}

// all背景贴图
-(UIImageView *) allbackgroundMapView{
    if(_allbackgroundMapView == nil){
        
        _allbackgroundMapView = [[UIImageView alloc] init];
        [self addSubview:_allbackgroundMapView];
        
    }
    return _allbackgroundMapView;
}
- (void) setAllbackgroundMap:(UIImage *)allbackgroundMap{
    if (_allbackgroundMap != allbackgroundMap) {
        _allbackgroundMap = allbackgroundMap;
        self.allbackgroundMapView.image = _allbackgroundMap;
    }
}


- (void)drawRect:(CGRect)rect {
    [self drawPointWithPoints:self.arrPersons] ;

}

-(void)drawPointWithPoints:(NSArray *)arrPersons{
    
    if (context) {
        CGContextClearRect(context, self.bounds) ;
    }
    context = UIGraphicsGetCurrentContext();

    double rotation = 0.0;
    //头部中点
    CGPoint midpoint = CGPointZero;
    CGPoint nosepoint = CGPointZero;
    CGPoint leftEarPoint = CGPointZero;
    CGPoint rightEarPoint = CGPointZero;
    CGPoint mouthPoint = CGPointZero;
    
    CGFloat spacing = 60;
    
    for (NSDictionary *dicPerson in self.arrPersons) {
        
#pragma mark - 识别面部关键点
        /*
         识别面部关键点
         */
        if ([dicPerson objectForKey:POINTS_KEY]) {
            
            for (NSString *strPoints in [dicPerson objectForKey:POINTS_KEY]) {
                CGPoint p = CGPointFromString(strPoints) ;
                CGContextAddEllipseInRect(context, CGRectMake(p.x - 1 , p.y - 1 , 2 , 2));
            }
            
#pragma mark - 取嘴角的点算头饰的旋转角度
            NSArray * strPoints = [dicPerson objectForKey:POINTS_KEY];
//            NSInteger strCount = [strPoints count];
//            NSLog(@"strPoints count is %ld",(long)strCount);
            //右边鼻孔
            CGPoint  strPoint1 = CGPointFromString(((NSString *)strPoints[2]));
//            CGContextAddEllipseInRect(context,CGRectMake(strPoint1.x - 1 , strPoint1.y - 1 , 2 , 2));
           //左边鼻孔
            CGPoint  strPoint2 = CGPointFromString(((NSString *)strPoints[15]));
//            CGContextAddEllipseInRect(context,CGRectMake(strPoint2.x - 1 , strPoint2.y - 1 , 2 , 2));
            
            //右边嘴角
            CGPoint  strPoint3 = CGPointFromString(((NSString *)strPoints[5]));
//            CGContextAddEllipseInRect(context,CGRectMake(strPoint3.x - 1 , strPoint3.y - 1 , 2 , 2));
            //左边嘴角
            CGPoint strPoint4 = CGPointFromString(((NSString *)strPoints[20]));
//            CGContextAddEllipseInRect(context,CGRectMake(strPoint4.x - 1 , strPoint4.y - 1 , 2 , 2));
            
           rotation = atan((strPoint3.x+strPoint4.x -strPoint1.x - strPoint2.x)/(strPoint3.y +strPoint4.y - strPoint1.y - strPoint2.y) *1.5);
            
            
#pragma mark - 取眉毛的点算头部的位置
            //左边眉毛中间点
            CGPoint  eyebrowsPoint1 = CGPointFromString(((NSString *)strPoints[16]));
//            CGContextAddEllipseInRect(context,CGRectMake(eyebrowsPoint1.x - 1 , eyebrowsPoint1.y - 1 , 2 , 2));
            
            //左边眉毛1号点
            CGPoint  eyebrowsPoint2 = CGPointFromString(((NSString *)strPoints[11]));
//            CGContextAddEllipseInRect(context,CGRectMake(eyebrowsPoint2.x - 1 , eyebrowsPoint2.y - 1 , 2 , 2));
            
            //右边眉毛中间点
            CGPoint  eyebrowsPoint3 = CGPointFromString(((NSString *)strPoints[17]));
//            CGContextAddEllipseInRect(context,CGRectMake(eyebrowsPoint3.x - 1 , eyebrowsPoint3.y - 1 , 2 , 2));
            
//            //右边眉毛一号点
            CGPoint eyebrowsPoint4 = CGPointFromString(((NSString *)strPoints[18]));
//            CGContextAddEllipseInRect(context,CGRectMake(eyebrowsPoint4.x - 1 , eyebrowsPoint4.y - 1 , 2 , 2));
//
            CGFloat midpointX  = (spacing *(eyebrowsPoint4.x + eyebrowsPoint2.x - eyebrowsPoint3.x - eyebrowsPoint1.x) / (eyebrowsPoint4.y + eyebrowsPoint2.y - eyebrowsPoint3.y - eyebrowsPoint1.y) + (eyebrowsPoint1.x + eyebrowsPoint3.x)) / 2;
            CGFloat midpointY = eyebrowsPoint2.y - spacing;
            
            midpoint = CGPointMake(midpointX, midpointY);
            nosepoint = CGPointMake(strPoint2.x, strPoint2.y);
            leftEarPoint = CGPointMake(eyebrowsPoint2.x - (-eyebrowsPoint1.x + eyebrowsPoint2.x)* 5, eyebrowsPoint2.y - (-eyebrowsPoint1.x + eyebrowsPoint2.x)*2);
            rightEarPoint = CGPointMake(eyebrowsPoint4.x - (eyebrowsPoint3.x - eyebrowsPoint4.x) * 0.9, eyebrowsPoint4.y - (eyebrowsPoint3.x - eyebrowsPoint4.x)*1.8);
            
//            CGContextAddEllipseInRect(context,CGRectMake(midpoint.x - 1 , midpoint.y - 1 , 2 , 2));
        }
        
        @try {
            BOOL isOriRect=NO;
            if ([dicPerson objectForKey:RECT_ORI]) {
                isOriRect=[[dicPerson objectForKey:RECT_ORI] boolValue];
            }
            
            if ([dicPerson objectForKey:RECT_KEY]) {
                
                CGRect rect=CGRectFromString([dicPerson objectForKey:RECT_KEY]);
                
                if(self.headMap){
                    CGFloat scale =  (rect.size.width / self.headMap.size.width) + 0.3;
                    CGFloat headMapViewW = scale * self.headMap.size.width;
                    CGFloat headmapViewH = scale * self.headMap.size.height;
                    
//                    CGRect frame  =  CGRectMake(midpoint.x - (headMapViewW * 0.5), midpoint.y - headmapViewH/2 * 0.8 - (kDeviceHeight-kDeviceWidth/480*640)/2, headMapViewW, headmapViewH);
                    CGPoint headCenter = CGPointMake(midpoint.x, midpoint.y + headmapViewH/3);
                    self.headMapView.center = headCenter;
//                    self.headMapView.frame = frame;
                    self.headMapView.bounds = CGRectMake(0, 0, headMapViewW, headmapViewH);
                    
                    self.headMapView.layer.anchorPoint = CGPointMake(0.5, 1);
                    self.headMapView.transform = CGAffineTransformMakeRotation(-rotation);
                }
                if(self.noseMap){
                    CGFloat scale =  (rect.size.width / self.noseMap.size.width) * 0.88 ;
                    CGFloat noseMapViewW = scale * self.noseMap.size.width /3.5;
                    CGFloat nosemapViewH = scale * self.noseMap.size.height /3.5 * 1.2;
                    
                    CGRect frame  =  CGRectMake(nosepoint.x , nosepoint.y - nosemapViewH /1.2 - (kDeviceHeight-kDeviceWidth/480*640)/2, noseMapViewW, nosemapViewH);
                    
                    self.noseMapView.frame = frame;
                    self.noseMapView.bounds = CGRectMake(0, 0, noseMapViewW, nosemapViewH);
                    
                    self.noseMapView.layer.anchorPoint = CGPointMake(0.5, 1);
//                    self.noseMapView.transform = CGAffineTransformMakeRotation(-rotation);
                }
                if(self.leftEarMap){
                    CGFloat scale =  (rect.size.width / self.leftEarMap.size.width) + 0.3;
                    CGFloat leftEarMapViewW = scale * self.leftEarMap.size.width /3.5 * 1.5;
                    CGFloat leftEarMapViewH = scale * self.leftEarMap.size.height /3.5 * 1.5;
    
                    CGRect frame  =  CGRectMake(leftEarPoint.x , leftEarPoint.y - leftEarMapViewH /1.2 - (kDeviceHeight-kDeviceWidth/480*640)/2, leftEarMapViewW, leftEarMapViewH);
                    
//                    [self.leftEarMapView setBackgroundColor:[UIColor redColor]];
                    
                    self.leftEarMapView.frame = frame;
                    self.leftEarMapView.bounds = CGRectMake(0, 0, leftEarMapViewW, leftEarMapViewH);
                    
                    self.leftEarMapView.layer.anchorPoint = CGPointMake(0.5, 1);
                    self.leftEarMapView.transform = CGAffineTransformMakeRotation(-rotation);
                }
                if(self.rightEarMap){
                    CGFloat scale =  (rect.size.width / self.rightEarMap.size.width) + 0.3;
                    CGFloat rightEarMapViewW = scale * self.rightEarMap.size.width /3.5 * 1.5;
                    CGFloat rightEarMapViewH = scale * self.rightEarMap.size.height /3.5 * 1.5;
                    
                    CGRect frame  =  CGRectMake(rightEarPoint.x , rightEarPoint.y - rightEarMapViewW /1.2 - (kDeviceHeight-kDeviceWidth/480*640)/2, rightEarMapViewW, rightEarMapViewH);
                    
                    self.rightEarMapView.frame = frame;
                    self.rightEarMapView.bounds = CGRectMake(0, 0, rightEarMapViewW, rightEarMapViewH);
                    
                    self.rightEarMapView.layer.anchorPoint = CGPointMake(0.5, 1);
                    self.rightEarMapView.transform = CGAffineTransformMakeRotation(-rotation);
                }
                if(self.backgroundMap){
                    CGFloat backgroundMapViewW = kDeviceWidth;
                    CGFloat backgroundMapViewH = kDeviceWidth / 375 * 180;
                    
                    CGRect frame  =  CGRectMake(0,kDeviceWidth / 480 * 640 - kDeviceWidth / 375 * 180, backgroundMapViewW, backgroundMapViewH);
                    
                    self.backgroundMapView.frame = frame;
                    self.backgroundMapView.bounds = CGRectMake(0, 0, backgroundMapViewW, backgroundMapViewH);
                }
                if(self.allbackgroundMap){
                    CGFloat allbackgroundMapViewW = kDeviceWidth;
                    CGFloat allbackgroundMapViewH = kDeviceWidth / 480 * 640;
                    
                    CGRect frame  =  CGRectMake(0,0, allbackgroundMapViewW, allbackgroundMapViewH);
                    
                    self.allbackgroundMapView.frame = frame;
                    self.allbackgroundMapView.bounds = CGRectMake(0, 0, allbackgroundMapViewW, allbackgroundMapViewH);
                }
                if(self.facialTextureMap){
                    CGFloat scale =  (rect.size.width / self.facialTextureMap.size.width) + 0.3;
                    CGFloat facialTextureMapViewW = scale * self.facialTextureMap.size.width /3.5 * 2.5;
                    CGFloat facialTextureMapViewH = scale * self.facialTextureMap.size.height /3.5 * 2.5;
                    
                    CGPoint facialCenter = CGPointMake(nosepoint.x * 1.1, nosepoint.y * 1.1);
                    self.facialTextureMapView.center = facialCenter;
                    self.facialTextureMapView.bounds = CGRectMake(0, 0, facialTextureMapViewW, facialTextureMapViewH);
                    
                    self.facialTextureMapView.layer.anchorPoint = CGPointMake(0.5, 1);
                    self.facialTextureMapView.transform = CGAffineTransformMakeRotation(-rotation);
                }
                if(self.bodyMap){
                    CGFloat scale =  (rect.size.width / self.bodyMap.size.width) + 0.3;
                    CGFloat bodyMapViewW = scale * self.bodyMap.size.width /3.5 * 2.5;
                    CGFloat bodyMapViewH = scale * self.bodyMap.size.height /3.5 * 2.5;
                    
                    CGPoint bodyCenter = CGPointMake(nosepoint.x , nosepoint.y * 1.1 + scale * self.facialTextureMap.size.height /3.8);
                    self.bodyMapView.center = bodyCenter;
                    [self bringSubviewToFront:self.bodyMapView];
                    self.bodyMapView.bounds = CGRectMake(0, 0, bodyMapViewW, bodyMapViewH);
                }
                self.clipsToBounds = YES;
            }
        } @catch (NSException *exception) {
            NSLog(@"exception is %@",exception);
        } @finally {
            
        }
    }

    [[UIColor greenColor] set];
    CGContextSetLineWidth(context, 2);
    CGContextStrokePath(context);
}

@end
