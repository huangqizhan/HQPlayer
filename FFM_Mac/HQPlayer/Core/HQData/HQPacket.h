//
//  HQPacket.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/3.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQTrack.h"
#import "HQData.h"

@interface HQPacket : NSObject<HQData>

/// AVPacket
@property (nonatomic,readonly) void *coreptr;

/// 流
@property (nonatomic,readonly) HQTrack *track;

/// 编解码时用户设置的信息
@property (nonatomic,readonly) NSDictionary *metadata;

/// 时长
@property (nonatomic,readonly) CMTime duration;

/// 时间 pts 
@property (nonatomic,readonly) CMTime timeStamp;

/// 编码时间
@property (nonatomic,readonly) CMTime decodetimeStamp;

/// size
@property (nonatomic,readonly) int size;


@end

