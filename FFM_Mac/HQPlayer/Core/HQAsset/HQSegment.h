//
//  HQSegment.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

/// 多媒体片段
@interface HQSegment : NSObject<NSCopying>


+ (instancetype)segmentWithDuration:(CMTime)duration;


+ (instancetype)segmentWithUrl:(NSURL *)url index:(NSInteger)index;


+ (instancetype)segmentWithUrl:(NSURL *)url index:(NSInteger)index timerange:(CMTimeRange)timeRange scale:(CMTime)scale;


@end


