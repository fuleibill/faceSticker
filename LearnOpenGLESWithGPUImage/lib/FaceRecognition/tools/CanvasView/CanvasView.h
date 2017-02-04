//
//  CanvasView.h
//  Created by sluin on 15/7/1.
//  Copyright (c) 2015年 SunLin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CanvasView : UIView

#define POINTS_KEY @"POINTS_KEY"
#define RECT_KEY   @"RECT_KEY"
#define RECT_ORI   @"RECT_ORI"

@property (nonatomic , strong) NSArray *arrPersons ;

//左耳贴图
@property (nonatomic,strong) UIImage *  leftEarMap;
//右耳贴图
@property (nonatomic,strong) UIImage *  rightEarMap;
//头部贴图
@property (nonatomic,strong) UIImage *  headMap;
//眼睛贴图
@property (nonatomic,strong) UIImage * eyesMap;
//鼻子贴图
@property (nonatomic,strong) UIImage * noseMap;
//嘴巴贴图
@property (nonatomic,strong) UIImage * mouthMap;
//身体贴图
@property (nonatomic,strong) UIImage * bodyMap;
//面部贴图
@property (nonatomic,strong) UIImage * facialTextureMap;
//背景贴图
@property (nonatomic,strong) UIImage * backgroundMap;
//全背景贴图
@property (nonatomic,strong) UIImage * allbackgroundMap;

@end
