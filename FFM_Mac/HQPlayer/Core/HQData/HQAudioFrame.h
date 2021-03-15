//
//  HQAudioFrame.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/13.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQFrame.h"
#import "HQAudioDescriptor.h"

/// 音频帧
@interface HQAudioFrame : HQFrame

/// 解码描述
@property (nonatomic,readonly) HQAudioDescriptor *descriptor;

/// 1帧的采样数
@property (nonatomic,readonly) int numberOfSamples;

///  int 数组 每个通道的大小
- (int *)lineSize;

/// 原数据 
- (uint8_t **)data;

@end

