//
//  HQDecoderOptions.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQAudioDescriptor.h"
#import "HQTime.h"

/// 解码描述
@interface HQDecoderOptions : NSObject <NSCopying>

/// avformat_open_input
@property (nonatomic,copy) NSDictionary *options;

/// ffmpeg 解码c线程
@property (nonatomic) BOOL threadsAuto;

/// 解码器的引用计数 
@property (nonatomic) BOOL refcountedFrames;

/// 硬件解码h264
@property (nonatomic) BOOL hardwareDecodeH264;

/// 硬件解码h265
@property (nonatomic) BOOL hardwareDecodeH265;

/// 最佳像素格式
@property (nonatomic) OSType preferredPixelFormat;

/// 支持的像素格式
@property (nonatomic, copy) NSArray<NSNumber *> *supportedPixelFormats;

///  支持的音频
@property (nonatomic, copy) NSArray<HQAudioDescriptor *> *supportedAudioDescriptors;

/// 重置帧率
@property (nonatomic) BOOL resetFrameRate;

/// 最佳帧率
@property (nonatomic) CMTime preferredFrameRate;



@end

