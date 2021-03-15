//
//  HQCodecDescriptor.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/3.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQCodecDescriptor.h"

@interface HQCodecDescriptor ()

@property (nonatomic,copy,readonly) NSArray <HQTimeLayout *> *timeLayouts;

@end

@implementation HQCodecDescriptor

- (id)copyWithZone:(NSZone *)zone{
    HQCodecDescriptor *one = [[HQCodecDescriptor alloc] init];
    [self fillTodDescriptor:one];
    return one;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self->_scale = CMTimeMake(1, 1);
        self->_timebase = AV_TIME_BASE_Q;
        self->_timeRange = CMTimeRangeMake(kCMTimeNegativeInfinity, kCMTimePositiveInfinity);
    }
    return self;
}
- (void)appendingTimeLayput:(HQTimeLayout *)timeLayout{
    NSMutableArray *timeLayouts = [[NSMutableArray alloc] initWithArray:self->_timeLayouts];
    [timeLayouts addObject:timeLayout];
    CMTime scale = CMTimeMake(1, 1);
    for (HQTimeLayout *layout in timeLayouts) {
        if (CMTIME_IS_NUMERIC(layout.scale)) {
            scale = HQCMTimeMultiply(scale, layout.scale);
        }
    }
    self->_scale = scale;
    self->_timeLayouts = timeLayouts;
    self->_timeRange = CMTimeRangeMake([timeLayout convertTimeStamp:self->_timeRange.start], [timeLayout convertDuration:self->_timeRange.duration]);
}
- (void)appendTimeRange:(CMTimeRange)timeRange{
    for (HQTimeLayout *layout in self->_timeLayouts) {
        timeRange = CMTimeRangeMake([layout convertTimeStamp:timeRange.start], [layout convertDuration:timeRange.duration]);
    }
    self->_timeRange = HQCMTimeRangeGetIntersection(self->_timeRange, timeRange);
}
- (CMTime)convertDuration:(CMTime)duration{
    for (HQTimeLayout *layout in self->_timeLayouts) {
        duration = [layout convertDuration:duration];
    }
    return duration;
}
- (CMTime)convertTimeStamp:(CMTime)timeStamp{
    for (HQTimeLayout *layout in self->_timeLayouts) {
        timeStamp = [layout convertTimeStamp:timeStamp];
    }
    return timeStamp;
}
- (void)fillTodDescriptor:(HQCodecDescriptor *)descriptor{
     descriptor->_track = self->_track;
     descriptor->_scale = self->_scale;
     descriptor->_metadata = self->_metadata;
     descriptor->_timebase = self->_timebase;
     descriptor->_codecpar = self->_codecpar;
     descriptor->_timeRange = self->_timeRange;
     descriptor->_timeLayouts = [self->_timeLayouts copy];
}

- (BOOL)isEqualToDescriptor:(HQCodecDescriptor *)descriptor{
    if (![self isEqualCodeContextToDescriptor:descriptor]) {
        return NO;
    }
    if (!CMTimeRangeEqual(descriptor->_timeRange, self->_timeRange)) {
        return NO;
    }
    if (self->_timeLayouts.count != descriptor->_timeLayouts.count) {
        return NO;
    }
    for (int i = 0; i < self->_timeLayouts.count; i++) {
        HQTimeLayout *des1 = [self->_timeLayouts objectAtIndex:i];
        HQTimeLayout *des2 = [descriptor->_timeLayouts objectAtIndex:i];
        if (![des1 isEqualTimeLayout:des2]) {
            return NO;
        }
    }
    return YES;
}
- (BOOL)isEqualCodeContextToDescriptor:(HQCodecDescriptor *)descriptor{
    if (!descriptor) {
        return NO;
    }
    if (descriptor->_track != self->_track) {
        return NO;
    }
    if (descriptor->_codecpar != self->_codecpar) {
        return NO;
    }
    if (av_cmp_q(descriptor->_timebase, self->_timebase) != 0) {
        return NO;
    }
    return YES;
}
@end
