//
//  HQTrack.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQTrack.h"
#import "HQTrack+Interal.h"

@implementation HQTrack

- (instancetype)copyWithZone:(NSZone *)zone{
    HQTrack *one = [[HQTrack alloc] init];
    one->_index = self->_index;
    one->_core = self->_core;
    one->_type = self->_type;
    return one;
}
- (instancetype)initWithType:(HQMediaType)type index:(NSInteger)index{
    self = [super init];
    if (self) {
        self->_index = index;
        self->_type = type;
    }
    return self;
}
- (void *)coreptr{
    return self->_core;
}
/// get track with tracks with m
/// ediaType
+ (HQTrack *)trackWithTracks:(NSArray <HQTrack *>*)tracks type:(HQMediaType)type{
    for (HQTrack *track in tracks) {
        if (track.type == type) {
            return track;
        }
    }
    return nil;
}

/// get track with tracks with index

+ (HQTrack *)trackWithTracks:(NSArray <HQTrack *>*)tracks index:(NSInteger)index{
    for (HQTrack *track in tracks) {
        if (track.index == index) {
            return track;
        }
    }
    return nil;
}

/// get tracks with tracks with index
+ (NSArray <HQTrack *>*)tracksWithTracks:(NSArray <HQTrack *>*)tracks type:(HQMediaType)type{
    NSMutableArray *array = [NSMutableArray array];
     for (HQTrack *obj in tracks) {
         if (obj.type == type) {
             [array addObject:obj];
         }
     }
     return array.count ? [array copy] : nil;
}

@end
