//
//  HQPacketOutput.m
//  FFM_Mac
//
//  Created by 黄麒展. on 2020/5/18.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPacketOutput.h"
#import "HQDemuxable.h"
#import "HQAsset+Interal.h"
#import "HQOptions.h"
#import "HQError.h"
#import "HQMacro.h"
#import "HQLock.h"

@interface HQPacketOutput ()<HQDemuxerableDelegate>{
    struct {
        NSError *error;
        HQPacketOutputState state;
    }_flags;
    
    struct {
        CMTime seekTime;
        CMTime seekToleranceBefore;
        CMTime seekToleranceAfter;
        HQSeekResult seekResult;
    }_seekFlags;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) NSCondition *weakup;
/// 解封装器
@property (nonatomic, strong, readonly) id<HQDemuxable> demuxable;
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

@end


@implementation HQPacketOutput

- (instancetype)initWithAsset:(HQAsset *)asset{
    self = [super init];
    if (self) {
        self->_lock = [[NSLock alloc] init];
        self->_weakup = [[NSCondition alloc] init];
        self->_demuxable = [asset newDemuxer];
        self->_demuxable.delegate = self;
        self->_demuxable.options = [HQOptions shareOptions].demuxer.copy;
    }
    return self;
}
- (void)dealloc{
    HQLockCondEXE00(self->_lock, ^BOOL{
        return self->_flags.state != HQPacketOutputStateClosed;
    }, ^{
        [self setState:HQPacketOutputStateClosed];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
    });
}
#pragma mark mapper
HQGetoMap(CMTime, duration, self->_demuxable)
HQGetoMap(NSDictionary *, metadata, self->_demuxable)
HQGetoMap(NSArray<HQTrack *> *, tracks, self->_demuxable)
HQGetoMap(NSArray<HQTrack *> *, finishedTracks, self->_demuxable)
HQGetoMap(HQDemuxerOptions *, options, self->_demuxable)
HQSet1Map(void, setOptions, HQDemuxerOptions *, self->_demuxable)

- (HQBlock)setState:(HQPacketOutputState)state{
    if (state == self->_flags.state) {
        return ^{};
    }
    self->_flags.state = state;
    [self->_weakup lock];
    /// 由weakup 控制的其他所有线程开始运行
    [self->_weakup broadcast];
    [self->_weakup unlock];
    return ^{
        [self->_delegate packetOutput:self didChangeState:state];
    };
}
- (HQPacketOutputState)state{
    __block HQPacketOutputState state = HQPacketOutputStateNone;
    HQLockEXE00(self->_lock, ^{
        state = self->_flags.state;
    });
    return state;
}
- (NSError *)error{
    __block NSError *error = nil;
    HQLockEXE00(self->_lock, ^{
        error = [self->_flags.error copy];
    });
    return error;
}

#pragma mark Interface
- (BOOL)open{
    return HQLockCondEXE11(self->_lock, ^BOOL{
        return self->_flags.state == HQPacketOutputStateNone;
    }, ^HQBlock{
        return [self setState:HQPacketOutputStateOpening];
    }, ^BOOL(HQBlock block) {
        NSOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(threadOperation) object:nil];
        self->_operationQueue = [[NSOperationQueue alloc] init];
        self->_operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        [self->_operationQueue addOperation:operation];
        return YES;
    });
}
- (BOOL)close{
    return HQLockCondEXE11(self->_lock, ^BOOL{
        return self->_flags.state != HQPacketOutputStateNone;
    }, ^HQBlock{
        return [self setState:HQPacketOutputStateClosed];
    }, ^BOOL(HQBlock block) {
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return YES;
    });
}
- (BOOL)pause{
    return HQLockCondEXE10(self->_lock, ^BOOL{
        return (self->_flags.state == HQPacketOutputStateReading || self->_flags.state == HQPacketOutputStateSeeking);
    }, ^HQBlock{
        return [self setState:HQPacketOutputStatePaused];
    });
}
- (BOOL)resume{
    return HQLockCondEXE10(self->_lock, ^BOOL{
        return (self->_flags.state == HQPacketOutputStatePaused || self->_flags.state == HQPacketOutputStateOpened);
    }, ^HQBlock{
        return [self setState:HQPacketOutputStateReading];
    });
}
- (BOOL)seekable{
    return self->_demuxable.seekable == nil;
}
- (BOOL)seekToTime:(CMTime)time{
   return [self seekToTime:time result:nil];
}
- (BOOL)seekToTime:(CMTime)time result:(HQSeekResult)result{
    return [self seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero result:result];
}
- (BOOL)seekToTime:(CMTime)time toleranceBefore:(CMTime)toleranceBefore toleranceAfter:(CMTime)toleranceAfter result:(HQSeekResult)result{
    if (!self.seekable) {
        return NO;
    }
    return HQLockCondEXE10(self->_lock, ^BOOL{
        return self->_flags.state == HQPacketOutputStateReading ||
        self->_flags.state == HQPacketOutputStateSeeking ||
        self->_flags.state == HQPacketOutputStateOpened ||
        self->_flags.state == HQPacketOutputStateFinished ||
        self->_flags.state == HQPacketOutputStatePaused;
    }, ^HQBlock{
        HQBlock b1 = ^{}, b2 = ^{};
        if (self->_seekFlags.seekResult) {
            CMTime lastSeekTime = self->_seekFlags.seekTime;
            HQSeekResult seekresult = self->_seekFlags.seekResult;
            b2 = ^{
                seekresult(lastSeekTime,HQCreateError(HQErrorCodePacketOutputCancelSeek, HQActionCodePacketOutputSeek));
            };
        }
        self->_seekFlags.seekTime = time;
        self->_seekFlags.seekToleranceBefore = toleranceBefore;
        self->_seekFlags.seekToleranceAfter = toleranceAfter;
        self->_seekFlags.seekResult = [result copy];
        b2 = [self setState:HQPacketOutputStateSeeking];
        return ^{b1();b2();};
    });
}
#pragma mark --- Thread operation for get packet
- (void)threadOperation{
    while (YES) {
        @autoreleasepool {
            [self->_lock lock];
            if (self->_flags.state == HQPacketOutputStateNone || self->_flags.state == HQPacketOutputStateClosed || self->_flags.state == HQPacketOutputStateFailed) {
                [self->_lock unlock];
                /// 退出
                break;
            }else if (self->_flags.state == HQPacketOutputStateOpening){
                [self->_lock unlock];
                NSError *error = [self->_demuxable open];
                [self->_lock lock];
                if (self->_flags.state != HQPacketOutputStateOpening) {
                    [self->_lock unlock];
                    continue;
                }
                self->_flags.error = error;
                HQBlock b = [self setState:error ? HQPacketOutputStateFailed : HQPacketOutputStateOpened];
                [self->_lock unlock];
                b();
                continue;
            }else if (self->_flags.state == HQPacketOutputStateOpened || self->_flags.state == HQPacketOutputStatePaused || self->_flags.state == HQPacketOutputStateFinished){
                [self->_lock unlock];
                [self->_weakup lock];
                /// 当前线程等待
                [self->_weakup wait];
                [self->_weakup unlock];
                continue;
            }else if (self->_flags.state == HQPacketOutputStateSeeking){
                CMTime seekingtime = self->_seekFlags.seekTime;
                CMTime seekingToleranceBefore = self->_seekFlags.seekToleranceBefore;
                CMTime seekingToleranceAfter  = self->_seekFlags.seekToleranceAfter;
                [self->_lock unlock];
                NSError *error = [self->_demuxable seekToTime:seekingtime toleranceBefor:seekingToleranceBefore toleranceAfter:seekingToleranceAfter];
                [self->_lock lock];
                if (self->_flags.state == HQPacketOutputStateSeeking && CMTimeCompare(self->_seekFlags.seekTime, seekingtime) != 0) {
                    [self->_lock unlock];
                    continue;
                }
                HQBlock b1 = ^{}, b2 = ^{};
                if (self->_seekFlags.seekResult) {
                    CMTime seekTime = self->_seekFlags.seekTime;
                    HQSeekResult seekresult = self->_seekFlags.seekResult;
                    b1 = ^{
                        seekresult(seekTime,error);
                    };
                }
                if (self->_flags.state == HQPacketOutputStateSeeking) {
                    b2 = [self setState:HQPacketOutputStateReading];
                }
                self->_seekFlags.seekTime = kCMTimeZero;
                self->_seekFlags.seekToleranceBefore = kCMTimeZero;
                self->_seekFlags.seekToleranceAfter = kCMTimeZero;
                self->_seekFlags.seekResult = nil;
                [self->_lock unlock];
                b1();b2();
                continue;
            }else if (self->_flags.state == HQPacketOutputStateReading){
                /// 读取下一个packet
                [self->_lock unlock];
                HQPacket *packet = nil;
                NSError *error = [self->_demuxable nextPacket:&packet];
//                NSLog(@"reading packet = ");
                if (error) {
                    HQLockCondEXE00(self->_lock, ^BOOL{
                        return self->_flags.state == HQPacketOutputStateReading;
                    }, ^{
                        [self setState:HQPacketOutputStateFinished];
                    });
                }else{
                    [self->_delegate packetOutput:self didOutputPacket:packet];
                    [packet unlock];
                }
                continue;
            }
        }
    }
    [self->_demuxable close];
}
#pragma mark -- HQDemuxerableDelegate
- (BOOL)demuxableShouldAbortBlockingFunctions:(id<HQDemuxable>)demuxable{
    return HQLockCondEXE00(self->_lock, ^BOOL{
        switch (self->_flags.state) {
            case HQPacketOutputStateFinished:
            case HQPacketOutputStateFailed:
            case HQPacketOutputStateClosed:
                return YES;
                break;
                
            default:
                 return NO;
                break;
        }
    }, nil);
}
@end
