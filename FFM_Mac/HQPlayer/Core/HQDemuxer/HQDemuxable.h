//
//  HQDemuxable.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDemuxerOptions.h"
#import "HQPacket.h"

/// 解封装接口

@protocol HQDemuxerableDelegate;

@protocol HQDemuxable <NSObject>

@property (nonatomic,copy) HQDemuxerOptions *options;

@property (nonatomic,weak) id <HQDemuxerableDelegate>delegate;

/// 每一路流
@property (nonatomic,copy,readonly) NSArray <HQTrack *> *tracks;

/// 完成的流
@property (nonatomic,copy,readonly) NSArray <HQTrack *> *finishedTracks;

/// 编解码时用户设置的信息
@property (nonatomic,copy,readonly) NSDictionary *metadata;

/// 时长
@property (nonatomic,readonly) CMTime duration;

- (id<HQDemuxable>)shareDemuxer;

/**
 *
 */
- (NSError *)open;

/**
 *
 */
- (NSError *)close;

/**
 *
 */
- (NSError *)seekable;

/**
 *
 */
- (NSError *)seekToTime:(CMTime)time;

/**
 *
 */
- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter;

/**
 *
 */
- (NSError *)nextPacket:(HQPacket **)packet;



@end



@protocol HQDemuxerableDelegate <NSObject>

/// 解封装的过程是否退出 
- (BOOL)demuxableShouldAbortBlockingFunctions:(id<HQDemuxable>)demuxable;

@end
