//
//  HQVideoRender.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/6.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQVideoDescriptor.h"
#import "HQPLFView.h"
#import "HQVideoFrame.h"
#import "HQPLFImage.h"



/* 视频呈现 模式  */
typedef NS_ENUM(NSUInteger, HQDisplayMode) {
    HQDisplayModePlane = 0,
    HQDisplayModeVR    = 1,
    HQDisplayModeVRBox = 2,
};
/* 视频放缩模式  */
typedef NS_ENUM(NSUInteger, HQScalingMode) {
    HQScalingModeResize           = 0,
    HQScalingModeResizeAspect     = 1,
    HQScalingModeResizeAspectFill = 2,
};

//// 视频渲染器  
@interface HQVideoRender : NSObject

/// 支持的像素格式  
+ (NSArray<NSNumber *> *)supportedPixelFormats;

/// 是否支持像素h格式
+ (BOOL)isSupportedInputFormat:(int)format;

/// 渲染视图的容器
@property (nonatomic, strong) HQPLFView *view;


//@property (nonatomic, strong, readonly) SGVRViewport *viewport;

@property (nonatomic,copy) void(^frameOutput) (HQVideoFrame *frame);

/// 每秒的渲染帧
@property (nonatomic) NSInteger preferredFramesPerSecond;

@property (nonatomic,assign) HQDisplayMode displayMode;
@property (nonatomic,assign) HQScalingMode scalingMode;

- (HQPLFImage *)currentImage;


@end

