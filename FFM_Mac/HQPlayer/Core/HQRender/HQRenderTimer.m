//
//  HQRenderTimer.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/20.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQRenderTimer.h"

@interface HQRenderTimer ()

@property (nonatomic, copy) dispatch_block_t handler;
@property (nonatomic,strong) NSTimer *timer;

@end

@implementation HQRenderTimer

- (instancetype)initWithHandler:(dispatch_block_t)handler{
    self = [super init];
    if (self) {
        self.handler = handler;
    }
    return self;
}

- (void)dealloc{
    [self stop];
}
- (void)timerHandler{
    if (self.handler) {
        self.handler();
    }
}
- (void)setTimeInterval:(NSTimeInterval)timeInterval{
    if (self->_timeInterval != timeInterval) {
        self->_timeInterval = timeInterval;
        [self start];
    }
}

- (void)setPause:(BOOL)pause{
    if (self->_pause != pause) {
        self->_pause = pause;
        [self fire];
    }
}
- (void)start{
    [self stop];
    self->_timer = [NSTimer timerWithTimeInterval:self->_timeInterval target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self->_timer forMode:NSRunLoopCommonModes];
}
- (void)stop{
    [self->_timer invalidate];
    self->_timer = nil;
}
- (void)fire{
    self->_timer.fireDate = self->_pause ? [NSDate distantFuture] : [NSDate distantPast];
}
@end

