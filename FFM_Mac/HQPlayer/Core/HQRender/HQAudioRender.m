//
//  HQAudioRender.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/6.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAudioRender.h"
#import "HQRender+Interal.h"
#import "HQClock+Interal.h"
#import "HQReanderable.h"
#import "HQClock.h"
#import "HQAudioPlayer.h"
#import "HQDefine.h"
#import "HQAudioFrame.h"
#import "HQLock.h"
#import "HQFFmpeg.h"


@interface HQAudioRender () <HQAudioPlayerDelegate>

{
    struct {
        HQRenderableState state;
        CMTime renderTime;
        CMTime renderDuration;
        int bufferCopiedFrames;
        int currentFrameCopiedFrames;
    } _flags;
    HQCapacity _capacity;
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) HQClock *clock;
@property (nonatomic, strong, readonly) HQAudioPlayer *player;
@property (nonatomic, strong, readonly) HQAudioFrame *currentFrame;

@end

@implementation HQAudioRender

@synthesize rate = _rate;
@synthesize pitch = _pitch;
@synthesize volume = _volume;
@synthesize delegate = _delegate;
@synthesize descriptor = _descriptor;

+ (HQAudioDescriptor *)supportedAudioDescriptor
{
    return [[HQAudioDescriptor alloc] init];
}

- (instancetype)init
{
    NSAssert(NO, @"Invalid Function.");
    return nil;
}

- (instancetype)initWithClock:(HQClock *)clock
{
    if (self = [super init]) {
        self->_clock = clock;
        self->_rate = 1.0;
        self->_pitch = 0.0;
        self->_volume = 1.0;
        self->_lock = [[NSLock alloc] init];
        self->_capacity = HQCapacityCreate();
        self->_descriptor = [HQAudioRender supportedAudioDescriptor];
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Setter & Getter

- (HQBlock)setState:(HQRenderableState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self.delegate renderable:self didChangeState:state];
    };
}

- (HQRenderableState)state
{
    __block HQRenderableState ret = HQRenderableStateNone;
    HQLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (HQCapacity)capacity
{
    __block HQCapacity ret;
    HQLockEXE00(self->_lock, ^{
        ret = self->_capacity;
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
        self->_player.rate = rate;
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

- (void)setPitch:(Float64)pitch
{
    HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_pitch != pitch;
    }, ^HQBlock {
        self->_pitch = pitch;
        return nil;
    }, ^BOOL(HQBlock block) {
        self->_player.pitch = pitch;
        return YES;
    });
}

- (Float64)pitch
{
    __block Float64 ret = 0.0f;
    HQLockEXE00(self->_lock, ^{
        ret = self->_pitch;
    });
    return ret;
}

- (void)setVolume:(Float64)volume
{
    HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_volume != volume;
    }, ^HQBlock {
        self->_volume = volume;
        return nil;
    }, ^BOOL(HQBlock block) {
        self->_player.volume = volume;
        return YES;
    });
}

- (Float64)volume
{
    __block Float64 ret = 1.0f;
    HQLockEXE00(self->_lock, ^{
        ret = self->_volume;
    });
    return ret;
}

- (HQAudioDescriptor *)descriptor
{
    __block HQAudioDescriptor *ret = nil;
    HQLockEXE00(self->_lock, ^{
        ret = self->_descriptor;
    });
    return ret;
}

#pragma mark - Interface

- (BOOL)open
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == HQRenderableStateNone;
    }, ^HQBlock {
        self->_player = [[HQAudioPlayer alloc] init];
        self->_player.delegate = self;
        self->_player.rate = self->_rate;
        self->_player.pitch = self->_pitch;
        self->_player.volume = self->_volume;
        return [self setState:HQRenderableStatePaused];
    }, nil);
}

- (BOOL)close
{
    return HQLoclkEXE11(self->_lock, ^HQBlock {
        self->_flags.currentFrameCopiedFrames = 0;
        self->_flags.bufferCopiedFrames = 0;
        self->_flags.renderTime = kCMTimeZero;
        self->_flags.renderDuration = kCMTimeZero;
        self->_capacity = HQCapacityCreate();
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        return [self setState:HQRenderableStateNone];
    }, ^BOOL(HQBlock block) {
        [self->_player pause];
        self->_player = nil;
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == HQRenderableStateRendering || self->_flags.state == HQRenderableStateFinished;
    }, ^HQBlock {
        return [self setState:HQRenderableStatePaused];
    }, ^BOOL(HQBlock block) {
        [self->_player pause];
        block();
        return YES;
    });
}

- (BOOL)resume
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == HQRenderableStatePaused || self->_flags.state == HQRenderableStateFinished;
    }, ^HQBlock {
        return [self setState:HQRenderableStateRendering];
    }, ^BOOL(HQBlock block) {
        [self->_player play];
        block();
        return YES;
    });
}

- (BOOL)flush
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == HQRenderableStatePaused || self->_flags.state == HQRenderableStateRendering || self->_flags.state == HQRenderableStateFinished;
    }, ^HQBlock {
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        self->_flags.currentFrameCopiedFrames = 0;
        self->_flags.bufferCopiedFrames = 0;
        self->_flags.renderTime = kCMTimeZero;
        self->_flags.renderDuration = kCMTimeZero;
        return ^{};
    }, ^BOOL(HQBlock block) {
        [self->_player flush];
        block();
        return YES;
    });
}

- (BOOL)finish
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == HQRenderableStateRendering || self->_flags.state == HQRenderableStatePaused;
    }, ^HQBlock {
        return [self setState:HQRenderableStateFinished];
    }, ^BOOL(HQBlock block) {
        [self->_player pause];
        block();
        return YES;
    });
}


#pragma mark - SGAudioPlayerDelegate

- (void)audioPlayer:(HQAudioPlayer *)player render:(const AudioTimeStamp *)timeStamp11 data:(AudioBufferList *)data numberOfFrames:(UInt32)numberOfFrames
{
    [self->_lock lock];
    self->_flags.bufferCopiedFrames = 0;
    self->_flags.renderTime = kCMTimeZero;
    self->_flags.renderDuration = kCMTimeZero;
    if (self->_flags.state != HQRenderableStateRendering) {
        [self->_lock unlock];
        return;
    }
    UInt32 bufferLeftFrames = numberOfFrames;
    while (YES) {
        if (bufferLeftFrames <= 0) {
            [self->_lock unlock];
            break;
        }
        if (!self->_currentFrame) {
            [self->_lock unlock];
            HQAudioFrame *frame = [self.delegate renderable:self fetchFrame:nil];
            if (!frame) {
                break;
            }
            [self->_lock lock];
            self->_currentFrame = frame;
        }
        /// 每一帧的音频数据可能跟播放器的采样数不一样   这里需要根据播放器的格式截取  
        HQAudioDescriptor *descriptor = self->_currentFrame.descriptor;
        NSAssert(descriptor.format == AV_SAMPLE_FMT_FLTP, @"Invaild audio frame format.");
        UInt32 currentFrameLeftFrames = self->_currentFrame.numberOfSamples - self->_flags.currentFrameCopiedFrames;
        UInt32 framesToCopy = MIN(bufferLeftFrames, currentFrameLeftFrames);
        UInt32 sizeToCopy = framesToCopy * (UInt32)sizeof(float);
        UInt32 bufferOffset = self->_flags.bufferCopiedFrames * (UInt32)sizeof(float);
        UInt32 currentFrameOffset = self->_flags.currentFrameCopiedFrames * (UInt32)sizeof(float);
        for (int i = 0; i < data->mNumberBuffers && i < descriptor.numberofChannels; i++) {
            memcpy(data->mBuffers[i].mData + bufferOffset, self->_currentFrame.data[i] + currentFrameOffset, sizeToCopy);
        }
        if (self->_flags.bufferCopiedFrames == 0) {
            /// 当前帧的时长
            CMTime duration = CMTimeMultiplyByRatio(self->_currentFrame.duration, self->_flags.currentFrameCopiedFrames, self->_currentFrame.numberOfSamples);
            self->_flags.renderTime = CMTimeAdd(self->_currentFrame.timeStamp, duration);
        }
        CMTime duration = CMTimeMultiplyByRatio(self->_currentFrame.duration, framesToCopy, self->_currentFrame.numberOfSamples);
        self->_flags.renderDuration = CMTimeAdd(self->_flags.renderDuration, duration);
        self->_flags.bufferCopiedFrames += framesToCopy;
        self->_flags.currentFrameCopiedFrames += framesToCopy;
        /// 当前帧播放完  就获取下一帧
        if (self->_currentFrame.numberOfSamples <= self->_flags.currentFrameCopiedFrames) {
            [self->_currentFrame unlock];
            self->_currentFrame = nil;
            self->_flags.currentFrameCopiedFrames = 0;
        }
        bufferLeftFrames -= framesToCopy;
    }
    UInt32 framesCopied = numberOfFrames - bufferLeftFrames;
    UInt32 sizeCopied = framesCopied * (UInt32)sizeof(float);
    for (int i = 0; i < data->mNumberBuffers; i++) {
        UInt32 sizeLeft = data->mBuffers[i].mDataByteSize - sizeCopied;
        if (sizeLeft > 0) {
            memset(data->mBuffers[i].mData + sizeCopied, 0, sizeLeft);
        }
    }
}

- (void)audioPlayer:(HQAudioPlayer *)player didRender:(const AudioTimeStamp *)timestamp
{
    [self->_lock lock];
    CMTime renderTime = self->_flags.renderTime;
    CMTime renderDuration = CMTimeMultiplyByFloat64(self->_flags.renderDuration, self->_rate);
    CMTime frameDuration = !self->_currentFrame ? kCMTimeZero : CMTimeMultiplyByRatio(self->_currentFrame.duration, self->_currentFrame.numberOfSamples - self->_flags.currentFrameCopiedFrames, self->_currentFrame.numberOfSamples);
    HQBlock clockBlock = ^{};
    if (self->_flags.state == HQRenderableStateRendering) {
        if (self->_flags.bufferCopiedFrames) {
            clockBlock = ^{
                [self->_clock setAudioTime:renderTime running:YES];
            };
        } else {
            clockBlock = ^{
                [self->_clock setAudioTime:kCMTimeInvalid running:NO];
            };
        }
    }
    HQCapacity capacity = HQCapacityCreate();
    capacity.duration = CMTimeAdd(renderDuration, frameDuration);
    HQBlock capacityBlock = ^{};
    if (!HQCapacityIsEqual(self->_capacity, capacity)) {
        self->_capacity = capacity;
        capacityBlock = ^{
            [self.delegate renderable:self didChangeCapacity:capacity];
        };
    }
    [self->_lock unlock];
    clockBlock();
    capacityBlock();
}

@end
