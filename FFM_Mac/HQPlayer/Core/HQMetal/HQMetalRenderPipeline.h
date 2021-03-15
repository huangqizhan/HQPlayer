//
//  HQMetalRenderPipeline.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/13.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Metal/Metal.h>

/// 渲染管线   用于描述commandbuffer 
@interface HQMetalRenderPipeline : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device library:(id<MTLLibrary>)library;

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLLibrary> library;
/// 渲染管线
@property (nonatomic, strong) id<MTLRenderPipelineState> state;
/// 渲染管线描述 
@property (nonatomic, strong) MTLRenderPipelineDescriptor *descriptor;

@end

