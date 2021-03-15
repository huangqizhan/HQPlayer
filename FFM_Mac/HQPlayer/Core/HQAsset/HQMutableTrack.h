//
//  HQMutableTrack.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQTrack.h"
#import "HQTrack.h"
#import "HQSegment.h"

/// 1路流包含多个片段
@interface HQMutableTrack : HQTrack 

/// 多路流
@property (nonatomic,readonly,copy) NSArray <HQTrack *> *subtracks;

/// 多个segment
@property (nonatomic,readonly,copy) NSArray <HQSegment *> *segments;


- (BOOL)appendSegment:(HQSegment *)segment;


@end




