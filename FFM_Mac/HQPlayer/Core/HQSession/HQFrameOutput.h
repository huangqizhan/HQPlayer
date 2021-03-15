//
//  HQFrameOutput.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/30.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDemuxerOptions.h"
#import "HQDecoderOptions.h"
#import "HQAsset.h"
#import "HQCapacity.h"
#import "HQFrame.h"

/// frame 输出状态
typedef NS_ENUM(NSUInteger, HQFrameOutputState) {
    HQFrameOutputStateNone     = 0,
    HQFrameOutputStateOpening  = 1,
    HQFrameOutputStateOpened   = 2,
    HQFrameOutputStateReading  = 3,
    HQFrameOutputStateSeeking  = 4,
    HQFrameOutputStateFinished = 5,
    HQFrameOutputStateClosed   = 6,
    HQFrameOutputStateFailed   = 7,
};

@class HQFrameOutput;

@protocol HQFrameOutPutDelegate <NSObject>
/**
 *
 */
- (void)frameOutput:(HQFrameOutput *)frameOutput didChangeState:(HQFrameOutputState)state;

/**
 *
 */
- (void)frameOutput:(HQFrameOutput *)frameOutput didChangeCapacity:(HQCapacity)capacity type:(HQMediaType)type;

/**
 *
 */
- (void)frameOutput:(HQFrameOutput *)frameOutput didOutputFrames:(NSArray<__kindof HQFrame *> *)frames needsDrop:(BOOL(^)(void))needsDrop;

@end



@interface HQFrameOutput : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

///
- (instancetype)initWithAsset:(HQAsset *)asset;

/// 解复用选项
@property (nonatomic,copy) HQDemuxerOptions *demuxerOptions;

///解码选项
@property (nonatomic,copy) HQDecoderOptions *decodeOptions;

///
@property (nonatomic,weak) id <HQFrameOutPutDelegate> delegate;

/// state
@property (nonatomic,readonly) HQFrameOutputState state;

/// error
@property (nonatomic,copy,readonly) NSError *error;

/// 流
@property (nonatomic,copy,readonly) NSArray <HQTrack *> *tracks;

///
@property (nonatomic,copy,readonly) NSArray <HQTrack *> *selectedTracks;


@property (nonatomic,copy,readonly) NSDictionary *metaData;

@property (nonatomic,readonly) CMTime duration;

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
- (BOOL)pause:(HQMediaType)type;

/**
 *
 */
- (BOOL)resume:(HQMediaType)type;

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
- (BOOL)selectTracks:(NSArray<HQTrack *> *)tracks;

/**
 *
 */
- (HQCapacity)capacityWithType:(HQMediaType)type;





@end
