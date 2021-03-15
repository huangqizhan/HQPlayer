//
//  HQLock.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQLock.h"

BOOL HQLockEXE00(id<NSLocking> locking, void(^run)(void)){
    [locking lock];
    if (run) {
        run();
    }
    [locking unlock];
    return YES;
}
BOOL HQLockEXE10(id<NSLocking> locking, HQBlock (^run)(void)){
    [locking lock];
    HQBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (r) {
        r();
    }
    return YES;
}
BOOL HQLoclkEXE11(id<NSLocking> locking, HQBlock (^run)(void),BOOL (^finish)(HQBlock block)){
    [locking lock];
    HQBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (finish) {
        return finish(r ? r : ^{});
    } else if (r) {
        r();
    }
    return YES;
}
BOOL HQLockCondEXE00(id<NSLocking> locking, BOOL (^verify)(void), void (^run)(void)){
    [locking lock];
    BOOL s = YES;
    if (verify) {
        s = verify();
    }
    if (!s) {
        [locking unlock];
        return NO;
    }
    if (run) {
        run();
    }
    [locking unlock];
    return YES;
}
BOOL HQLockCondEXE10(id<NSLocking> locking, BOOL (^verify)(void), HQBlock (^run)(void)){
    [locking lock];
    BOOL s = YES;
    if (verify) {
        s = verify();
    }
    if (!s) {
        [locking unlock];
        return NO;
    }
    HQBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (r) {
        r();
    }
    return YES;
}
BOOL HQLockCondEXE11(id<NSLocking> locking, BOOL (^verify)(void), HQBlock (^run)(void), BOOL (^finish)(HQBlock block)){
    [locking lock];
    BOOL s = YES;
    if (verify) {
        s = verify();
    }
    if (!s) {
        [locking unlock];
        return NO;
    }
    HQBlock r = nil;
    if (run) {
        r = run();
    }
    [locking unlock];
    if (finish) {
        return finish(r ? r : ^{});
    } else if (r) {
        r();
    }
    return YES;
}

