//
//  HQTrack.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDefine.h"

/// 一路流
@interface HQTrack : NSObject <NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/// AVStream 的指针
@property (nonatomic,readonly) void *coreptr;


/// 媒体类型
@property (nonatomic,readonly) HQMediaType type;


/// 流的索引
@property (nonatomic,readonly) NSInteger index;

 
/// get track with tracks with mediaType
+ (HQTrack *)trackWithTracks:(NSArray <HQTrack *>*)tracks type:(HQMediaType)type;


/// get track with tracks with index

+ (HQTrack *)trackWithTracks:(NSArray <HQTrack *>*)tracks index:(NSInteger)index;


/// get tracks with tracks with index
+ (NSArray <HQTrack *>*)tracksWithTracks:(NSArray <HQTrack *>*)tracks type:(HQMediaType)type;

@end

