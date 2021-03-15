//
//  HQTrackDemuxer.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQMutableTrack.h"
#import "HQDemuxable.h"

///  单路流解析 (HQMutableTrack) 
@interface HQTrackDemuxer : NSObject <HQDemuxable>


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;



- (instancetype)initWithTrack:(HQMutableTrack *)track;

@end

