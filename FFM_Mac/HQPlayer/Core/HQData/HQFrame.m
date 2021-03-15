//
//  HQFrame.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/13.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQFrame.h"
#import "HQFrame+Interal.h"
#import "HQObjectPool.h"

@interface HQFrame (){
    NSLock *_lock;
    NSUInteger lockingCount;
}

@end

@implementation HQFrame

@synthesize flags = _flags;
@synthesize reuseName = _reuseName;

+ (instancetype) frame{
    NSAssert(NO, @"user subclass");
    return nil;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self->_core = av_frame_alloc();
        self->_coreptr = self->_core;
        self->_lock = [[NSLock alloc] init];
        [self clear];
    }
    return self;
}

- (void)dealloc{
    NSAssert(self->lockingCount == 0, @"invalid lockingcount");
    [self clear];
    if (self->_core) {
        av_frame_free(&self->_core);
        self->_core = nil;
    }
}
- (NSString *)description{
    return [NSString stringWithFormat:@"<%@: %p>, track: %d, pts: %f, end: %f, duration: %f",
            NSStringFromClass(self.class), self,
            (int)self->_track.index,
            CMTimeGetSeconds(self->_timeStamp),
            CMTimeGetSeconds(CMTimeAdd(self->_timeStamp, self->_duration)),
            CMTimeGetSeconds(self->_duration)];
}

#pragma mark ---- setter getter
- (HQMediaType )type{
    return HQMediaTypeUnknown;
}

#pragma mark ---- HQData
- (void)lock{
    [self->_lock lock];
    self->lockingCount += 1;
    [self->_lock unlock];
}
- (void)unlock{
    NSAssert(self->lockingCount > 0, @"invalid locking count");
    [self->_lock lock];
    self->lockingCount -= 1;
    BOOL iscomback = self->lockingCount == 0;
    [self->_lock unlock];
    if (iscomback) {
        [[HQObjectPool sharedPool] comeBack:self];
    }
}
- (void)clear{
    if (self->_core) {
        av_frame_unref(self->_core);
    }
    self->_size = 0;
    self->_flags = 0;
    self->_track = nil;
    self->_timeStamp = kCMTimeInvalid;
    self->_decodeTimeStamp = kCMTimeInvalid;
    self->_duration = kCMTimeInvalid;
    self->_codeDescriptor = nil;
}
- (void)fill{
    AVFrame *frame = self->_core;
    AVRational rational = self->_codeDescriptor.timebase;
    HQCodecDescriptor *cd = self->_codeDescriptor;
    self->_size = frame->pkt_size;
    self->_track = cd.track;
    self->_metadata = cd.metadata;
    CMTime duration = CMTimeMake(frame->pkt_duration * rational.num, rational.den);
    CMTime timeStamp = CMTimeMake(frame->best_effort_timestamp * rational.num, rational.den);
    CMTime decodeTimeStamp = CMTimeMake(frame->pkt_dts *rational.num, rational.den);
    self->_duration = duration;
    self->_timeStamp = timeStamp;
    self->_decodeTimeStamp = decodeTimeStamp;
}
- (void)fillWithFrame:(HQFrame *)frame{
    // 添加引用计数
    av_frame_ref(self->_core, frame->_core);
    self->_size = frame->_size;
    self->_track = frame->_track;
    self->_metadata = frame->_metadata;
    self->_duration = frame->_duration;
    self->_timeStamp = frame->_timeStamp;
    self->_decodeTimeStamp = frame->_decodeTimeStamp;
    self->_codeDescriptor = frame->_codeDescriptor.copy;
}
- (void)fillWithTimeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp duration:(CMTime)duration{
    AVFrame *frame = self->_core;
    HQCodecDescriptor *cd = self->_codeDescriptor;
    self->_size = frame->pkt_size;
    self->_track = cd.track;
    self->_metadata = cd.metadata;
    self->_duration = duration;
    self->_timeStamp = timeStamp;
    self->_decodeTimeStamp = decodeTimeStamp;
}

@end

