//
//  HQPLFImage.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/10.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPLFObject.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>

#if HQCPLATFORM_TARGET_OS_MAC

typedef NSImage HQPLFImage;

#elif HQCPLATFORM_TARGET_OS_IPHONE_OR_TV

typedef UIImage HQPLFImage;

#endif

HQPLFImage * HQPLFImageWithCGImage(CGImageRef image);

/// CVPixelBufferRef data buffer
HQPLFImage *HQPLFImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer);
CIImage * HQPLFImageCIImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer);
CGImageRef HQPLFImageCGImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer);

// RGB data buffer
HQPLFImage *HQPLFImageWithRGBData(uint8_t *rgb_data, int lineSize,int width,int height);
CGImageRef HQPLFImageCGImageWithRGBData(uint8_t *rgb_data, int lineSize,int width,int height);
