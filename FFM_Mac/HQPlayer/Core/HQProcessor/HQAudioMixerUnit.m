//
//  HQAudioMixerUnit.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAudioMixerUnit.h"

@interface HQAudioMixerUnit (){
    HQCapacity _capatity;
}
@property (nonatomic,readonly) NSMutableArray <HQAudioFrame *> *frames;

@end

@implementation HQAudioMixerUnit

- (instancetype)init{
    self = [super init];
    if (self) {
        [self flush];
    }
    return self;
}

- (void)dealloc{
    for (HQAudioFrame *frame in self->_frames) {
        [frame unlock];
    }
}
- (BOOL)putFrame:(HQAudioFrame *)frame{
    if (!CMTIMERANGE_IS_VALID(self->_timeRange) && CMTimeCompare(CMTimeAdd(frame.timeStamp, frame.duration), CMTimeRangeGetEnd(self->_timeRange)) <= 0) {
        return NO;
    }
    [frame lock];
    [self->_frames addObject:frame];
    [self updateTimeRange];
    return YES;
}
- (NSArray <HQAudioFrame *> *)frameToEndtime:(CMTime)endtime{
    NSMutableArray <HQAudioFrame *> *ret = [NSMutableArray new];
    NSMutableArray <HQAudioFrame *> *rem = [NSMutableArray new];
    for (HQAudioFrame *frame in self->_frames) {
        if (CMTimeCompare(frame.timeStamp, endtime) < 0) {
            [frame lock];
            [ret addObject:frame];
        }
        if (CMTimeCompare(CMTimeAdd(frame.timeStamp, frame.duration), endtime) <= 0) {
            [frame unlock];
            [rem addObject:frame];
        }
    }
    [self->_frames removeObjectsInArray:rem];
    [self updateTimeRange];
    return [ret copy];
}
- (HQCapacity )capatity{
    return self->_capatity;
}
- (void)flush{
    for (HQFrame *frame in self->_frames) {
        [frame unlock];
    }
    self->_frames = [NSMutableArray new];
    self->_timeRange = kCMTimeRangeInvalid;
    self->_capatity = HQCapacityCreate();
}
#pragma mark private
- (void)updateTimeRange{
    self->_capatity.count = (int)self->_frames.count;
    if (self->_capatity.count == 0) {
        self->_timeRange = kCMTimeRangeInvalid;
    }else{
        CMTime start = self->_frames.firstObject.timeStamp;
        CMTime end = CMTimeAdd(self->_frames.lastObject.timeStamp, self->_frames.lastObject.duration);
        self->_timeRange = CMTimeRangeFromTimeToTime(start, end);
    }
}
@end
