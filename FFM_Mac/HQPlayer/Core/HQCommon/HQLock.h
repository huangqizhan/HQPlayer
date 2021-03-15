//
//  HQLock.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDefine.h"

/// lock 操作

BOOL HQLockEXE00(id<NSLocking> locking, void(^run)(void));

BOOL HQLockEXE10(id<NSLocking> locking, HQBlock (^run)(void));
BOOL HQLoclkEXE11(id<NSLocking> locking, HQBlock (^run)(void),BOOL (^finish)(HQBlock block));


BOOL HQLockCondEXE00(id<NSLocking> locking, BOOL (^verify)(void), void (^run)(void));
BOOL HQLockCondEXE10(id<NSLocking> locking, BOOL (^verify)(void), HQBlock (^run)(void));
BOOL HQLockCondEXE11(id<NSLocking> locking, BOOL (^verify)(void), HQBlock (^run)(void), BOOL (^finish)(HQBlock block));


