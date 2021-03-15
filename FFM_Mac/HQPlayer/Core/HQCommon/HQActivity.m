//
//  HQActivity.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/27.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQActivity.h"
#import "HQPLFTarget.h"

@interface HQActivity ()

@property (nonatomic,strong,readonly) NSLock *lock;
@property (nonatomic,strong,readonly) NSMutableSet *targets;

@end

@implementation HQActivity

+ (void)addTarget:(id)target{
    
}

+ (void)removeTarget:(id)target{
    
}

+ (instancetype)activity{
    static HQActivity *activity = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        activity = [[HQActivity alloc] init];
    });
    return activity;
}
- (instancetype)init{
    self = [super init];
    if (self) {
        self->_lock = [[NSLock alloc] init];
        self->_targets = [NSMutableSet set];
    }
    return self;
}
- (void)addTarget:(id)target
{
    if (!target) {
        return;
    }
    [self->_lock lock];
    if (![self->_targets containsObject:[self token:target]]) {
        [self->_targets addObject:[self token:target]];
    }
    [self reload];
    [self->_lock unlock];
}

- (void)removeTarget:(id)target
{
    if (!target) {
        return;
    }
    [self->_lock lock];
    if ([self->_targets containsObject:[self token:target]]) {
        [self->_targets removeObject:[self token:target]];
    }
    [self reload];
    [self->_lock unlock];
}
- (void)reload
{
#if HQCPLATFORM_TARGET_OS_IPHONE_OR_TV
    BOOL disable = self.targets.count <= 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].idleTimerDisabled = disable;
    });
#endif
}

- (id)token:(id)target
{
    return [NSString stringWithFormat:@"%p", target];
}
@end
