//
//  HQMetalModel.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/12.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Metal/Metal.h>

/// 顶点数据
@interface HQMetalModel : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;
/// 定点数量
@property (nonatomic) NSUInteger indexCount;
/// 定点类型
@property (nonatomic) MTLIndexType indexType;
/// 图元类型
@property (nonatomic) MTLPrimitiveType primitiveType;
/// GPU
@property (nonatomic, strong) id<MTLDevice> device;
/// index buffer
@property (nonatomic, strong) id<MTLBuffer> indexBuffer;
/// vertex buffer 
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

@end
