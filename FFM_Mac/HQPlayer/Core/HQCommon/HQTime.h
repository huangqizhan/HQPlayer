//
//  HQTime.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>


/// CMTime 是否有效
/// @param time cmtime
/// @param infinity 是否无限
BOOL HQCMTimeIsValid(CMTime time, BOOL infinity);


/// 有效cmtime
/// @param time cmtime
/// @param defaultTime default time
/// @param infinity 是否无限
CMTime HQCMTimeValidate(CMTime time, CMTime defaultTime, BOOL infinity);


/// 秒对应cmtime
/// @param seconds 秒数
CMTime HQCMTimeMakeWithSeconds(Float64 seconds);


/// 乘法运算
/// @param time ctime1
/// @param multiplier cttime2
CMTime HQCMTimeMultiply(CMTime time, CMTime multiplier);


/// 分割运算
/// @param time time
/// @param divisor divisor 
CMTime HQCMTimeDivide(CMTime time, CMTime divisor);


/// 校验CMTimeRange
/// @param timeRange CMTimeRange
CMTimeRange HQCMTimeRangeFitting(CMTimeRange timeRange);


/// 获取两个range的交集
/// @param timeRange1 range1
/// @param timeRange2 range2 
CMTimeRange HQCMTimeRangeGetIntersection(CMTimeRange timeRange1, CMTimeRange timeRange2);
