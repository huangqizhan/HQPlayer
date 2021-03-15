//
//  HQUrlDemuxer.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDemuxable.h"

/// URL媒体解封装
@interface HQUrlDemuxer : NSObject<HQDemuxable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;



- (instancetype)initWithURL:(NSURL *)url;


@property (nonatomic,copy,readonly) NSURL *URL;



@end

