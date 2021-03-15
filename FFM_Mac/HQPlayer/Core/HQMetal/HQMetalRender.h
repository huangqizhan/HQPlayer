//
//  HQMetalRender.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQMetalProjection.h"
#import "HQMetalModel.h"
#import "HQMetalRenderPipeline.h"

/// 渲染 负责生成commander
@interface HQMetalRender : NSObject

-  (instancetype)initWithDevice:(id<MTLDevice>)device;



/// 创建commandbufer
/// @param model model
/// @param viewports  viewports
/// @param pipeline pipeline
/// @param projections projections
/// @param inputTextures 输入纹理
/// @param outputTexture 输出纹理
- (id<MTLCommandBuffer>)drawModel:(HQMetalModel *)model
                        viewports:(MTLViewport[])viewports
                         pipeline:(HQMetalRenderPipeline *)pipeline
                      projections:(NSArray <HQMetalProjection *> *)projections
                       intextures:(NSArray<id<MTLTexture>> *)inputTextures
                      outtextures:(id<MTLTexture>)outputTexture;


@end
