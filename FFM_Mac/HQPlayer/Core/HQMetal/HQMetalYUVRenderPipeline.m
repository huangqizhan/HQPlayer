//
//  HQMetalYUVRenderPipeline.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/14.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMetalYUVRenderPipeline.h"

@implementation HQMetalYUVRenderPipeline

- (instancetype)initWithDevice:(id<MTLDevice>)device library:(id<MTLLibrary>)library{
    self = [super initWithDevice:device library:library];
    if (self) {
        self.descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        self.descriptor.vertexFunction = [self.library newFunctionWithName:@"vertexShader"];
        self.descriptor.fragmentFunction = [self.library newFunctionWithName:@"fragmentShaderYUV"];
        /// 输出格式 
        self.descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        self.state = [self.device newRenderPipelineStateWithDescriptor:self.descriptor error:nil];
    }
    return self;
}
@end
