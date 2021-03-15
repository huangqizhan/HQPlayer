//
//  HQMetalTextureLoader.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <CoreVideo/CoreVideo.h>

/// 纹理加载器
@interface HQMetalTextureLoader : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;


/// 从CVPixelBuffer 创建
/// @param pixelBuffer    pixelbuffer
- (NSArray<id <MTLTexture>> *)texturesWithCVTextureBuffer:(CVPixelBufferRef )pixelBuffer;


/// CoreVideoPixelformat
/// @param pixelFormat CoreVideo  Pixelformat
/// @param width width
/// @param hight hight
/// @param bytes bytes
/// @param bytesPerRow bytesperrow
- (NSArray <id <MTLTexture>> *)texturesWithMTLPixelFormat:(OSType)pixelFormat
                                             textureWidth:(NSUInteger)width
                                             textureHight:(NSUInteger)hight
                                                    bytes:(void **)bytes
                                              bytesPerRow:(int *)bytesPerRow;



/// metal pixel format
/// @param pixelFormat MTLPixelFormat
/// @param width width
/// @param hight hight
/// @param bytes bytes
/// @param bytesPerRow bytesperrow 
- (id <MTLTexture>)textureWithCVPixelFormat:(MTLPixelFormat)pixelFormat
                               textureWidth:(NSUInteger)width
                               textureHight:(NSUInteger)hight
                                      bytes:(void *)bytes
                                bytesPerRow:(int )bytesPerRow;


@end
