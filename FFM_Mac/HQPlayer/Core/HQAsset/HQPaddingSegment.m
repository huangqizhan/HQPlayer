//
//  HQPaddingSegment.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPaddingSegment.h"
#import "HQPaddinfDemuxer.h"

@implementation HQPaddingSegment

- (id)copyWithZone:(NSZone *)zone
{
    HQPaddingSegment *obj = [super copyWithZone:zone];
    obj->_duration = self->_duration;
    return obj;
}

- (instancetype)initWithDuration:(CMTime)duration
{
    if (self = [super init]) {
        self->_duration = duration;
    }
    return self;
}

- (NSString *)sharedDemuxerKey
{
    return nil;
}

- (id<HQDemuxable>)newDemuxer
{
    return [[HQPaddinfDemuxer alloc] initWithDuration:self->_duration];
}

- (id<HQDemuxable>)newDemuxerWithSharedDemuxer:(id<HQDemuxable>)demuxer
{
    return [self newDemuxer];
}
@end
