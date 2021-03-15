//
//  HQMetalProjection.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/13.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMetalProjection.h"
#import "HQMetalTypes.h"

@implementation HQMetalProjection

- (instancetype)initWithDevice:(id<MTLDevice>)device{
    self = [super init];
    if (self) {
        self.device = device;
        self.matrixBuffer = [device newBufferWithLength:sizeof(HQMetalMatrix) options:(MTLResourceStorageModeShared)];
    }
    return self;
}

- (void)setMatrix:(GLKMatrix4)matrix{
    self->_matrix = matrix;
    ((HQMetalMatrix* )self.matrixBuffer.contents)->mvp = HQMatrixFloat4x4FromGLKMatrix4(matrix);
}

static matrix_float4x4 HQMatrixFloat4x4FromGLKMatrix4(GLKMatrix4 matrix){
    return (matrix_float4x4){{
        {matrix.m00, matrix.m01, matrix.m02, matrix.m03},
        {matrix.m10, matrix.m11, matrix.m12, matrix.m13},
        {matrix.m20, matrix.m21, matrix.m22, matrix.m23},
        {matrix.m30, matrix.m31, matrix.m32, matrix.m33}}};
}
@end
