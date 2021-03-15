//
//  HQPaddingSegment.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQSegment.h"
#import "HQDemuxable.h"

///什么也不做类似于暂停片段  
@interface HQPaddingSegment : HQSegment  


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


- (instancetype)initWithDuration:(CMTime)duration;



@property (nonatomic, readonly) CMTime duration;


@end

