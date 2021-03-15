//
//  HQSegment+Inteal.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQSegment.h"
#import "HQDemuxable.h"
@interface HQSegment ()

/// 解复用对应的key
- (NSString *)sharedDemuxerKey;

/// 解复用
- (id<HQDemuxable>)newDemuxer;


- (id<HQDemuxable>)newDemuxerWithSharedMuxer:(id<HQDemuxable>)demuxer;

@end

