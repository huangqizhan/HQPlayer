//
//  HQPlayerItem+Internal.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/7/1.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPlayerItem.h"
#import "HQDemuxerOptions.h"
#import "HQDecoderOptions.h"
#import "HQProcessorOptions.h"
#import "HQCapacity.h"
#import "HQFrame.h"

typedef NS_ENUM(NSUInteger, HQPlayerItemState) {
    HQPlayerItemStateNone     = 0,
    HQPlayerItemStateOpening  = 1,
    HQPlayerItemStateOpened   = 2,
    HQPlayerItemStateReading  = 3,
    HQPlayerItemStateSeeking  = 4,
    HQPlayerItemStateFinished = 5,
    HQPlayerItemStateClosed   = 6,
    HQPlayerItemStateFailed   = 7,
};

@protocol HQPlayerItemDelegate ;



@interface HQPlayerItem ()

/// 解封装
@property (nonatomic ,copy) HQDemuxerOptions *demuxerOptions;

/// 解码
@property (nonatomic ,copy) HQDecoderOptions *decodeOptions;

///
@property (nonatomic ,copy) HQProcessorOptions *processOptions;

///
@property (nonatomic ,weak) id<HQPlayerItemDelegate>delegate;

/// 状态
@property (nonatomic ,readonly) HQPlayerItemState state;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)start;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)seekable;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time result:(HQSeekResult)result;

/**
 *
 */
- (BOOL)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter result:(HQSeekResult)result;

/**
 *
 */
- (HQCapacity)capacityWithType:(HQMediaType)type;

/**
 *
 */
- (BOOL)isAvailable:(HQMediaType)type;

/**
 *
 */
- (BOOL)isFinished:(HQMediaType)type;

/**
 *
 */
- (__kindof HQFrame *)copyAudioFrame:(HQTimeReader)timeReader;
- (__kindof HQFrame *)copyVideoFrame:(HQTimeReader)timeReader;


@end



@protocol HQPlayerItemDelegate <NSObject>

- (void)playerItem:(HQPlayerItem *)item didChangeState:(HQPlayerItemState)state;

- (void)playerItem:(HQPlayerItem *)item didChangeCapacity:(HQCapacity)capacity mediaType:(HQMediaType)type;


@end
