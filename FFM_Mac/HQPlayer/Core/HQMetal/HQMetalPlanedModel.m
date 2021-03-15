//
//  HQMetalPlanedModel.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMetalPlanedModel.h"
#import "HQMetalTypes.h"

@implementation HQMetalPlanedModel

/// 顶点索引
static const UInt32 indices[] = {
    0, 1, 3, 0, 3, 2,
};

static const HQMetalVertex vertices[] = {
    { { -1.0,  -1.0,  0.0,  1.0 }, { 0.0, 1.0 } },
    { { -1.0,   1.0,  0.0,  1.0 }, { 0.0, 0.0 } },
    { {  1.0,  -1.0,  0.0,  1.0 }, { 1.0, 1.0 } },
    { {  1.0,   1.0,  0.0,  1.0 }, { 1.0, 0.0 } },
};

- (instancetype)initWithDevice:(id<MTLDevice>)device{
    self = [super initWithDevice:device];
    if (self) {
        self.indexCount = 6;
        self.indexType = MTLIndexTypeUInt32;
        self.primitiveType = MTLPrimitiveTypeTriangle;
        self.indexBuffer = [self.device newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceStorageModeShared];
        self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceStorageModeShared];
    }
    return self;
}


@end
