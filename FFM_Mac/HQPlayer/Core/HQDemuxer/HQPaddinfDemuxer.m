//
//  HQPaddinfDemuxer.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPaddinfDemuxer.h"
#import "HQSegment+Inteal.h"
#import "HQError.h"
#import "HQPacket+Internal.h"

@interface HQPaddinfDemuxer ()

@property (nonatomic,readonly) CMTime lasttime;

@end


/// 片头片尾 demuxer
@implementation HQPaddinfDemuxer

@synthesize tracks = _tracks;
@synthesize delegate = _delegate;
@synthesize duration = _duration;
@synthesize finishedTracks = _finishedTracks;
@synthesize options = _options;
@synthesize metadata = _metadata;

- (instancetype)initWithDuration:(CMTime)duration{
    self = [super init];
    if (self) {
        self->_duration = duration;
        [self seekToTime:kCMTimeZero];
    }
    return self;
}

- (id<HQDemuxable>)shareDemuxer{
    return nil;
}

- (NSError *)open{
    return nil;
}
- (NSError *)close{
    return nil;
}
- (NSError *)seekable{
    return nil;
}
- (NSError *)seekToTime:(CMTime)time{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}
- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter{
    if (!CMTIME_IS_NUMERIC(time)) {
        return HQCreateError(HQErrorCodePacketOutputCancelSeek, HQActionCodeFormatSeekFrame);
    }
    time = CMTimeMaximum(time, kCMTimeZero);
    time = CMTimeMinimum(time, self->_duration);
    self->_lasttime = time;
    return nil;
}

- (NSError *)nextPacket:(HQPacket *__autoreleasing *)packet{
    if (CMTimeCompare(self->_lasttime, self->_duration) >= 0) {
        return HQCreateError(HQActionCodeNextFrame, HQActionCodeFormatReadFrame);
    }
    CMTime timeStamp = self->_lasttime;
    CMTime duration = CMTimeSubtract(self->_duration, self->_lasttime);
    HQPacket *pkt = [HQPacket packet];
    pkt.flags |= HQDataFlagPadding;
    pkt.core->size = 1;
    pkt.core->pts = av_rescale(AV_TIME_BASE, timeStamp.value, timeStamp.timescale);
    pkt.core->dts = av_rescale(AV_TIME_BASE, timeStamp.value, timeStamp.timescale);
    pkt.core->duration = av_rescale(AV_TIME_BASE, duration.value, duration.timescale);
    HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
    cd.timebase = AV_TIME_BASE_Q;
    [pkt setCodecDescriptor:cd];
    [pkt fill];
    self->_lasttime = self->_duration;
    *packet = pkt;
    return nil;
}

@end

