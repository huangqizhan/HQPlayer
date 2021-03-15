//
//  HQMetalTextureLoader.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMetalTextureLoader.h"

@interface HQMetalTextureLoader()

@property (nonatomic,strong) id<MTLDevice>device;
@property (nonatomic) CVMetalTextureCacheRef textureBuffer;

@end

@implementation HQMetalTextureLoader

- (instancetype)initWithDevice:(id<MTLDevice>)device{
    self = [super init];
    if (self) {
        self.device = device;
    }
    return self;
}
- (void)dealloc{
    if (self.textureBuffer) {
        CVMetalTextureCacheFlush(self.textureBuffer, 0);
        CFRelease(self.textureBuffer);
        self.textureBuffer = NULL;
    }
}
- (NSArray<id <MTLTexture>> *)texturesWithCVTextureBuffer:(CVPixelBufferRef )pixelBuffer{
    if (!self.textureBuffer) {
        CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureBuffer);
    }
    
    OSType formatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    CVMetalTextureRef texture;
    NSMutableArray *textures = [NSMutableArray new];
    /// YUV 3个 plane 通道
    if (formatType == kCVPixelFormatType_420YpCbCr8Planar) {
        for (int i = 0; i < 3; i++) {
            CVMetalTextureCacheCreateTextureFromImage(NULL,
                                                      self.textureBuffer,
                                                      pixelBuffer,
                                                      NULL,
                                                      MTLPixelFormatR8Unorm,
                                                      CVPixelBufferGetWidthOfPlane(pixelBuffer, i),
                                                      CVPixelBufferGetHeightOfPlane(pixelBuffer, i),
                                                      i,
                                                      &texture);
            [textures addObject:CVMetalTextureGetTexture(texture)];
            CVBufferRelease(texture);
            texture = NULL;
        }
    }else if (formatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange){
        /// （yuv）NV12 两个plane 通道
        MTLPixelFormat formats[2] = {MTLPixelFormatR8Unorm, MTLPixelFormatRG8Unorm};
        for (int i = 0; i < 2; i++) {
            CVMetalTextureCacheCreateTextureFromImage(
                                                      NULL,
                                                      self.textureBuffer,
                                                      pixelBuffer,
                                                      NULL,
                                                      formats[i],
                                                      CVPixelBufferGetWidthOfPlane(pixelBuffer, i),
                                                      CVPixelBufferGetHeightOfPlane(pixelBuffer, i),
                                                      i,
                                                      &texture);
            [textures addObject:CVMetalTextureGetTexture(texture)];
            CVBufferRelease(texture);
            texture = NULL;
        }
    }else if (formatType == kCVPixelFormatType_32BGRA){
        /// RGBA 一个通道
        CVMetalTextureCacheCreateTextureFromImage(NULL,
                                                  self.textureBuffer,
                                                  pixelBuffer,
                                                  NULL,
                                                  MTLPixelFormatBGRA8Unorm,
                                                  CVPixelBufferGetWidth(pixelBuffer),
                                                  CVPixelBufferGetHeight(pixelBuffer),
                                                  0,
                                                  &texture);
        [textures addObject:CVMetalTextureGetTexture(texture)];
        CVBufferRelease(texture);
        texture = NULL;
    }
    return textures.count ? textures : nil;
}

- (NSArray <id <MTLTexture>> *)texturesWithMTLPixelFormat:(OSType)pixelFormat
                                             textureWidth:(NSUInteger)width
                                             textureHight:(NSUInteger)hight
                                                    bytes:(void **)bytes
                                              bytesPerRow:(int *)bytesPerRow{
    static NSUInteger const channelCount = 3;
    NSUInteger planes = 0;
    NSUInteger widths[channelCount] = {0};
    NSUInteger heights[channelCount] = {0};
    MTLPixelFormat formats[channelCount] = {0};
    if (pixelFormat == kCVPixelFormatType_420YpCbCr8Planar) {
        planes = 3;
        widths[0] = width; //y
        widths[1] = width/2.0; //u
        widths[2] = width/2.0; //v
        heights[0] = hight; //y
        heights[1] = hight/2.0; //u
        heights[2] = hight/2.0;//v
        formats[0] = MTLPixelFormatR8Unorm;
        formats[1] = MTLPixelFormatR8Unorm;
        formats[2] = MTLPixelFormatR8Unorm;
    }else if (pixelFormat == kCVPixelFormatType_32BGRA){
        planes = 2;
        widths[0] = width; //y
        widths[1] = width/2.0; //uv
        heights[0] = hight; //y
        heights[1] = hight/2.0; //uv
        formats[0] = MTLPixelFormatR8Unorm;
        formats[1] = MTLPixelFormatRG8Unorm;
    }else if (pixelFormat == kCVPixelFormatType_32BGRA){
        /// RGB
        planes = 1;
        widths[0] = width;
        heights[0] = hight;
        formats[0] = MTLPixelFormatBGRA8Unorm;
    }
    NSMutableArray <id <MTLTexture>> *textures = [NSMutableArray array];
    for (int i = 0; i < planes; i++) {
         id <MTLTexture> texture = [self textureWithCVPixelFormat:formats[i] textureWidth:widths[i] textureHight:heights[i] bytes:bytes[i] bytesPerRow:bytesPerRow[i]];
        [textures addObject:texture];
    }
    return textures;
}
- (id <MTLTexture>)textureWithCVPixelFormat:(MTLPixelFormat)pixelFormat
                                           textureWidth:(NSUInteger)width
                                           textureHight:(NSUInteger)hight
                                                  bytes:(void *)bytes
                                            bytesPerRow:(int)bytesPerRow{
    MTLTextureDescriptor *des = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:width height:hight mipmapped:NO];
    id<MTLTexture> texture = [self.device newTextureWithDescriptor:des];
    [texture replaceRegion:MTLRegionMake2D(0, 0, width, hight) mipmapLevel:0 withBytes:bytes bytesPerRow:bytesPerRow];
    return texture;
}

@end
