//
//  HQURLSegment.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQSegment.h"
#import <CoreMedia/CoreMedia.h>

/// url 媒体作为一路k流的片段
@interface HQURLSegment : HQSegment

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)init NS_UNAVAILABLE;


- (instancetype)initWithURL:(NSURL *)url index:(NSInteger)index timerange:(CMTimeRange)timerange scale:(CMTime)scale;

/// url
@property (nonatomic,copy,readonly) NSURL *url;

/// index
@property (nonatomic,readonly) NSInteger index;

/// timerange
@property (nonatomic,readonly) CMTimeRange timeRange;

/// scale 
@property (nonatomic,readonly) CMTime scale;

@end

