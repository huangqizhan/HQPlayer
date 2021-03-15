//
//  HQDecodeLoop.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDecoderOptions.h"
#import "HQTrack.h"
#import "HQPacket.h"
#import "HQCapacity.h"
#import "HQFrame.h"

typedef NS_ENUM(NSUInteger, HQDecodeLoopState) {
    /// 
    HQDecodeLoopStateNone     = 0,
    ///
    HQDecodeLoopStateDecoding = 1,
    /// 停滞
    HQDecodeLoopStateStalled  = 2,
    ///
    HQDecodeLoopStatePaused   = 3,
    ///
    HQDecodeLoopStateClosed   = 4,
};

@protocol HQDecodeLoopDelegate ;

/// 音视频解码队列 
@interface HQDecodeLoop : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


- (instancetype)initWithDecoderClass:(Class)decoderClass;


@property (nonatomic, weak) id<HQDecodeLoopDelegate> delegate;


@property (nonatomic, copy) HQDecoderOptions *options;


- (HQDecodeLoopState)state;


- (BOOL)open;


- (BOOL)close;


- (BOOL)pause;


- (BOOL)resume;


- (BOOL)flush;


- (BOOL)finish:(NSArray<HQTrack *> *)tracks;


- (BOOL)putPacket:(HQPacket *)packet;

@end

@protocol HQDecodeLoopDelegate <NSObject>

/// 解码状态
- (void)decodeLoop:(HQDecodeLoop *)decodeLoop didChangeState:(HQDecodeLoopState)state;

/// 总的容量
- (void)decodeLoop:(HQDecodeLoop *)decodeLoop didChangeCapacity:(HQCapacity)capacity;

/// 解码后输出
- (void)decodeLoop:(HQDecodeLoop *)decodeLoop didOutputFrames:(NSArray<__kindof HQFrame *> *)frames needsDrop:(BOOL(^)(void))needsDrop;

@end
