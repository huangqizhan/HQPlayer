//
//  HQVideoProcessor.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQVideoProcessor.h"
#import "HQTrackSelection.h"
#import "HQVideoFrame.h"

@interface HQVideoProcessor ()

@property (nonatomic) HQTrackSelection *selection;

@end

@implementation HQVideoProcessor

- (void)setSelection:(HQTrackSelection *)selection action:(HQTrackSelectionAction)action{
    self->_selection = selection.copy;
}

- (__kindof HQFrame *)putFrame:(__kindof HQFrame *)frame{
    
    if (![frame isKindOfClass:[HQVideoFrame  class]] || ![self->_selection.tracks containsObject:frame.track]) {
        [frame unlock];
        return nil;
    }
    return frame;
}

- (__kindof HQFrame *)finish{
    return nil;
}
- (HQCapacity)capatity{
    return HQCapacityCreate();
}
- (void)flush{}
- (void)close{}


@end

