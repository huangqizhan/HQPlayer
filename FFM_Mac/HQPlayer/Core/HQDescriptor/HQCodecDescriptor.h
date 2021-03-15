//
//  HQCodecDescriptor.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/3.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQTimeLayout.h"
#import "HQFFmpeg.h"
#import "HQTrack.h"

/// 解码描述
@interface HQCodecDescriptor : NSObject <NSCopying>

 /// 时间基
@property (nonatomic) AVRational timebase;

/// 解码参数 
@property (nonatomic) AVCodecParameters *codecpar;

/// 一路流
@property (nonatomic,strong) HQTrack *track;

/// 编解码时用户设置的信息
@property (nonatomic, strong) NSDictionary *metadata;

/// 编码时间区域
@property (nonatomic, readonly) CMTimeRange timeRange;

///  播放倍速   (sonic )
@property (nonatomic, readonly) CMTime scale;

- (CMTime)convertTimeStamp:(CMTime)timeStamp;

- (CMTime)convertDuration:(CMTime)duration;

/// 添加时间长度
- (void)appendTimeRange:(CMTimeRange)timeRange;

- (void)appendingTimeLayput:(HQTimeLayout *)timeLayout;

- (void)fillTodDescriptor:(HQCodecDescriptor *)descriptor;

- (BOOL)isEqualToDescriptor:(HQCodecDescriptor *)descriptor;

- (BOOL)isEqualCodeContextToDescriptor:(HQCodecDescriptor *)descriptor;


@end

 
