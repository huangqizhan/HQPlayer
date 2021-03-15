//
//  HQTimeLayout.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/10.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQTimeLayout.h"

@implementation HQTimeLayout

- (id)copyWithZone:(NSZone *)zone{
    HQTimeLayout *one = [HQTimeLayout new];
    one->_offset = self->_offset;
    one->_scale = self->_scale;
    return one;
}
- (instancetype)initWithScale:(CMTime)scale{
    self = [super init];
    if (self) {
        self->_scale = HQCMTimeValidate(scale, CMTimeMake(1, 1), NO);
        self->_offset = kCMTimeInvalid;
    }
    return self;
}
- (instancetype)initWithOffset:(CMTime)offset{
    self = [super init];
    if (self) {
        self->_offset = HQCMTimeValidate(offset, CMTimeMake(1, 1), NO);
        self->_scale = kCMTimeInvalid;
    }
    return self;
}

- (CMTime)convertDuration:(CMTime)duration{
    if (CMTIME_IS_NUMERIC(self->_scale)) {
        duration = HQCMTimeMultiply(duration, self->_scale);
    }
    return duration;
}
- (CMTime)convertTimeStamp:(CMTime)timeStamp{
    if (CMTIME_IS_NUMERIC(self->_scale)) {
        timeStamp = HQCMTimeMultiply(timeStamp, self->_scale);
    }
    if (CMTIME_IS_NUMERIC(self->_offset)) {
        timeStamp = CMTimeAdd(timeStamp, self->_offset);
    }
    return timeStamp;
}

- (CMTime)reConvertTimeStamp:(CMTime)timeStamp{
    if (CMTIME_IS_NUMERIC(self->_scale)) {
        timeStamp = HQCMTimeMultiply(timeStamp, self->_scale);
    }
    if (CMTIME_IS_NUMERIC(self->_offset)) {
        timeStamp = CMTimeSubtract(timeStamp, self->_offset);
    }
    return timeStamp;
}

- (BOOL)isEqualTimeLayout:(HQTimeLayout *)timeLayout{
    if (!timeLayout) {
        return NO;
    }
    if (CMTimeCompare(timeLayout->_offset, self->_offset) != 0) {
        return NO;
    }
    if (CMTimeCompare(timeLayout->_scale, self->_scale) != 0) {
        return NO;
    }
    return YES;
}


@end
