//
//  HQDecodeLoop.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQDecodeLoop.h"
#import "HQDecodeContext.h"
#import "HQLock.h"
#import "HQPacket+Internal.h"

@interface HQDecodeLoop (){
    struct {
        HQDecodeLoopState  state;
    } _flags;
    HQCapacity _capacity;
}

@property (nonatomic, copy) Class decoderClass;
@property (nonatomic, strong ) NSLock *lock;
@property (nonatomic, strong) NSCondition *weakup;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, HQDecodeContext *> *contexts;

@end

@implementation HQDecodeLoop

- (instancetype)initWithDecoderClass:(Class)decoderClass{
    self = [super init];
    self->_decoderClass = decoderClass;
    self->_lock = [[NSLock alloc] init];
    self->_weakup = [[NSCondition alloc] init];
    self->_contexts = [[NSMutableDictionary alloc] init];
    self->_capacity = HQCapacityCreate();
    self->_operationQueue = [[NSOperationQueue alloc] init];
    self->_operationQueue.maxConcurrentOperationCount = 1;
    self->_operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    return self;
}

- (void)dealloc{
    HQLockCondEXE10(self->_lock, ^BOOL{
        return self->_flags.state != HQDecodeLoopStateClosed;
    }, ^HQBlock{
        [self setState:HQDecodeLoopStateClosed];
        [self->_contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, HQDecodeContext * _Nonnull obj, BOOL * _Nonnull stop) {
            [obj destory];
        }];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return nil;
    });
}

- (HQBlock)setState:(HQDecodeLoopState)state{
    if (self->_flags.state == state) {
        return ^{};
    }
    HQDecodeLoopState previousState = self->_flags.state;
    self->_flags.state = state;
    if (previousState == HQDecodeLoopStateStalled || previousState == HQDecodeLoopStatePaused) {
        [self->_weakup lock];
        [self->_weakup broadcast];
        [self->_weakup unlock];
    }
    return ^{
        [self->_delegate decodeLoop:self didChangeState:state];
    };
}

- (HQDecodeLoopState)state{
    __block HQDecodeLoopState state = HQDecodeLoopStateNone;
    HQLockEXE00(self->_lock, ^{
        state = self->_flags.state;
    });
    return state;
}
- (HQBlock)setCapacityIfNeed{
    
    __block HQCapacity capatity = HQCapacityCreate();
    [self.contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, HQDecodeContext * _Nonnull obj, BOOL * _Nonnull stop) {
        capatity = HQCapacityMaximum(capatity, obj.capacity);
    }];
    if (HQCapacityIsEqual(capatity, self->_capacity)) {
        return ^{};
    }
    self->_capacity = capatity;
    return ^{
        [self->_delegate decodeLoop:self didChangeCapacity:capatity];
    };
}

#pragma mark ---- process
- (HQDecodeContext *)contextWithKey:(NSNumber *)key{
    HQDecodeContext *context = self->_contexts[key];
    if (!context) {
        context = [[HQDecodeContext alloc] initWithDecoderClass:self->_decoderClass];
        context.options = self->_options;
        self->_contexts[key] = context;
    }
    return context;
}
- (HQDecodeContext *)currentDecodeContext{
    HQDecodeContext *context = nil;
    CMTime minTime = kCMTimePositiveInfinity;
    for (NSNumber *key in self->_contexts) {
        HQDecodeContext *obj = self->_contexts[key];
        if (obj.capacity.count == 0) {
            continue;
        }
        CMTime dts = obj.decodeTimeStamp;
        if (!CMTIME_IS_NUMERIC(dts)) {
            context = obj;
            break;
        }
        if (CMTimeCompare(dts, minTime) < 0) {
            minTime = dts;
            context = obj;
            continue;
        }
    }
    return context;
}
- (HQDecodeContext *)currentPreDecodeContext{
    HQDecodeContext *context = nil;
    for (NSNumber *key in self->_contexts) {
        HQDecodeContext *obj = self->_contexts[key];
        if ([obj needPreDecode]) {
            context = obj;
            break;
        }
    }
    return context;
}

#pragma mark --- Interface
- (BOOL)open {
    return HQLockCondEXE11(self->_lock, ^BOOL{
        return self->_flags.state == HQDecodeLoopStateNone;
    }, ^HQBlock{
        return [self setState:HQDecodeLoopStateDecoding];
    }, ^BOOL(HQBlock block) {
        block();
        NSOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(runingThread) object:nil];
        self->_operationQueue = [[NSOperationQueue alloc] init];
        self->_operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        [self->_operationQueue addOperation:operation];
        return YES;
    });
}
- (BOOL)close{
   return HQLockCondEXE11(self->_lock, ^BOOL{
        return self->_flags.state != HQDecodeLoopStateNone && self->_flags.state != HQDecodeLoopStateClosed;
    }, ^HQBlock{
        return [self setState:HQDecodeLoopStateClosed];
    }, ^BOOL(HQBlock block) {
        block();
        [self->_contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, HQDecodeContext * _Nonnull obj, BOOL * _Nonnull stop) {
            [obj destory];
        }];
        [self->_operationQueue cancelAllOperations];
        [self->_operationQueue waitUntilAllOperationsAreFinished];
        return YES;
    });
}
- (BOOL)pause{
    return HQLockCondEXE10(self->_lock, ^BOOL{
        return self->_flags.state == HQDecodeLoopStateDecoding;
    }, ^HQBlock{
        return [self setState:HQDecodeLoopStatePaused];
    });
}
- (BOOL)resume{
    return HQLockCondEXE10(self->_lock, ^BOOL{
        return self->_flags.state == HQDecodeLoopStatePaused;
    }, ^HQBlock{
        return [self setState:HQDecodeLoopStateDecoding];
    });
}

- (BOOL)flush{
    return HQLockCondEXE10(self->_lock, ^BOOL{
        return self->_flags.state != HQDecodeLoopStateNone && self->_flags.state != HQDecodeLoopStateClosed;
    }, ^HQBlock{
        [self->_contexts enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, HQDecodeContext * _Nonnull obj, BOOL * _Nonnull stop) {
            [obj setNeedsFlush];
        }];
        HQBlock b1 = ^{};
        HQBlock b2 = [self setCapacityIfNeed];
        if (self->_flags.state == HQDecodeLoopStateStalled) {
            b1 = [self setState:HQDecodeLoopStateDecoding];
        }
        return ^{
            b1();
            b2();
        };
    });
}

- (BOOL)finish:(NSArray<HQTrack *> *)tracks{
    return HQLockCondEXE10(self->_lock, ^BOOL{
        return self->_flags.state != HQDecodeLoopStateNone && self->_flags.state != HQDecodeLoopStateClosed;
    }, ^HQBlock{
        for (HQTrack *track in tracks) {
            HQDecodeContext *obj = [self contextWithKey:@(track.index)];
            [obj markAsFinshed];
        }
        HQBlock b1 = ^{};
        HQBlock b2 = [self setCapacityIfNeed];
        if (self->_flags.state == HQDecodeLoopStateStalled) {
            b1 = [self setState:HQDecodeLoopStateDecoding];
        }
        return ^{
            b1();
            b2();
        };
    });
}
- (BOOL)putPacket:(HQPacket *)packet{
    return HQLockCondEXE10(self->_lock, ^BOOL{
        return self->_flags.state != HQDecodeLoopStateNone && self->_flags.state != HQDecodeLoopStateClosed;
    }, ^HQBlock {
        HQDecodeContext *context = [self contextWithKey:@(packet.track.index)];
        [context putPacket:packet];
        HQBlock b1 = ^{};
        HQBlock b2 = [self setCapacityIfNeed];
        if (self->_flags.state == HQDecodeLoopStateDecoding  && [context needPreDecode]) {
            /// 如果暂停  开始解码
            [self->_weakup lock];
            [self->_weakup broadcast];
            [self->_weakup unlock];
        }else if (self->_flags.state == HQDecodeLoopStateStalled){
            b1 = [self setState:HQDecodeLoopStateDecoding];
        }
        return ^{
            b1();
            b2();
        };
    });
}
/// 解码 loop
- (void)runingThread{
    HQBlock lock = ^{
        [self->_lock lock];
    };
    HQBlock unlock = ^{
        [self->_lock unlock];
    };
    while (YES) {
        @autoreleasepool {
            [self->_lock lock];
            if (self->_flags.state == HQDecodeLoopStateNone || self->_flags.state == HQDecodeLoopStateClosed) {
                [self->_lock unlock];
                break;
            }else if (self->_flags.state == HQDecodeLoopStateStalled){
                [self->_weakup lock];
                [self->_lock unlock];
                [self->_weakup wait];
                [self->_weakup unlock];
                continue;
            }else if (self->_flags.state == HQDecodeLoopStatePaused){
                HQDecodeContext *context = [self currentPreDecodeContext];
                if (!context) {
                    [self->_weakup lock];
                    [self->_lock unlock];
                    [self->_weakup wait];
                    [self->_weakup unlock];
                    continue;
                }
//                [context preDecode:lock unlock:unlock];
                [self->_lock unlock];
                continue;
            }else if (self->_flags.state == HQDecodeLoopStateDecoding){
                HQDecodeContext *context = [self currentDecodeContext];
                if (!context) {
                    self->_flags.state = HQDecodeLoopStateStalled;
                    [self->_lock unlock];
                    continue;
                }
                NSArray <__kindof HQFrame *> *array = [context decode:lock unlock:unlock];
                [self->_lock unlock];
                
                [self->_delegate decodeLoop:self didOutputFrames:array needsDrop:nil];
                for (HQFrame *frame in array) {
                    [frame unlock];
                }
                [self->_lock lock];
                HQBlock b1 = [self setCapacityIfNeed];
                [self->_lock unlock];
                b1();
                continue;
            }
        }
    }
}
@end
