//
//  HQMutiDemuxer.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDemuxable.h"

/// 多个HQTrackDemuxer的封装
@interface HQMutiDemuxer : NSObject <HQDemuxable>


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


- (instancetype)initWithDemuxers:(NSArray <id<HQDemuxable>> *)demuxers;


@end

