//
//  HQReanderable.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/20.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQCapacity.h"
#import "HQFrame.h"


@protocol HQRenderableDelegate;

/// 渲染状态
typedef NS_ENUM(NSUInteger, HQRenderableState) {
    HQRenderableStateNone      = 0,
    HQRenderableStateRendering = 1,
    HQRenderableStatePaused    = 2,
    HQRenderableStateFinished  = 3,
    HQRenderableStateFailed    = 4,
};

/// 渲染操作
@protocol HQRenderable <NSObject>

/**
 *
 */
@property (nonatomic, weak) id<HQRenderableDelegate> delegate;

/**
 *
 */
@property (nonatomic, readonly) HQRenderableState state;

/**
 *
 */
- (HQCapacity)capacity;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)pause;

/**
 *
 */
- (BOOL)resume;

/**
 *
 */
- (BOOL)flush;

/**
 *
 */
- (BOOL)finish;


@end


/// 渲染状态
@protocol HQRenderableDelegate <NSObject>

/**
 *
 */
- (void)renderable:(id<HQRenderable>)renderable didChangeState:(HQRenderableState)state;

/**
 *
 */
- (void)renderable:(id<HQRenderable>)renderable didChangeCapacity:(HQCapacity)capacity;

/**
 *
 */
- (__kindof HQFrame *)renderable:(id<HQRenderable>)renderable fetchFrame:(HQTimeReader)timeReader;



@end
