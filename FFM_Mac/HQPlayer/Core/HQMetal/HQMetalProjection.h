//
//  HQMetalProjection.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/13.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Metal/Metal.h>
#import <GLKit/GLKit.h>

/// 顶点坐标 变换数据 
@interface HQMetalProjection : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@property (nonatomic) GLKMatrix4 matrix;
@property (nonatomic, strong) id<MTLDevice> device;
/// buf 中存储 GLKMatrix4 
@property (nonatomic, strong) id<MTLBuffer> matrixBuffer;


@end

