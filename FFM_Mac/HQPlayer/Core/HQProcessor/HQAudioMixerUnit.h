//
//  HQAudioMixerUnit.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQAudioFrame.h"
#import "HQCapacity.h"

/// 音频合并帧基本单元
@interface HQAudioMixerUnit : NSObject

///
@property (nonatomic,readonly) CMTimeRange timeRange;

/// 添加frame
- (BOOL)putFrame:(HQAudioFrame *)frame;

/// 一定范围内的audioframe
- (NSArray <HQAudioFrame *> *)frameToEndtime:(CMTime)endtime;

/// capacity
- (HQCapacity)capatity;

/// 
- (void)flush;

@end
