//
//  HQURLSegment.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQURLSegment.h"
#import "HQTime.h"
#import "HQSegment+Inteal.h"
#import "HQUrlDemuxer.h"
#import "HQEXTractingDemuxer.h"


@implementation HQURLSegment


- (id)copyWithZone:(NSZone *)zone{
    HQURLSegment *obj = [[self.class alloc] init];
    obj->_scale = self->_scale;
    obj->_url = self->_url;
    obj->_timeRange = self->_timeRange;
    obj->_index = self->_index;
    return obj;
}

- (instancetype)initWithURL:(NSURL *)url index:(NSInteger)index timerange:(CMTimeRange)timerange scale:(CMTime)scale{
    self = [super init];
    NSAssert(CMTimeCompare(scale, CMTimeMake(1, 10)) <= 0, @"invalid timescale");
    NSAssert(CMTimeCompare(scale, CMTimeMake(10, 1)), @"invalid timescale");
    scale = HQCMTimeValidate(scale, CMTimeMake(1, 1), NO);
    if (self) {
        self->_url = url;
        self->_index = index;
        self->_timeRange = timerange;
        self->_scale = scale;
    }
    return self;
}

- (NSString *)sharedDemuxerKey{
   return self->_url.isFileURL ? self->_url.path : self->_url.absoluteString;
}

- (id<HQDemuxable>)newDemuxer{
    return [self newDemuxerWithSharedMuxer:nil];
}
- (id<HQDemuxable>)newDemuxerWithSharedMuxer:(id<HQDemuxable>)demuxer{
    if (!demuxer) {
        demuxer = [[HQUrlDemuxer alloc] initWithURL:self->_url];
    }
    HQEXTractingDemuxer *exdemxer = [[HQEXTractingDemuxer alloc] initWith:demuxer index:self->_index timerange:self->_timeRange scale:self->_scale];
    return exdemxer;
}


@end
