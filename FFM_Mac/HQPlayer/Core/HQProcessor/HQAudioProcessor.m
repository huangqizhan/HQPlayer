//
//  HQAudioProcessor.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAudioProcessor.h"
#import "HQAudioMixer.h"
#import "HQTrackSelection.h"

@interface HQAudioProcessor ()

@property (nonatomic) HQAudioMixer *mixer;
@property (nonatomic) HQTrackSelection *selection;

@end

@implementation HQAudioProcessor

- (void)setSelection:(HQTrackSelection *)selection action:(HQTrackSelectionAction)action{
    self->_selection = [selection copy];
    if (action & HQTrackSelectionActionTracks) {
        self->_mixer = [[HQAudioMixer alloc] initWith:selection.tracks weights:selection.weights];
    }else if (action & HQTrackSelectionActionWeights){
        self->_mixer.weights = selection.weights;
    }
}

- (__kindof HQFrame *)putFrame:(__kindof HQFrame *)frame{
    if (![frame isKindOfClass:[HQAudioFrame class]] || ![self->_mixer.tracks containsObject:frame.track]) {
        [frame unlock];
        return nil;
    }
    return [self->_mixer putFrame:frame];
}

- (__kindof HQFrame *)finish{
    return [self->_mixer finish];
}

- (HQCapacity)capatity{
    return [self->_mixer capatity];
}
- (void)flush{
    [self->_mixer flush];
}
- (void)close{
    self->_mixer = nil;
}
@end
