//
//  HQMetalViewPort.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/7.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Metal/Metal.h>


typedef NS_ENUM(NSUInteger, HQMetalViewportMode) {
    HQMetalViewportModeResize           = 0,
    HQMetalViewportModeResizeAspect     = 1,
    HQMetalViewportModeResizeAspectFill = 2,
};

/// 获取纹理的坐标
@interface HQMetalViewPort : NSObject

+ (MTLViewport)viewportWithLayerSize:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSizeForLeft:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSizeForRight:(MTLSize)layerSize;
+ (MTLViewport)viewportWithLayerSize:(MTLSize)layerSize textureSize:(MTLSize)textureSize mode:(HQMetalViewportMode)mode;


@end

