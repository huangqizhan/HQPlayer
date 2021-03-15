//
//  HQAsset+Interal.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAsset.h"
#import "HQDemuxable.h"

@interface HQAsset ()

/// 创建解复用对象
- (id<HQDemuxable>)newDemuxer;


@end

