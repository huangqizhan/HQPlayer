//
//  HQMetalNV12RenderPipeline.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/14.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMetalNV12RenderPipeline.h"

@implementation HQMetalNV12RenderPipeline

- (instancetype)initWithDevice:(id<MTLDevice>)device library:(id<MTLLibrary>)library{
    self = [super initWithDevice:device library:library];
    if (self) {
        self.descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        self.descriptor.vertexFunction = [self.library newFunctionWithName:@"vertexShader"];
        self.descriptor.fragmentFunction = [self.library newFunctionWithName:@"fragmentShaderNV12"];
        /// 输出格式 
        self.descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        self.state = [self.device newRenderPipelineStateWithDescriptor:self.descriptor error:nil];
    }
    return self;
}

@end
