//
//  HQSegment.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQSegment.h"
#import "HQSegment+Inteal.h"
#import "HQURLSegment.h"
#import "HQPaddingSegment.h"


@implementation HQSegment

+ (instancetype)segmentWithDuration:(CMTime)duration{
    return [HQPaddingSegment segmentWithDuration:duration];
}


+ (instancetype)segmentWithUrl:(NSURL *)url index:(NSInteger)index{
    return [HQURLSegment segmentWithUrl:url index:index timerange:kCMTimeRangeInvalid scale:kCMTimeInvalid];
}

+ (instancetype)segmentWithUrl:(NSURL *)url index:(NSInteger)index timerange:(CMTimeRange)timeRange scale:(CMTime)scale{
    return [HQURLSegment segmentWithUrl:url index:index timerange:timeRange scale:scale];
}

- (id)copyWithZone:(NSZone *)zone{
    return [[self.class alloc] init];
}

- (NSString *)sharedDemuxerKey{
    NSAssert(NO, @"use subclass");
    return nil;
}
- (id<HQDemuxable>)newDemuxer{
    NSAssert(NO, @"use subclass");
    return nil;
}
- (id<HQDemuxable>)newDemuxerWithSharedMuxer:(id<HQDemuxable>)demuxer{
    NSAssert(NO, @"use subclass");
    return nil;
}

@end
