//
//  HQTimeLayout.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/10.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQTime.h"

/// 时间变化范围校验 包括扩大缩小的倍数 ，和前后移动 
@interface HQTimeLayout : NSObject <NSCopying>

///放大缩小倍数
- (instancetype)initWithScale:(CMTime)scale;
/// 前后偏移量
- (instancetype)initWithOffset:(CMTime)offset;
/// 放大缩小倍数
@property (nonatomic,readonly) CMTime scale;
/// 前后偏移量
@property (nonatomic,readonly) CMTime offset;
/// 时长校验
- (CMTime)convertDuration:(CMTime)duration;
/// timeStamp 校验
- (CMTime)convertTimeStamp:(CMTime)timeStamp;
- (CMTime)reConvertTimeStamp:(CMTime)timeStamp;

- (BOOL)isEqualTimeLayout:(HQTimeLayout *)timeLayout;

@end

