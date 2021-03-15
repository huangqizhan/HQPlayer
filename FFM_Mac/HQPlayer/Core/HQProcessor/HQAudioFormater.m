//
//  HQAudioFormater.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAudioFormater.h"
#import "HQTrack.h"
#import "HQFrame+Interal.h"
#import "HQSWRESample.h"

@interface HQAudioFormater ()
///音频流
@property (nonatomic,readonly) HQTrack *track;
/// 重新采样
@property (nonatomic,readonly) HQSWRESample *resampleContext;
/// 下一个pts
@property (nonatomic,readonly) CMTime nextTimeStamp;

@end

@implementation HQAudioFormater

- (instancetype)init{
    self = [super init];
    if (self) {
        [self flush];
    }
    return self;
}

- (HQAudioFrame *)format:(HQAudioFrame *)frame{
    if (![frame isKindOfClass:[HQAudioFrame class]]) {
        return nil;
    }
    if (![self->_resampleContext.inputDescriptor isEqualToDescriptor:frame.descriptor] || ![self->_resampleContext.outputDescriptor isEqualToDescriptor:self->_descriptor]) {
        [self flush];
        HQSWRESample *resamCtx = [[HQSWRESample alloc] init];
        resamCtx.inputDescriptor = frame.descriptor;
        resamCtx.outputDescriptor = self->_descriptor;
        if ([resamCtx open]) {
            self->_resampleContext = resamCtx;
        }
    }
    
    if (!self->_resampleContext) {
        [frame unlock];
        return nil;
    }
    self->_track = frame.track;
    int nb_samples = [self->_resampleContext write:frame.data nb_samples:frame.numberOfSamples];
    HQAudioFrame *aframe = [self frameWith:frame.timeStamp nbSamples:nb_samples];
    self->_nextTimeStamp = CMTimeAdd(aframe.timeStamp, aframe.duration);
    [frame unlock];
    return aframe;
}
- (HQAudioFrame *)finish{
    if (!self->_track || !self->_resampleContext || CMTIME_IS_INVALID(self->_nextTimeStamp)) {
        return nil;
    }
    int nb_samples = [self->_resampleContext write:NULL nb_samples:0];
    if (nb_samples <= 0) {
        return nil;
    }
    HQAudioFrame *frame = [self frameWith:self->_nextTimeStamp nbSamples:nb_samples];
    return frame;
}

- (HQAudioFrame *)frameWith:(CMTime)start nbSamples:(int)nb_samples{
    HQAudioFrame *frame = [HQAudioFrame frameWithDescriptor:self->_descriptor numberofSamples:nb_samples];
    uint8_t nb_planes = self->_descriptor.numberOfPlanes;
    uint8_t *data[HQFramePlaneCount] = {NULL};
    for (int i = 0; i < nb_planes; i++) {
        data[i] = frame.data[i];
    }
    [self->_resampleContext read:data nb_samples:nb_samples];
    HQCodecDescriptor *cd  =[[HQCodecDescriptor alloc] init];
    cd.track = self->_track;
    [frame setCodeDescriptor:cd];
    [frame fillWithTimeStamp:start decodeTimeStamp:start duration:CMTimeMake(nb_samples, self->_descriptor.sampleRate)];
    return frame;
}
- (void)flush{
    self->_track = nil;
    self->_nextTimeStamp = kCMTimeInvalid;
    self->_resampleContext = nil;
}
@end
