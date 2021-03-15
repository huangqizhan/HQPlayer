//
//  HQMutableTrack.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMutableTrack.h"
#import "HQFFmpeg.h"
#import "HQTrack+Interal.h"

@interface HQMutableTrack (){
    NSMutableArray <HQSegment *> *_segments;
}

@end

@implementation HQMutableTrack
- (id)copyWithZone:(NSZone *)zone{
    HQMutableTrack *one = [super copyWithZone:zone];
    one->_segments = self->_segments.copy;
    one->_subTracks = self->_subTracks.copy;
    return one;
}

- (instancetype)initWithType:(HQMediaType)type index:(NSInteger)index{
    self = [super initWithType:type index:index];
    if (self) {
        self->_segments = [NSMutableArray new];
    }
    return self;
}

- (void *)coreptr{
    return self.core;
}
- (AVStream *)core{
    void *ret = self.core;
    if (ret) {
        return ret;
    }
    for (HQTrack *obj in self->_subTracks) {
        if (obj.core) {
            ret = obj.core;
            break;
        }
    }
    return nil;
}

- (BOOL)appendSegment:(HQSegment *)segment{
    [self->_segments addObject:segment];
    return YES;
}
@end
