//
//  HQMetalRenderPipelinePool.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/14.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMetalRenderPipelinePool.h"
#import "HQMetalNV12RenderPipeline.h"
#import "HQMetalBGRARenderPipeline.h"
#import "HQMetalYUVRenderPipeline.h"
#import "HQPLFTarget.h"


#if HQCPLATFORM_TARGET_OS_MAC
#import "HQMetalShader_macosmetalib.h"
#elif HQCPLATFORM_TARGET_OS_IPHONE
#import "HQMetalShader_iosmetallib.h"
#elif HQCPLATFORM_TARGET_OS_TV
#import "HQMetalShader_tvosmetalib.h"
#endif



@interface HQMetalRenderPipelinePool ()

@property (nonatomic,strong) id<MTLDevice> device;
@property (nonatomic,strong) id <MTLLibrary> library;
@property (nonatomic,strong) HQMetalYUVRenderPipeline *yuvShader;
@property (nonatomic,strong) HQMetalNV12RenderPipeline *nv12Shader;
@property (nonatomic,strong) HQMetalBGRARenderPipeline *bgraShader;


@end

@implementation HQMetalRenderPipelinePool

- (instancetype)initWithDevice:(id<MTLDevice>)device{
    self = [super init];
    if (self) {
        self.device = device;
        self.library = [device newLibraryWithData:dispatch_data_create(metallib, sizeof(metallib), dispatch_get_global_queue(0, 0), ^{}) error:nil];
    }
    return self;
}

- (HQMetalRenderPipeline *)pipelineWithCVPixelFormat:(OSType)pixpelFormat{
    if (pixpelFormat == kCVPixelFormatType_420YpCbCr8Planar) {
        return self.yuvShader;
    } else if (pixpelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        return self.nv12Shader;
    } else if (pixpelFormat == kCVPixelFormatType_32BGRA) {
        return self.bgraShader;
    }
    return nil;
}
- (HQMetalRenderPipeline *)pipelineWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    return [self pipelineWithCVPixelFormat:CVPixelBufferGetPixelFormatType(pixelBuffer)];
}
- (HQMetalRenderPipeline *)yuvShader{
    if (_yuvShader == nil) {
        _yuvShader = [[HQMetalYUVRenderPipeline alloc] initWithDevice:self.device library:self.library];
    }
    return _yuvShader;
}

- (HQMetalRenderPipeline *)nv12Shader{
    if (_nv12Shader == nil) {
        _nv12Shader = [[HQMetalNV12RenderPipeline alloc] initWithDevice:self.device library:self.library];
    }
    return _nv12Shader;
}

- (HQMetalRenderPipeline *)bgraShader{
    if (_bgraShader == nil) {
        _bgraShader = [[HQMetalBGRARenderPipeline alloc] initWithDevice:self.device library:self.library];
    }
    return _bgraShader;
}
@end
