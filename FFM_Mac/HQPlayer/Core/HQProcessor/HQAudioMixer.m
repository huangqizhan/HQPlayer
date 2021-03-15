//
//  HQAudioMixer.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAudioMixer.h"
#import "HQFrame+Interal.h"
#import "HQAudioMixerUnit.h"
#import "HQVideoFrame.h"
#import "HQFFmpeg.h"

@interface HQAudioMixer ()

@property (nonatomic) CMTime starttime;

@property (nonatomic) NSMutableDictionary <NSNumber *, HQAudioMixerUnit *> *units;

@property (nonatomic) HQAudioDescriptor *descriptor;

@end

@implementation HQAudioMixer

- (instancetype)initWith:(NSArray<HQTrack *> *)tracks weights:(NSArray<NSNumber *> *)weights{
    self = [super init];
    if (self) {
        self->_tracks = tracks.copy;
        self->_weights = weights.copy;
        self->_starttime = kCMTimeNegativeInfinity;
        self->_units = [NSMutableDictionary dictionary];
        for (HQTrack *track in self->_tracks) {
            [self->_units setObject:[[HQAudioMixerUnit alloc] init] forKey:@(track.index)];
        }
    }
    return self;
}
#pragma mark --

- (HQAudioFrame *)putFrame:(HQAudioFrame *)frame{
    if (self->_tracks.count <= 1) {
        return frame;
    }
    if (CMTimeCompare(CMTimeAdd(frame.timeStamp, frame.duration), self->_starttime) <= 0) {
        [frame unlock];
        return nil;
    }
    if (!self->_descriptor) {
        self->_descriptor = frame.descriptor;
    }
    NSAssert([self->_descriptor isEqualToDescriptor:frame.descriptor], @"invalid format");
    NSAssert(frame.descriptor.format == AV_SAMPLE_FMT_FLTP, @"invalid format ");
    HQAudioMixerUnit *uint = [self.units objectForKey:@(frame.track.index)];
    BOOL ret = [uint putFrame:frame];
    [frame unlock];
    if (ret) {
        [self mixForPutFrame];
    }
    return nil;
}
- (HQAudioFrame *)finish{
    if (self->_tracks.count <= 1) {
        return nil;
    }
    return [self mixForFinish];
}
- (HQCapacity)capatity{
    __block HQCapacity capacity = HQCapacityCreate();
    [self.units enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, HQAudioMixerUnit * _Nonnull obj, BOOL * _Nonnull stop) {
        capacity = HQCapacityMaximum(capacity, obj.capatity);
    }];
    return capacity;
}
- (void)flush{
    [self.units enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, HQAudioMixerUnit * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj flush];
    }];
    self->_starttime = kCMTimePositiveInfinity;

}
#pragma mark --- 合并
- (HQAudioFrame *)mixForPutFrame{
    __block CMTime start = kCMTimePositiveInfinity;
    __block CMTime end = kCMTimePositiveInfinity;
    __block CMTime maximumDuration = kCMTimeZero;
    [self->_units enumerateKeysAndObjectsUsingBlock:^(id key, HQAudioMixerUnit *obj, BOOL *stop) {
        if (CMTIMERANGE_IS_INVALID(obj.timeRange)) {
            return;
        }
        start = CMTimeMinimum(start, obj.timeRange.start);
        start = CMTimeMaximum(start, self->_starttime);
        end = CMTimeMinimum(end, CMTimeRangeGetEnd(obj.timeRange));
        maximumDuration = CMTimeMaximum(maximumDuration, obj.timeRange.duration);
    }];
    if (CMTimeCompare(maximumDuration, CMTimeMake(8, 100)) < 0) {
        return nil;
    }
    return [self mixWithRange:CMTimeRangeFromTimeToTime(start, end)];
}
- (HQAudioFrame *)mixForFinish{
    __block CMTime start = kCMTimePositiveInfinity;
    __block CMTime end = kCMTimeNegativeInfinity;
    [self->_units enumerateKeysAndObjectsUsingBlock:^(id key, HQAudioMixerUnit *obj, BOOL *stop) {
        if (CMTIMERANGE_IS_INVALID(obj.timeRange)) {
            return;
        }
        start = CMTimeMinimum(start, obj.timeRange.start);
        start = CMTimeMaximum(start, self->_starttime);
        end = CMTimeMaximum(end, CMTimeRangeGetEnd(obj.timeRange));
    }];
    if (CMTimeCompare(CMTimeSubtract(end, start), kCMTimeZero) <= 0) {
        return nil;
    }
    HQAudioFrame *frame = [self mixWithRange:CMTimeRangeFromTimeToTime(start, end)];
    [self->_units enumerateKeysAndObjectsUsingBlock:^(id key, HQAudioMixerUnit *obj, BOOL *stop) {
        [obj flush];
    }];
    return frame;
}
- (HQAudioFrame *)mixWithRange:(CMTimeRange)range{
    if (!CMTIMERANGE_IS_VALID(range)) {
        return nil;
    }
    self->_starttime = CMTimeRangeGetEnd(range);
    HQAudioDescriptor *audioDescriptor = self->_descriptor;
    NSArray <NSNumber *> *weights = self->_weights;
    if (weights.count != self->_tracks.count) {
        NSMutableArray <NSNumber *> *objs = [NSMutableArray new];
        for (int i = 0; i < self->_tracks.count; i++) {
            [objs addObject:@(1.0 / self->_tracks.count)];
        }
        weights = objs.copy;
    }else{
        float sum = 0;
        for (NSNumber *num in weights) {
            sum += num.doubleValue;
        }
        NSMutableArray <NSNumber *> *objs = [NSMutableArray new];
        for (int i = 0; i < self->_tracks.count; i++) {
            [objs addObject:@([weights[i] doubleValue] / self->_tracks.count)];
        }
        weights = objs.copy;
    }
    CMTime start = range.start;
    CMTime duration = range.duration;
    /// 计算z该duration下的采样数
    int numofsamples = (int)CMTimeConvertScale(duration, audioDescriptor.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
    HQAudioFrame *audioFrame = [HQAudioFrame frameWithDescriptor:audioDescriptor numberofSamples:(int)numofsamples];
    NSMutableDictionary <NSNumber *,NSArray<HQAudioFrame *> *> *list = [NSMutableDictionary dictionary];
    for (HQTrack *track in self->_tracks) {
        NSArray <HQAudioFrame *> *frames = [self->_units[@(track.index)] frameToEndtime:CMTimeRangeGetEnd(range)];
        if (frames.count) {
            [list setObject:frames forKey:@(track.index)];
        }
    }
    /// 把一下帧合到audioFrame中
    NSMutableArray *discontinuous = [NSMutableArray array];
    for (int i = 0; i < self->_tracks.count; i++) {
        int lastEE = 0;
        for (HQAudioFrame *fra in list[@(self->_tracks[i].index)]) {
            /// start 时间到 当前帧的pts 的采样数
            int curNum = (int)CMTimeConvertScale(CMTimeSubtract(fra.timeStamp, start), audioDescriptor.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
            int e = curNum + fra.numberOfSamples;
            int ss = MAX(0, curNum);
            int ee = MIN(numofsamples, e);
            /// 不连续处
            if (ee - lastEE != 0) {
                NSRange range = NSMakeRange(MIN(ss, lastEE), ABS(ss - lastEE));
                [discontinuous addObject:[NSValue valueWithRange:range]];
            }
            lastEE = ee;
            /// 把数据添加到audioFrame 中
            for (int j = ss ; j < ee; j++) {
                for (int k = 0 ; k < audioDescriptor.numberofChannels ; k++) {
                    ((float *)audioFrame.core->data)[k] +=  (((float *)fra.data[k])[i - curNum] * weights[k].floatValue);
                }
            }
        }
    }
    ///  不连续处减半处理
    for (NSValue *obj in discontinuous) {
        NSRange range = obj.rangeValue;
        for (int c = 0; c < audioDescriptor.numberOfPlanes; c++) {
            float value = 0;
            if (range.location > 0) {
                value += ((float *)audioFrame.core->data[c])[range.location - 1] * 0.5;
            }
            if (NSMaxRange(range) < numofsamples - 1) {
                value += ((float *)audioFrame.core->data[c])[NSMaxRange(range)] * 0.5;
            }
            for (int i = (int)range.location; i < NSMaxRange(range); i++) {
                ((float *)audioFrame.core->data[c])[i] = value;
            }
        }
    }
    [list enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSArray<HQAudioFrame *> * _Nonnull objs, BOOL * _Nonnull stop) {
        for (HQAudioFrame *frame in objs) {
            [frame unlock];
        }
    }];
    audioFrame.codeDescriptor = [[HQCodecDescriptor alloc] init];
    [audioFrame fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
    return audioFrame;
}

@end
