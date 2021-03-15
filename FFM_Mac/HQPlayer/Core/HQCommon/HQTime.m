//
//  HQTime.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQTime.h"
#import "HQFFmpeg.h"

BOOL HQCMTimeIsValid(CMTime time, BOOL infinity){
    return
    CMTIME_IS_VALID(time) &&
    (infinity || (!CMTIME_IS_NEGATIVE_INFINITY(time) &&
                  !CMTIME_IS_POSITIVE_INFINITY(time)));
}
CMTime HQCMTimeValidate(CMTime time, CMTime defaultTime, BOOL infinity){
    if (HQCMTimeIsValid(time,infinity)) {
        return time;
    }
    NSCAssert(HQCMTimeIsValid(defaultTime,infinity), @"Invalid default time");
    return defaultTime;
}

CMTime HQCMTimeMakeWithSeconds(Float64 seconds){
    return CMTimeMakeWithSeconds(seconds, AV_TIME_BASE);
}

CMTime HQCMTimeMultiply(CMTime time, CMTime multiplier){
    int64_t maxV = ABS(time.value == 0 ? INT64_MAX : INT64_MAX / time.value);
    int32_t maxT = ABS(time.timescale == 0 ? INT32_MAX : INT32_MAX / time.timescale);
    if (multiplier.value > maxV || multiplier.value < -maxV || multiplier.timescale > maxT || multiplier.timescale < -maxT) {
        return CMTimeMultiplyByFloat64(time, CMTimeGetSeconds(multiplier));
    }
    return CMTimeMake(time.value * multiplier.value, time.timescale * multiplier.timescale);
}
CMTime SGCMTimeDivide(CMTime time, CMTime divisor){
    int64_t maxV = ABS(time.value == 0 ? INT64_MAX : INT64_MAX / time.value);
    int32_t maxT = ABS(time.timescale == 0 ? INT32_MAX : INT32_MAX / time.timescale);
    if (divisor.timescale > maxV || divisor.timescale < -maxV || divisor.value > maxT || divisor.value < -maxT) {
        return CMTimeMultiplyByFloat64(time, 1.0 / CMTimeGetSeconds(divisor));
    }
    return CMTimeMake(time.value * divisor.timescale, time.timescale * (int32_t)divisor.value);
}

CMTimeRange HQCMTimeRangeFitting(CMTimeRange timeRange){
    return CMTimeRangeMake(HQCMTimeValidate(timeRange.start, kCMTimeNegativeInfinity, YES),HQCMTimeValidate(timeRange.duration, kCMTimePositiveInfinity, YES));
}

CMTimeRange HQCMTimeRangeGetIntersection(CMTimeRange timeRange1, CMTimeRange timeRange2){
    CMTime start1 = HQCMTimeValidate(timeRange1.start, kCMTimeNegativeInfinity, YES);
    CMTime start2 = HQCMTimeValidate(timeRange2.start, kCMTimeNegativeInfinity, YES);
    CMTime end1 = HQCMTimeValidate(CMTimeRangeGetEnd(timeRange1), kCMTimePositiveInfinity, YES);
    CMTime end2 = HQCMTimeValidate(CMTimeRangeGetEnd(timeRange2), kCMTimePositiveInfinity, YES);
    return CMTimeRangeFromTimeToTime(CMTimeMaximum(start1, start2), CMTimeMinimum(end1, end2));
}
