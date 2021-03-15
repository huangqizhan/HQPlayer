//
//  HQPacketOutput.h
//  FFM_Mac
//
//  Created by 黄麒展. on 2020/5/18.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDemuxerOptions.h"
#import "HQPacket+Internal.h"
#import "HQPacket.h"
#import "HQAsset.h"

typedef NS_ENUM(NSInteger, HQPacketOutputState) {
    HQPacketOutputStateNone     = 0,
    HQPacketOutputStateOpening  = 1,
    HQPacketOutputStateOpened   = 2,
    HQPacketOutputStateReading  = 3,
    HQPacketOutputStatePaused   = 4,
    HQPacketOutputStateSeeking  = 5,
    HQPacketOutputStateFinished = 6,
    HQPacketOutputStateClosed   = 7,
    HQPacketOutputStateFailed   = 8,
};

@class HQPacketOutput;

@protocol HQPacketOutputDelegate <NSObject>
/**
 *
 */
- (void)packetOutput:(HQPacketOutput *)packetOutput didChangeState:(HQPacketOutputState)state;
/**
 *
 */
- (void)packetOutput:(HQPacketOutput *)packetOutput didOutputPacket:(HQPacket *)packet;

@end

/// 读取packet 
@interface HQPacketOutput : NSObject

/// 解复用参数
@property (nonatomic, strong) HQDemuxerOptions *options;

///
@property (nonatomic, weak) id <HQPacketOutputDelegate> delegate;

///
@property (nonatomic, assign,readonly ) HQPacketOutputState state;

///
@property (nonatomic,copy ,readonly) NSError *error;

///
@property (nonatomic,copy, readonly) NSArray <HQTrack *> *tracks;

///
@property (nonatomic,copy, readonly) NSArray <HQTrack *> *finishedTracks;

///
@property (nonatomic,copy,readonly) NSDictionary *metadata;

///
@property (nonatomic,assign,readonly) CMTime duration;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/// 
- (instancetype)initWithAsset:(HQAsset *)asset;
///
- (BOOL)open;

///
- (BOOL)close;

///
- (BOOL)pause;

///
- (BOOL)resume;

///
- (BOOL)seekable;

///
- (BOOL)seekToTime:(CMTime)time;

///
- (BOOL)seekToTime:(CMTime)time result:(HQSeekResult)result;

///
- (BOOL)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter result:(HQSeekResult)result;


@end

