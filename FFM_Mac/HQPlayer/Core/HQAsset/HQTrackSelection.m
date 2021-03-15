//
//  HQTrackSelection.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQTrackSelection.h"

@implementation HQTrackSelection

- (id)copyWithZone:(NSZone *)zone{
    HQTrackSelection *one = [[HQTrackSelection alloc] init];
    one->_tracks = self->_tracks.copy;
    one->_weights = self->_weights.copy;
    return one;
}

@end
