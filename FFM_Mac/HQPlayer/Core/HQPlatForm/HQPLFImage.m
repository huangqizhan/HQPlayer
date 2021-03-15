//
//  HQPLFImage.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/10.
//  Copyright © 2020 黄麒展. All rights reserved.
//


#import "HQPLFImage.h"
//#import <CoreGraphics/CoreGraphics.h>

#if HQCPLATFORM_TARGET_OS_MAC

HQPLFImage * HQPLFImageWithCGImage(CGImageRef image){
    return [[NSImage alloc] initWithCGImage:image size:CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image))];
}

HQPLFImage *HQPLFImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer){
    CIImage *ciimage = HQPLFImageCIImageWithCVPixelBuffer(pixelBuffer);
    if (!ciimage) return nil;
    NSCIImageRep *cimageRef = [NSCIImageRep imageRepWithCIImage:ciimage];
    NSImage *image = [[NSImage alloc] initWithSize:cimageRef.size];
    [image addRepresentation:cimageRef];
    return image;
}

CIImage * HQPLFImageCIImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer){
    if (@available(macOS 10.11,*)) {
        return [CIImage imageWithCVImageBuffer:pixelBuffer];
    }else{
        return nil;
    }
}
#elif HQCPLATFORM_TARGET_OS_IPHONE_OR_TV

HQPLFImage * HQPLFImageWithCGImage(CGImageRef image){
    return [UIImage imageWithCGImage:image];
}

HQPLFImage *HQPLFImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer){
    CIImage *ciImage = SGPLFImageCIImageWithCVPexelBuffer(pixelBuffer);
    if (!ciImage) return nil;
    return [UIImage imageWithCIImage:ciImage];
}

CIImage * HQPLFImageCIImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer){
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
     return image;
}
#endif



CGImageRef HQPLFImageCGImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer){
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t count = CVPixelBufferGetPlaneCount(pixelBuffer);
    if (count <= 0) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return nil;
    }
    uint8_t *bassAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(bassAddress, width, height, 8, bytesRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef imageref = CGBitmapContextCreateImage(context);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return imageref;
}



// RGB data buffer
HQPLFImage *HQPLFImageWithRGBData(uint8_t *rgb_data, int lineSize,int width,int height){
    CGImageRef imageRef = HQPLFImageCGImageWithRGBData(rgb_data, lineSize, width, height);
    if (!imageRef) {
        return nil;
    }
    HQPLFImage *image = HQPLFImageWithCGImage(imageRef);
    CGImageRelease(imageRef);
    return image;
}
CGImageRef HQPLFImageCGImageWithRGBData(uint8_t *rgb_data, int lineSize,int width,int height){
    CFDataRef date = CFDataCreate(kCFAllocatorDefault, rgb_data, lineSize * height);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(date);
    CGColorSpaceRef coloeSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageref = CGImageCreate(width, height, 8, 24, lineSize, coloeSpace, kCGBitmapByteOrderDefault, provider, NULL, NO, kCGRenderingIntentDefault);
    
    CFRelease(date);
    CGColorSpaceRelease(coloeSpace);
    CGDataProviderRelease(provider);
    return imageref;
}


