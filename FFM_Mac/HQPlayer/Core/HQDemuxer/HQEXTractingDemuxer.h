//
//  HQEXTractingDemuxer.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDemuxable.h"

/// 媒体片段解复用
@interface HQEXTractingDemuxer : NSObject <HQDemuxable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

///
- (instancetype)initWith:(id<HQDemuxable>)demuxer index:(NSInteger)index timerange:(CMTimeRange)timerange scale:(CMTime)scale;

/// 解复用器
@property (nonatomic,strong,readonly) id<HQDemuxable>demuxer;

/// index
@property (nonatomic,readonly) NSInteger index;

/// timerange
@property (nonatomic,readonly) CMTimeRange timeRange;

/// scale
@property (nonatomic,readonly) CMTime scale;

/// 
@property (nonatomic,readonly) BOOL overgop;

@end

