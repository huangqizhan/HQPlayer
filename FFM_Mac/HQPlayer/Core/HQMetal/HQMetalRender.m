//
//  HQMetalRender.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMetalRender.h"

//@interface HQMetalRender ()
//
//@property (nonatomic,strong) id<MTLDevice> device;
//@property (nonatomic,strong) id<MTLCommandQueue> commandQueue;
///// 编码器描述
//@property (nonatomic,strong) MTLRenderPassDescriptor *renderPassDes;
//
//@end
//
//@implementation HQMetalRender
//
//-  (instancetype)initWithDevice:(id<MTLDevice>)device{
//    self = [super init];
//    if (self) {
//        self.device = device;
//        self.commandQueue = [self.device newCommandQueue];
//        self.renderPassDes = [[MTLRenderPassDescriptor alloc] init];
//        /// 输出颜色
//        self.renderPassDes.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
//        self.renderPassDes.colorAttachments[0].loadAction = MTLLoadActionClear;
//        self.renderPassDes.colorAttachments[0].storeAction = MTLStoreActionStore;
//    }
//    return self;
//}
//
//- (id<MTLCommandBuffer>)drawModel:(HQMetalModel *)model
//                        viewports:(MTLViewport[])viewports
//                         pipeline:(HQMetalRenderPipeline *)pipeline
//                      projections:(NSArray <HQMetalProjection *> *)projections
//                       intextures:(NSArray<id<MTLTexture>> *)intextures
//                      outtextures:(id<MTLTexture>)outtexture{
//    /// 设置输出纹理
//    self.renderPassDes.colorAttachments[0].texture = outtexture;
//    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
//    /// encoder
//    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:self.renderPassDes];
//    /// 设置剔除模式
//    [commandEncoder setCullMode:MTLCullModeNone];
//    /// 设置渲染管线
//    [commandEncoder setRenderPipelineState:pipeline.state];
//    /// 设置顶点着色器   顶点数据
//    [commandEncoder setVertexBuffer:model.vertexBuffer offset:0 atIndex:0];
//    /// 设置片段着色器 输入纹理
//    for (int i = 0; i < intextures.count; i++) {
//        [commandEncoder setFragmentTexture:intextures[i] atIndex:i];
//    }
//    /// 设置变换数据及绘制
//    for (int i = 0; i < projections.count; i++) {
//        [commandEncoder setViewport:viewports[i]];
//        [commandEncoder setVertexBuffer:projections[i].matrixBuffer offset:0 atIndex:1];
//        [commandEncoder drawIndexedPrimitives:model.primitiveType indexCount:model.indexCount indexType:model.indexType indexBuffer:model.indexBuffer indexBufferOffset:0];
//    }
//    [commandEncoder endEncoding];
//    return  commandBuffer;
//}
//
//@end




@interface HQMetalRender ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) MTLRenderPassDescriptor *renderPassDescriptor;

@end

@implementation HQMetalRender

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init]) {
        self.device = device;
        self.commandQueue = [self.device newCommandQueue];
        self.renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
        self.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
        self.renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        self.renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    }
    return self;
}

- (id<MTLCommandBuffer>)drawModel:(HQMetalModel *)model
                        viewports:(MTLViewport[])viewports
                         pipeline:(HQMetalRenderPipeline *)pipeline
                      projections:(NSArray <HQMetalProjection *> *)projections
                       intextures:(NSArray<id<MTLTexture>> *)inputTextures
                      outtextures:(id<MTLTexture>)outputTexture
{
    self.renderPassDescriptor.colorAttachments[0].texture = outputTexture;
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:self.renderPassDescriptor];
    [encoder setCullMode:MTLCullModeNone];
    [encoder setRenderPipelineState:pipeline.state];
    [encoder setVertexBuffer:model.vertexBuffer offset:0 atIndex:0];
    for (NSUInteger i = 0; i < inputTextures.count; i++) {
        [encoder setFragmentTexture:inputTextures[i] atIndex:i];
    }
    for (NSUInteger i = 0; i < projections.count; i++) {
        [encoder setViewport:viewports[i]];
        [encoder setVertexBuffer:projections[i].matrixBuffer offset:0 atIndex:1];
        [encoder drawIndexedPrimitives:model.primitiveType
                            indexCount:model.indexCount
                             indexType:model.indexType
                           indexBuffer:model.indexBuffer
                     indexBufferOffset:0];
    }
    [encoder endEncoding];
    return commandBuffer;
}

@end
