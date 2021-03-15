//
//  HQClock+Interal.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQClock.h"
#import "HQDefine.h"

@protocol HQClockDelegate;

@interface HQClock ()

/// delegate
@property (nonatomic,weak) id<HQClockDelegate>delegate;

/// 倍速
@property (nonatomic) Float64 rate;

/// currentTime
@property (nonatomic,readonly ) CMTime currentTime;


/// 调整音频时间基
/// @param time 时间段
/// @param running bool
- (void)setAudioTime:(CMTime)time running:(BOOL)running;

/// 调整视频时间基
/// @param time 时间段 
- (void)setVideoTime:(CMTime)time;

///
- (BOOL)open;

///
- (BOOL)close;

///
- (BOOL)pause;

///
- (BOOL)resume;

///
- (BOOL)flush;


@end

@protocol HQClockDelegate <NSObject>

/**
 *  时钟回调
 */
- (void)clock:(HQClock *)clock didChcnageCurrentTime:(CMTime)currentTime;

@end
