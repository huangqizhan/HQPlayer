//
//  HQClock.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQClock.h"
#import "HQClock+Interal.h"
#import "HQLock.h"
#import "HQTime.h"

@interface HQClock (){

    ///
    BOOL _audioRuning;
    ///
    BOOL _videoRuning;
    /// 时钟
    CMClockRef _masterClock;
    /// 主时基
    CMTimebaseRef _playtimebase;
    /// 音频时间基
    CMTimebaseRef _audioTimeBase;
    /// 视频时间基
    CMTimebaseRef _videoTimeBase;
}
@property (nonatomic,readonly) NSLock *lock;

@end


@implementation HQClock

@synthesize rate = _rate;

- (instancetype)init{
    self = [super init];
    if (self) {
        _masterClock = CMClockGetHostTimeClock();
        _lock = [[NSLock alloc] init];
        _rate = 1.0;
    }
    return self;
}
- (void)setRate:(Float64)rate{
    HQLockEXE00(self->_lock, ^{
        self->_rate = rate;
    });
}
- (Float64)rate{
    __block Float64 rate = 0;
    HQLockEXE00(self->_lock, ^{
        rate = self->_rate;
    });
    return rate;
}
- (CMTime)currentTime{
    __block CMTime time = kCMTimeInvalid;
    HQLockEXE00(self->_lock, ^{
        if (self->_audioRuning) {
            time = CMTimebaseGetTime(self->_audioTimeBase);
        }else{
            time = CMTimebaseGetTime(self->_videoTimeBase);
        }
    });
    return time;
}
- (void)setAudioTime:(CMTime)time running:(BOOL)running{
    HQLockEXE00(self->_lock, ^{
        if (CMTIME_IS_NUMERIC(time)) {
            if (self->_audioRuning != running || self->_videoRuning == NO) {
                self->_audioRuning = running;
                self->_videoRuning = YES;
                /// 如果音频的运行状态与设置的不一样 同步视频时间基
                CMTime playtime = CMTimebaseGetTime(self->_playtimebase);
                /// 设置时间及速率 
                CMTimebaseSetRateAndAnchorTime(self->_videoTimeBase, 1.0, time, playtime);
                CMTimebaseSetRateAndAnchorTime(self->_audioTimeBase, running ? 1 : 0, time, playtime);
            }else{
                /// 同步时间
                CMTimebaseSetTime(self->_audioTimeBase, time);
                CMTimebaseSetTime(self->_videoTimeBase, time);
            }
            [self->_delegate clock:self didChcnageCurrentTime:time];
        }else if (self->_audioRuning != running){
            self->_audioRuning = running;
            /// 设置速率
            CMTimebaseSetRate(self->_audioTimeBase, running ? 1 : 0);
        }
    });
}
- (void)setVideoTime:(CMTime)time{
    HQLockCondEXE00(self->_lock, ^BOOL{
        return self->_audioRuning == NO && CMTIME_IS_NUMERIC(time);
    }, ^{
        if (self->_audioRuning == NO) {
            self->_audioRuning = YES;
            /// 设置时间
            CMTimebaseSetTime(self->_videoTimeBase, time);
            /// 设置速率
            CMTimebaseSetRate(self->_audioTimeBase, 1.0);
        }
        [self->_delegate clock:self didChcnageCurrentTime:time];
    });
}

- (BOOL)open
{
    return HQLockCondEXE00(self->_lock, ^BOOL {
        return self->_audioTimeBase == NULL;
    }, ^{
        /// 创建主时基
        CMTimebaseCreateWithMasterClock(NULL, self->_masterClock, &self->_playtimebase);
        /// 设置主时基时间
        CMTimebaseSetRateAndAnchorTime(self->_playtimebase, 0.0, kCMTimeZero, CMClockGetTime(self->_masterClock));
        /// 创建音频时基
        CMTimebaseCreateWithMasterTimebase(NULL, self->_playtimebase, &self->_audioTimeBase);
        /// 创建视频时基
        CMTimebaseCreateWithMasterTimebase(NULL, self->_playtimebase, &self->_videoTimeBase);
        self->_audioRuning = NO;
        self->_videoRuning = NO;
        /// 获取主时基时间
        CMTime playbackTime = CMTimebaseGetTime(self->_playtimebase);
        /// 设置子时基到具体的时间
        CMTimebaseSetRateAndAnchorTime(self->_audioTimeBase, 0.0, kCMTimeZero, playbackTime);
        CMTimebaseSetRateAndAnchorTime(self->_videoTimeBase, 0.0, kCMTimeZero, playbackTime);
    });
}

- (BOOL)close
{
    return HQLockEXE00(self->_lock, ^{
        self->_audioRuning = NO;
        self->_videoRuning = NO;
        if (self->_audioTimeBase) {
            CFRelease(self->_audioTimeBase);
            self->_audioTimeBase = NULL;
        }
        if (self->_videoTimeBase) {
            CFRelease(self->_videoTimeBase);
            self->_videoTimeBase = NULL;
        }
        if (self->_playtimebase) {
            CFRelease(self->_playtimebase);
            self->_playtimebase = NULL;
        }
    });
}

- (BOOL)pause
{
    return HQLockEXE00(self->_lock, ^{
        CMTimebaseSetRate(self->_playtimebase, 0.0);
    });
}

- (BOOL)resume
{
    return HQLockEXE00(self->_lock, ^{
        /// 设置速率
        CMTimebaseSetRate(self->_playtimebase, self->_rate);
    });
}

- (BOOL)flush
{
    return HQLockEXE00(self->_lock, ^{
        self->_audioRuning = NO;
        self->_videoRuning = NO;
        CMTime playbackTime = CMTimebaseGetTime(self->_playtimebase);
        CMTimebaseSetRateAndAnchorTime(self->_audioTimeBase, 0.0, kCMTimeZero, playbackTime);
        CMTimebaseSetRateAndAnchorTime(self->_videoTimeBase, 0.0, kCMTimeZero, playbackTime);
    });
}

@end
