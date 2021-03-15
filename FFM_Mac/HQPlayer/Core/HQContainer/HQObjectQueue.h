//
//  HQObjectQueue.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQData.h"
#import "HQCapacity.h"
#import "HQDefine.h"

/// 存放对象的队列 
@interface HQObjectQueue : NSObject

/// 初始化
/// @param count maxcount
- (instancetype)initWithMaxCount:(uint64_t)count;

/// 是否排序
@property (nonatomic) BOOL shouldSortsObjects;

/// 容量
- (HQCapacity)capacity;

#pragma mark --- set obj

/// 同步入队 需要等待
/// @param object obj
- (BOOL)putObjectSync:(id<HQData>)object;

/// 同步入队 需要等待
/// @param object obj
/// @param before 入队前
/// @param after 入队后
- (BOOL)putObjectSync:(id<HQData>)object before:(HQBlock)before after:(HQBlock)after;

/// 入队 无需等待
/// @param object object
- (BOOL)putObjectAsync:(id<HQData>)object;

#pragma mark --- get obj

/// 同步出队 需要等待
/// @param object obj
- (BOOL)getObjectSync:(id<HQData>*)object;


/// 出队 无需等待
/// @param object object
- (BOOL)getObjectAsync:(id<HQData> *)object;

/// 根据时间出队
/// @param object object
/// @param timeReader 出队前
/// @param discarded 出队后
- (BOOL)getObjectAsync:(id<HQData> *)object timeReader:(HQTimeReader)timeReader discareded:(uint64_t *)discarded;

/// 清空
- (BOOL)flush;

/// 销毁
- (BOOL)destroy;

@end
