//
//  HQMutableAsset.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAsset.h"
#import "HQMutableTrack.h"
#import "HQDefine.h"

/// 多路媒体封装
@interface HQMutableAsset : HQAsset

///  每一路流
@property (nonatomic,copy,readonly) NSArray <HQMutableTrack *> *tracks;

/// 添加一路流
- (HQMutableTrack *)addtrack:(HQMediaType)type;


@end

