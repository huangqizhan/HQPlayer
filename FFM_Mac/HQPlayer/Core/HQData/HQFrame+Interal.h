//
//  HQFrame+Interal.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/13.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQFrame.h"
#import "HQAudioFrame.h"
#import "HQVideoFrame.h"
#import "HQCodecDescriptor.h"
#import "HQFFmpeg.h"
#import "HQAudioDescriptor.h"
#import "HQVideoDescriptor.h"


@interface HQFrame ()

+ (instancetype)frame;

/// 帧
@property (nonatomic,readonly) AVFrame *core;
/// 编码描述
@property (nonatomic) HQCodecDescriptor *codeDescriptor;

- (void)fill;

- (void)fillWithFrame:(HQFrame *)frame;

- (void)fillWithTimeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp duration:(CMTime)duration;

@end


@interface HQAudioFrame ()


/// 音频帧
/// @param descriptor 音频描述
/// @param numofSamples s采样率
+ (instancetype)frameWithDescriptor:(HQAudioDescriptor *)descriptor numberofSamples:(int)numofSamples;

@end


@interface HQVideoFrame ()

/// 视频帧
/// @param descriptor 视频描述
+ (instancetype)frameWithDescriptor:(HQVideoDescriptor *)descriptor;

@end
