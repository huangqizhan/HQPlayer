//
//  HQFrame.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/13.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQData.h"
#import "HQTrack.h"
/// 数据通道
static int const HQFramePlaneCount = 8;

@interface HQFrame : NSObject<HQData>

/// AVFrame
@property (nonatomic,readonly) void *coreptr;

/// 流
@property (nonatomic,readonly) HQTrack *track;

/// 原数据
@property (nonatomic,readonly) NSDictionary *metadata;

/// 时长
@property (nonatomic,readonly) CMTime duration;

/// pts
@property (nonatomic, readonly) CMTime timeStamp;

///dts 
@property (nonatomic,readonly) CMTime decodeTimeStamp;

///size
@property (nonatomic,readonly) int size;



@end

