//
//  HQMetalSphereModel.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMetalSphereModel.h"
#import "HQMetalTypes.h"

static int const slicesCount    = 200;
static int const parallelsCount = slicesCount / 2;
static int const indicesCount   = slicesCount * parallelsCount * 6;
static int const verticesCount  = (slicesCount + 1) * (parallelsCount + 1);

/// 顶点索引
static UInt32 indices [indicesCount];
static HQMetalVertex vertices[verticesCount];

@implementation HQMetalSphereModel

- (instancetype)initWithDevice:(id<MTLDevice>)device{
    self = [super initWithDevice:device];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            int runCount = 0;
            float const radius = 1.0f;
            float const step = (2.0f * M_PI) / (float)slicesCount;
            for (int i = 0; i < parallelsCount + 1; i++) {
                for (int j = 0; j < slicesCount + 1; j++) {
                    HQMetalVertex vertex;
                    vertex.position[0] = radius * sinf(step * (float)i) * cosf(step * (float)j);
                    vertex.position[1] = radius * cosf(step * (float)i);
                    vertex.position[2] = radius * sinf(step * (float)i) * sinf(step * (float)j);
                    vertex.position[3] = 1.0;
                    vertex.texCoord[0] = (float)j / (float)slicesCount;
                    vertex.texCoord[1] = (float)i / (float)parallelsCount;
                    vertices[i * (slicesCount + 1) + j] = vertex;
                    if (i < parallelsCount && j < slicesCount) {
                        indices[runCount++] = i * (slicesCount + 1) + j;
                        indices[runCount++] = (i + 1) * (slicesCount + 1) + j;
                        indices[runCount++] = (i + 1) * (slicesCount + 1) + (j + 1);
                        indices[runCount++] = i * (slicesCount + 1) + j;
                        indices[runCount++] = (i + 1) * (slicesCount + 1) + (j + 1);
                        indices[runCount++] = i * (slicesCount + 1) + (j + 1);
                    }
                }
            }
        });
        self.indexCount = indicesCount;
        self.indexType = MTLIndexTypeUInt32;
        self.primitiveType = MTLPrimitiveTypeTriangle;
        self.indexBuffer = [self.device newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceStorageModeShared];
        self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceStorageModeShared];
    }
    return self;
}

@end
