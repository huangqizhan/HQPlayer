//
//  HQDefine.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

/// C++ 调用时 需要前面添加 "C"

#if defined(__cplusplus)
#define HQPLAYER_EXTERN extern "C"
#else
#define HQPLAYER_EXTERN extern
#endif

/// 媒体类型
typedef NS_ENUM(NSUInteger, HQMediaType) {
    HQMediaTypeUnknown  = 0,
    /// 音频
    HQMediaTypeAudio    = 1,
    /// 视频
    HQMediaTypeVideo    = 2,
    /// 字幕
    HQMediaTypeSubtitle = 3,
};


/// 播放状态
typedef NS_ENUM(NSUInteger, HQPlayerState) {
    HQPlayerStateNone      = 0,
    /// 准备
    HQPlayerStatePreparing = 1,
    /// 正常播放
    HQPlayerStateReady     = 2,
    /// 失败 
    HQPlayerStateFailed    = 3,
};

///  回放状态
typedef NS_OPTIONS(NSUInteger, HQPlaybackState) {
    HQPlaybackStateNone     = 0,
    HQPlaybackStatePlaying  = 1 << 0,
    HQPlaybackStateSeeking  = 1 << 1,
    HQPlaybackStateFinished = 1 << 2,
};
/// 加载状态
typedef NS_ENUM(NSUInteger, HQLoadingState) {
    HQLoadingStateNone     = 0,
    HQLoadingStatePlaybale = 1,
    HQLoadingStateStalled  = 2,
    HQLoadingStateFinished = 3,
};


typedef NS_OPTIONS(NSUInteger, HQInfoAction) {
    HQInfoActionNone          = 0,
    HQInfoActionTimeCached    = 1 << 1,
    HQInfoActionTimePlayback  = 1 << 2,
    HQInfoActionTimeDuration  = 1 << 3,
    HQInfoActionTime          = HQInfoActionTimeCached | HQInfoActionTimePlayback | HQInfoActionTimeDuration,
    HQInfoActionStatePlayer   = 1 << 4,
    HQInfoActionStateLoading  = 1 << 5,
    HQInfoActionStatePlayback = 1 << 6,
    HQInfoActionState         = HQInfoActionStatePlayer | HQInfoActionStateLoading | HQInfoActionStatePlayback,
};

/// 有理数结构
typedef struct {
    // 分子
    int num;
    // 分目 
    int den;
} HQRational;

/// 时间
typedef struct {
    CMTime cached;
    CMTime playback;
    CMTime duration;
} HQTimeInfo;

typedef struct {
    HQPlayerState player;
    HQLoadingState loading;
    HQPlaybackState playback;
} HQStateInfo;

@class HQPlayer;

typedef void (^HQBlock)(void);
typedef void (^HQHandler)(HQPlayer *player);
typedef BOOL (^HQTimeReader)(CMTime *desire, BOOL *drop);
typedef void (^HQSeekResult)(CMTime time, NSError *error);
