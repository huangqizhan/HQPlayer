//
//  HQMetalRenderPipelinePool.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/14.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQMetalRenderPipeline.h"
#import <CoreVideo/CoreVideo.h>

/// 管理多个不同的渲染管线
@interface HQMetalRenderPipelinePool : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

/// 根据像素格式获取相应的 渲染管线 
- (HQMetalRenderPipeline *)pipelineWithCVPixelFormat:(OSType)pixpelFormat;
- (HQMetalRenderPipeline *)pipelineWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;


@end
