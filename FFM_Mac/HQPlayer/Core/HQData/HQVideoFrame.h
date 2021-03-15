//
//  HQVideoFrame.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/13.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQFrame.h"
#import "HQPLFImage.h"
#import "HQVideoDescriptor.h"

@interface HQVideoFrame : HQFrame


@property (nonatomic,readonly) HQVideoDescriptor *descriptor;

/// 每一帧图像的第一行
- (int *)linesize;

/// 原数据
- (uint8_t **)data;

/// 像素缓冲区
- (CVPixelBufferRef)pixelBuffer;

/// 
- (HQPLFImage *)image;

@end

