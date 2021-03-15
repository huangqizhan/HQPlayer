//
//  HQPlayer.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "HQPlayerItem+Internal.h"
#import "HQRender+Interal.h"
#import "HQActivity.h"
#import "HQMacro.h"
#import "HQClock+Interal.h"

#if HQCPLATFORM_TARGET_OS_IPHONE_OR_TV

#import <UIKit/UIKit.h>

#endif

NSString *const  HQPlayerDidChangeInfosNotification = @"HQPlayerDidChangeInfosNotification";
NSString *const HQPlayerTimeinfoUserInfoKey = @"HQPlayerTimeinfoUserInfoKey";
NSString *const HQPlayerStateInfoUserInfoKey = @"HQPlayerStateInfoUserInfoKey";
NSString *const HQPlayerInfoActionUserInfoKey = @"HQPlayerInfoActionUserInfoKey";


@interface HQPlayer () <HQClockDelegate, HQRenderableDelegate, HQPlayerItemDelegate>

{
    struct {
        BOOL playing;
        BOOL audioFinished;
        BOOL videoFinished;
        BOOL audioAvailable;
        BOOL videoAvailable;
        NSError *error;
        NSUInteger seekingIndex;
        HQTimeInfo timeInfo;
        HQStateInfo stateInfo;
        HQInfoAction additionalAction;
        NSTimeInterval lastNotificationTime;
    } _flags;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) HQClock *clock;
@property (nonatomic, strong, readonly) HQPlayerItem *currentItem;
@property (nonatomic, strong, readonly) HQAudioRender *audioRenderer;
@property (nonatomic, strong, readonly) HQVideoRender *videoRenderer;

@end

@implementation HQPlayer

@synthesize rate = _rate;
@synthesize clock = _clock;
@synthesize currentItem = _currentItem;
@synthesize audioRenderer = _audioRenderer;
@synthesize videoRenderer = _videoRenderer;

- (instancetype)init
{
    if (self = [super init]) {
        [self stop];
        self->_options = [HQOptions shareOptions].copy;
        self->_rate = 1.0;
        self->_lock = [[NSLock alloc] init];
        self->_clock = [[HQClock alloc] init];
        self->_clock.delegate = self;
        self->_audioRenderer = [[HQAudioRender alloc] initWithClock:self->_clock];
        self->_audioRenderer.delegate = self;
        self->_videoRenderer = [[HQVideoRender alloc] initWithClock:self->_clock];
        self->_videoRenderer.delegate = self;
        self->_actionMask = HQInfoActionNone;
        self->_minimumTimeInfoInterval = 1.0;
        self->_notificationQueue = [NSOperationQueue mainQueue];
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
        self->_pausesWhenInterrupted = YES;
        self->_pausesWhenEnteredBackground = NO;
        self->_pausesWhenEnteredBackgroundIfNoAudioTrack = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptionHandler:) name:AVAudioSessionInterruptionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroundHandler:) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
    }
    return self;
}

- (void)dealloc
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
    [HQActivity removeTarget:self];
    [self->_currentItem close];
    [self->_clock close];
    [self->_audioRenderer close];
    [self->_videoRenderer close];
}

#pragma mark - Info

- (HQBlock)setPlayerState:(HQPlayerState)state action:(HQInfoAction *)action
{
    if (self->_flags.stateInfo.player == state) {
        return ^{};
    }
    *action |= HQInfoActionStatePlayer;
    self->_flags.stateInfo.player = state;
    return ^{
        if (state == HQPlayerStateReady) {
            if (self->_readyHanler) {
                self->_readyHanler(self);
            }
            if (self->_wantsToPlay) {
                [self play];
            }
        }
    };
}

- (HQBlock)setPlaybackState:(HQInfoAction *)action
{
    HQPlaybackState state = 0;
    if (self->_flags.playing) {
        state |= HQPlaybackStatePlaying;
    }
    if (self->_flags.seekingIndex > 0) {
        state |= HQPlaybackStateSeeking;
    }
    if (self->_flags.stateInfo.player == HQPlayerStateReady &&
        (!self->_flags.audioAvailable || self->_flags.audioFinished) &&
        (!self->_flags.videoAvailable || self->_flags.videoFinished)) {
        state |= HQPlaybackStateFinished;
    }
    if (self->_flags.stateInfo.playback == state) {
        return ^{};
    }
    *action |= HQInfoActionStatePlayback;
    self->_flags.stateInfo.playback = state;
    HQBlock b1 = ^{};
    if (state & HQPlaybackStateFinished) {
        [self setCachedDuration:kCMTimeZero action:action];
        [self setPlaybackTime:self->_flags.timeInfo.duration action:action];
    }
    if (state & HQPlaybackStateFinished) {
        b1 = ^{
            [self->_clock pause];
            [self->_audioRenderer finish];
            [self->_videoRenderer finish];
        };
    } else if (state & HQPlaybackStatePlaying) {
        b1 = ^{
            [self->_clock resume];
            [self->_audioRenderer resume];
            [self->_videoRenderer resume];
        };
    } else {
        b1 = ^{
            [self->_clock pause];
            [self->_audioRenderer pause];
            [self->_videoRenderer pause];
        };
    }
    return b1;
}

- (HQBlock)setLoadingState:(HQLoadingState)state action:(HQInfoAction *)action
{
    if (self->_flags.stateInfo.loading == state) {
        return ^{};
    }
    *action |= HQInfoActionStateLoading;
    self->_flags.stateInfo.loading = state;
    return ^{};
}

- (void)setPlaybackTime:(CMTime)time action:(HQInfoAction *)action
{
    if (CMTimeCompare(self->_flags.timeInfo.playback, time) == 0) {
        return;
    }
    *action |= HQInfoActionTimePlayback;
    self->_flags.timeInfo.playback = time;
}

- (void)setDuration:(CMTime)duration action:(HQInfoAction *)action
{
    if (CMTimeCompare(self->_flags.timeInfo.duration, duration) == 0) {
        return;
    }
    *action |= HQInfoActionTimeDuration;
    self->_flags.timeInfo.duration = duration;
}

- (void)setCachedDuration:(CMTime)duration action:(HQInfoAction *)action
{
    if (CMTimeCompare(self->_flags.timeInfo.cached, duration) == 0) {
        return;
    }
    *action |= HQInfoActionTimeCached;
    self->_flags.timeInfo.cached = duration;
}

#pragma mark - Setter & Getter

- (NSError *)error
{
    NSError *error;
    [self stateInfo:nil timeInfo:nil error:&error];
    return error;
}

- (HQTimeInfo)timeInfo
{
    HQTimeInfo timeInfo;
    [self stateInfo:nil timeInfo:&timeInfo error:nil];
    return timeInfo;
}

- (HQStateInfo)stateInfo
{
    HQStateInfo stateInfo;
    [self stateInfo:&stateInfo timeInfo:nil error:nil];
    return stateInfo;
}

- (BOOL)stateInfo:(HQStateInfo *)stateInfo timeInfo:(HQTimeInfo *)timeInfo error:(NSError **)error
{
    __block NSError *err = nil;
    HQLockEXE00(self->_lock, ^{
        if (stateInfo) {
            *stateInfo = self->_flags.stateInfo;
        }
        if (timeInfo) {
            *timeInfo = self->_flags.timeInfo;
        }
        err = self->_flags.error;
    });
    if (error) {
        *error = err;
    }
    return YES;
}

- (HQPlayerItem *)currentItem
{
    __block HQPlayerItem *ret = nil;
    HQLockEXE00(self->_lock, ^{
        ret = self->_currentItem;
    });
    return ret;
}

- (void)setRate:(Float64)rate
{
    HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_rate != rate;
    }, ^HQBlock {
        self->_rate = rate;
        return nil;
    }, ^BOOL(HQBlock block) {
        self->_clock.rate = rate;
        self->_audioRenderer.rate = rate;
        self->_videoRenderer.rate = rate;
        return YES;
    });
}

- (Float64)rate
{
    __block Float64 ret = 1.0;
    HQLockEXE00(self->_lock, ^{
        ret = self->_rate;
    });
    return ret;
}

- (HQClock *)clock
{
    __block HQClock *ret = nil;
    HQLockEXE00(self->_lock, ^{
        ret = self->_clock;
    });
    return ret;
}

- (HQAudioRender *)audioRenderer
{
    __block HQAudioRender *ret = nil;
    HQLockEXE00(self->_lock, ^{
        ret = self->_audioRenderer;
    });
    return ret;
}

- (HQVideoRender *)videoRenderer
{
    __block HQVideoRender *ret = nil;
    HQLockEXE00(self->_lock, ^{
        ret = self->_videoRenderer;
    });
    return ret;
}

#pragma mark - Item

- (BOOL)replaceWithUrl:(NSURL *)url
{
    return [self replaceWithAsset:url ? [[HQUrlAsset alloc] initWithURL:url] : nil];
}

- (BOOL)replaceWithAsset:(HQAsset *)asset
{
    return [self replaceWithItem:asset ? [[HQPlayerItem alloc] initWithAsset:asset] : nil];
}

- (BOOL)replaceWithItem:(HQPlayerItem *)item
{
    [self stop];
    if (!item) {
        return NO;
    }
    return HQLoclkEXE11(self->_lock, ^HQBlock {
        self->_currentItem = item;
        self->_currentItem.delegate = self;
        self->_currentItem.demuxerOptions = self->_options.demuxer;
        self->_currentItem.decodeOptions = self->_options.decoder;
        self->_currentItem.processOptions = self->_options.processor;
        return nil;
    }, ^BOOL(HQBlock block) {
        return [item open];
    });
}

- (BOOL)stop
{
    [HQActivity removeTarget:self];
    return HQLockEXE10(self->_lock, ^HQBlock {
        HQPlayerItem *currentItem = self->_currentItem;
        self->_currentItem = nil;
        self->_flags.error = nil;
        self->_flags.playing = NO;
        self->_flags.seekingIndex = 0;
        self->_flags.audioFinished = NO;
        self->_flags.videoFinished = NO;
        self->_flags.audioAvailable = NO;
        self->_flags.videoAvailable = NO;
        self->_flags.additionalAction = HQInfoActionNone;
        self->_flags.lastNotificationTime = 0.0;
        self->_flags.timeInfo.cached = kCMTimeInvalid;
        self->_flags.timeInfo.playback = kCMTimeInvalid;
        self->_flags.timeInfo.duration = kCMTimeInvalid;
        self->_flags.stateInfo.player = HQPlayerStateNone;
        self->_flags.stateInfo.loading = HQLoadingStateNone;
        self->_flags.stateInfo.playback = HQPlaybackStateNone;
        HQInfoAction action = HQInfoActionNone;
        HQBlock b1 = [self setPlayerState:HQPlayerStateNone action:&action];
        HQBlock b2 = [self setPlaybackState:&action];
        HQBlock b3 = [self setLoadingState:HQLoadingStateNone action:&action];
        HQBlock b4 = [self infoCallback:action];
        return ^{
            [currentItem close];
            [self->_clock close];
            [self->_audioRenderer close];
            [self->_videoRenderer close];
            b1(); b2(); b3(); b4();
        };
    });
}

#pragma mark - Playback

- (BOOL)play
{
    self->_wantsToPlay = YES;
    [HQActivity addTarget:self];
    return HQLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.stateInfo.player == HQPlayerStateReady;
    }, ^HQBlock {
        self->_flags.playing = YES;
        HQInfoAction action = HQInfoActionNone;
        HQBlock b1 = [self setPlaybackState:&action];
        HQBlock b2 = [self infoCallback:action];
        return ^{b1(); b2();};
    });
}

- (BOOL)pause
{
    self->_wantsToPlay = NO;
    [HQActivity removeTarget:self];
    return HQLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.stateInfo.player == HQPlayerStateReady;
    }, ^HQBlock {
        self->_flags.playing = NO;
        HQInfoAction action = HQInfoActionNone;
        HQBlock b1 = [self setPlaybackState:&action];
        HQBlock b2 = [self infoCallback:action];
        return ^{b1(); b2();};
    });
}

-  (BOOL)seekable
{
    HQPlayerItem *currentItem = [self currentItem];
    return [currentItem seekable];
}

- (BOOL)seekToTime:(CMTime)time
{
    return [self seekToTime:time result:nil];
}

- (BOOL)seekToTime:(CMTime)time result:(HQSeekResult)result
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid result:result];
}

- (BOOL)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter result:(HQSeekResult)result
{
    __block NSUInteger seekingCount = 0;
    __block HQPlayerItem *currentItem = nil;
    BOOL ret = HQLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.stateInfo.player == HQPlayerStateReady;
    }, ^HQBlock {
        self->_flags.seekingIndex += 1;
        currentItem = self->_currentItem;
        seekingCount = self->_flags.seekingIndex;
        HQInfoAction action = HQInfoActionNone;
        HQBlock b1 = [self setPlaybackState:&action];
        HQBlock b2 = [self infoCallback:action];
        return ^{b1(); b2();};
    });
    if (!ret) {
        return NO;
    }
    HQWeakify(self)
    return [currentItem seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter result:^(CMTime time, NSError *error) {
        HQStrongify(self)
        HQLockCondEXE11(self->_lock, ^BOOL {
            return seekingCount == self->_flags.seekingIndex;
        }, ^HQBlock {
            HQBlock b1 = ^{};
            self->_flags.seekingIndex = 0;
            if (!error) {
                self->_flags.audioFinished = NO;
                self->_flags.videoFinished = NO;
                self->_flags.lastNotificationTime = 0.0;
                b1 = ^{
                    [self->_clock flush];
                    [self->_audioRenderer flush];
                    [self->_videoRenderer flush];
                };
            }
            HQInfoAction action = HQInfoActionNone;
            HQBlock b2 = [self setPlaybackState:&action];
            HQBlock b3 = [self infoCallback:action];
            return ^{b1(); b2(); b3();};
        }, ^BOOL(HQBlock block) {
            block();
            if (result) {
                [self callback:^{
                    result(time, error);
                }];
            }
            return YES;
        });
    }];
}

#pragma mark - SGClockDelegate

- (void)clock:(HQClock *)clock didChcnageCurrentTime:(CMTime)currentTime
{
    HQLockEXE10(self->_lock, ^HQBlock {
        HQInfoAction action = HQInfoActionNone;
        [self setPlaybackTime:currentTime action:&action];
        return [self infoCallback:action];
    });
}

#pragma mark - SGRenderableDelegate

- (void)renderable:(id<HQRenderable>)renderable didChangeState:(HQRenderableState)state
{
    NSAssert(state != HQRenderableStateFailed, @"Invaild renderer, %@", renderable);
}

- (void)renderable:(id<HQRenderable>)renderable didChangeCapacity:(HQCapacity)capacity
{
    if (HQCapacityIsEmpty(capacity)) {
        HQLockEXE10(self->_lock, ^HQBlock {
            if (HQCapacityIsEmpty(self->_audioRenderer.capacity) && [self->_currentItem isFinished:HQMediaTypeAudio]) {
                self->_flags.audioFinished = YES;
            }
            if (HQCapacityIsEmpty(self->_videoRenderer.capacity) && [self->_currentItem isFinished:HQMediaTypeVideo]) {
                self->_flags.videoFinished = YES;
            }
            HQInfoAction action = HQInfoActionNone;
            HQBlock b1 = [self setPlaybackState:&action];
            HQBlock b2 = [self infoCallback:action];
            return ^{b1(); b2();};
        });
    }
}

- (__kindof HQFrame *)renderable:(id<HQRenderable>)renderable fetchFrame:(HQTimeReader)timeReader
{
    HQPlayerItem *currentItem = self.currentItem;
    if (renderable == self->_audioRenderer) {
        return [currentItem copyAudioFrame:timeReader];
    } else if (renderable == self->_videoRenderer) {
        return [currentItem copyVideoFrame:timeReader];
    }
    return nil;
}

#pragma mark - SGPlayerItemDelegate

- (void)playerItem:(HQPlayerItem *)playerItem didChangeState:(HQPlayerItemState)state
{
    HQLockEXE10(self->_lock, ^HQBlock {
        HQInfoAction action = HQInfoActionNone;
        HQBlock b1 = ^{}, b2 = ^{}, b3 = ^{}, b4 = ^{};
        switch (state) {
            case HQPlayerItemStateOpening: {
                b1 = [self setPlayerState:HQPlayerStatePreparing action:&action];
            }
                break;
            case HQPlayerItemStateOpened: {
                CMTime duration = self->_currentItem.duration;
                [self setDuration:duration action:&action];
                [self setPlaybackTime:kCMTimeZero action:&action];
                [self setCachedDuration:kCMTimeZero action:&action];
                b1 = ^{
                    [self->_clock open];
                    if ([playerItem isAvailable:HQMediaTypeAudio]) {
                        self->_flags.audioAvailable = YES;
                        [self->_audioRenderer open];
                    }
                    if ([playerItem isAvailable:HQMediaTypeVideo]) {
                        self->_flags.videoAvailable = YES;
                        [self->_videoRenderer open];
                    }
                };
                b2 = [self setPlayerState:HQPlayerStateReady action:&action];
                b3 = [self setLoadingState:HQLoadingStateStalled action:&action];
                b4 = ^{
                    [playerItem start];
                };
            }
                break;
            case HQPlayerItemStateReading: {
                b1 = [self setPlaybackState:&action];
            }
                break;
            case HQPlayerItemStateFinished: {
                b1 = [self setLoadingState:HQLoadingStateFinished action:&action];
                if (HQCapacityIsEmpty(self->_audioRenderer.capacity)) {
                    self->_flags.audioFinished = YES;
                }
                if (HQCapacityIsEmpty(self->_videoRenderer.capacity)) {
                    self->_flags.videoFinished = YES;
                }
                b2 = [self setPlaybackState:&action];
            }
                break;
            case HQPlayerItemStateFailed: {
                self->_flags.error = [playerItem.error copy];
                b1 = [self setPlayerState:HQPlayerStateFailed action:&action];
            }
                break;
            default:
                break;
        }
        HQBlock b5 = [self infoCallback:action];
        return ^{b1(); b2(); b3(); b4(); b5();};
    });
}

- (void)playerItem:(HQPlayerItem *)playerItem didChangeCapacity:(HQCapacity)capacity mediaType:(HQMediaType)type
{
    BOOL should = NO;
    if (type == HQMediaTypeAudio &&
        ![playerItem isFinished:HQMediaTypeAudio]) {
        should = YES;
    } else if (type == HQMediaTypeVideo &&
               ![playerItem isFinished:HQMediaTypeVideo] &&
               (![playerItem isAvailable:HQMediaTypeAudio] || [playerItem isFinished:HQMediaTypeAudio])) {
        should = YES;
    }
    if (should) {
        HQLockEXE10(self->_lock, ^HQBlock {
            HQInfoAction action = HQInfoActionNone;
            CMTime duration = capacity.duration;
            HQLoadingState loadingState = (HQCapacityIsEmpty(capacity) || self->_flags.stateInfo.loading == HQLoadingStateFinished) ? HQLoadingStateStalled : HQLoadingStatePlaybale;
            [self setCachedDuration:duration action:&action];
            HQBlock b1 = [self setLoadingState:loadingState action:&action];
            HQBlock b2 = [self infoCallback:action];
            return ^{b1(); b2();};
        });
    }
}

#pragma mark - Notification

- (HQBlock)infoCallback:(HQInfoAction)action
{
    action &= ~self->_actionMask;
    BOOL needed = NO;
    if (action & HQInfoActionState) {
        needed = YES;
    } else if (action & HQInfoActionTime) {
        NSTimeInterval currentTime = CACurrentMediaTime();
        NSTimeInterval interval = currentTime - self->_flags.lastNotificationTime;
        if (self->_flags.playing == NO ||
            interval >= self->_minimumTimeInfoInterval) {
            needed = YES;
            self->_flags.lastNotificationTime = currentTime;
        } else {
            self->_flags.additionalAction |= (action & HQInfoActionTime);
        }
    }
    if (!needed) {
        return ^{};
    }
    action |= self->_flags.additionalAction;
    self->_flags.additionalAction = HQInfoActionNone;
    NSValue *timeInfo = [NSValue value:&self->_flags.timeInfo withObjCType:@encode(HQTimeInfo)];
    NSValue *stateInfo = [NSValue value:&self->_flags.stateInfo withObjCType:@encode(HQStateInfo)];
    id userInfo = @{HQPlayerTimeinfoUserInfoKey : timeInfo,
                    HQPlayerStateInfoUserInfoKey : stateInfo,
                    HQPlayerInfoActionUserInfoKey : @(action)};
    return ^{
        [self callback:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:HQPlayerDidChangeInfosNotification
                                                                object:self
                                                              userInfo:userInfo];
        }];
    };
}

- (void)callback:(void (^)(void))block
{
    if (!block) {
        return;
    }
    if (self->_notificationQueue) {
        [self->_notificationQueue addOperation:[NSBlockOperation blockOperationWithBlock:block]];
    } else {
        block();
    }
}

+ (HQTimeInfo)timeInfoFromUserInfo:(NSDictionary *)userInfo
{
    HQTimeInfo info;
    NSValue *value = userInfo[HQPlayerTimeinfoUserInfoKey];
    [value getValue:&info];
    return info;
}

+ (HQStateInfo)stateInfoFromUserInfo:(NSDictionary *)userInfo
{
    HQStateInfo info;
    NSValue *value = userInfo[HQPlayerStateInfoUserInfoKey];
    [value getValue:&info];
    return info;
}

+ (HQInfoAction)infoActionFromUserInfo:(NSDictionary *)userInfo
{
    return [userInfo[HQPlayerInfoActionUserInfoKey] unsignedIntegerValue];
}

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
- (void)interruptionHandler:(NSNotification *)notification
{
    if (self->_pausesWhenInterrupted == YES) {
        AVAudioSessionInterruptionType type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
        if (type == AVAudioSessionInterruptionTypeBegan) {
            [self pause];
        }
    }
}

- (void)enterBackgroundHandler:(NSNotification *)notification
{
    if (self->_pausesWhenEnteredBackground) {
        [self pause];
    } else if (self->_pausesWhenEnteredBackgroundIfNoAudioTrack) {
        SGLockCondEXE11(self->_lock, ^BOOL {
            return self->_flags.audioAvailable == NO && self->_flags.videoAvailable == YES;
        }, nil, ^BOOL(SGBlock block) {
            return [self pause];
        });
    }
}
#endif

@end
