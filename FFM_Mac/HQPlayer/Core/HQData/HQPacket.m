//
//  HQPacket.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/3.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPacket.h"
#import "HQPacket+Internal.h"
#import "HQObjectPool.h"

@interface HQPacket (){
    NSLock *_lock;
    uint64_t _lockingCount;
}
@end

@implementation HQPacket

@synthesize flags = _flags;
@synthesize reuseName = _reuseName;


+ (instancetype)packet{
    NSString *resueName = @"HQPacket";
    return [[HQObjectPool sharedPool] objectWithClass:[self class] reuseName:resueName];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self->_core = av_packet_alloc();
        self->_lock = [[NSLock alloc] init];
        self->_coreptr = self->_core;
        [self clear];
    }
    return self;
}
- (void)dealloc{
    NSAssert(self->_lockingCount == 0, @"invalid locking count");
    [self clear];
    if (self->_core) {
        av_packet_free(&self->_core);
        self->_core = NULL;
    }
}
- (NSString *)description{
    return [NSString stringWithFormat:@"<%@: %p>, track: %d, pts: %f, end: %f, duration: %f",
            NSStringFromClass(self.class), self,
            (int)self->_codecDescriptor.track.index,
            CMTimeGetSeconds(self->_timeStamp),
            CMTimeGetSeconds(CMTimeAdd(self->_timeStamp, self->_duration)),
            CMTimeGetSeconds(self->_duration)];
}
#pragma mark --- HQData
- (void)lock{
    [self->_lock lock];
    self->_lockingCount += 1;
    [self->_lock unlock];
}
- (void)unlock{
//    NSAssert(self->_lockingCount > 0, @"invalid locking count");
    [self->_lock lock];
    self->_lockingCount -= 1;
    BOOL iszero = self->_lockingCount == 0;
    [self->_lock unlock];
    if (iszero) {
        [[HQObjectPool sharedPool] comeBack:self];
    }
}
- (void)clear{
    if (self->_core) {
        av_packet_unref(self->_core);
    }
    self->_size = 0;
    self->_flags = 0;
    self->_track = nil;
    self->_duration = kCMTimeInvalid;
    self->_timeStamp = kCMTimeInvalid;
    self->_decodetimeStamp = kCMTimeInvalid;
    self->_codecDescriptor = nil;
}
- (void)fill{
    AVPacket *pkt = self->_core;
    AVRational rational = self->_codecDescriptor.timebase;
    HQCodecDescriptor *cd = self->_codecDescriptor;
    if (pkt->pts == AV_NOPTS_VALUE) {
        pkt->pts = pkt->dts;
    }
    self->_size = pkt->size;
    self->_track = cd.track;
    self->_metadata = cd.metadata;
    CMTime duration = CMTimeMake(pkt->duration * rational.num, rational.den);
    CMTime timeStamp= CMTimeMake(pkt->pts * rational.num, rational.den);
    CMTime decodeTimrStamp = CMTimeMake(pkt->dts * rational.num, rational.den);
    self->_duration = [cd convertDuration:duration];
    self->_timeStamp = [cd convertTimeStamp:timeStamp];
    self->_decodetimeStamp = [cd convertTimeStamp:decodeTimrStamp];
}

@end

