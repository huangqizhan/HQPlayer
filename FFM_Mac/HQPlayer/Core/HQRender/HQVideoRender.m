//
//  HQVideoRender.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/6.
//  Copyright © 2020 黄麒展. All rights reserved.
//
#import "HQVideoRender.h"
#import <MetalKit/MetalKit.h>
#import "HQRender+Interal.h"
#import "HQRenderTimer.h"
#import "HQOptions.h"
#import "HQClock.h"
#import "HQClock+Interal.h"
#import "HQLock.h"
#import "HQMapping.h"
#import "HQMacro.h"
#import "HQMetal.h"
#import "HQCapacity.h"

@interface HQVideoRender ()<MTKViewDelegate> {
    struct {
        HQRenderableState state;
        BOOL hasNewFrame;
        /// 已经获取的帧数
        NSUInteger framesFetched;
        /// 已经渲染的帧数
        NSUInteger framesDisplayed;
        /// 当前帧的结束时间
        NSTimeInterval currentFrameEndTime;
        /// 当前帧的开始时间
        NSTimeInterval currentFrameBeginTime;
    }_flags;
    /// 记录当前帧播放的剩余时长
    HQCapacity _capacity;
}
@property (nonatomic,strong,readonly) NSLock *lock;
@property (nonatomic,strong,readonly) HQClock *clock;
/// 渲染定时器
@property (nonatomic,strong,readonly) HQRenderTimer *fetchTimer;
@property (nonatomic,strong,readonly) HQVideoFrame *currentFrame;
/// 渲染模式
@property (nonatomic,strong,readonly) HQMetalModel *planedMode;
@property (nonatomic,strong,readonly) HQMetalModel *sphereMode;

/// metal 渲染器
@property (nonatomic,strong,readonly) HQMetalRender *metalRender;

@property (nonatomic,strong,readonly) HQMetalProjection *projection1;
@property (nonatomic,strong,readonly) HQMetalProjection *projection2;
/// metal 渲染管线
@property (nonatomic,strong,readonly) HQMetalRenderPipelinePool *pipelinePool;

@property (nonatomic,strong,readonly) HQMetalTextureLoader *textureLoader;
@property (nonatomic,strong,readonly) MTKView *metalView;

@end

@implementation HQVideoRender

@synthesize rate = _rate;
@synthesize delegate = _delegate;

+ (NSArray<NSNumber *> *)supportedPixelFormats
{
    return @[
        @(AV_PIX_FMT_BGRA),
        @(AV_PIX_FMT_NV12),
        @(AV_PIX_FMT_YUV420P),
    ];
}

+ (BOOL)isSupportedInputFormat:(int)format
{
    for (NSNumber *obj in [self supportedPixelFormats]) {
        if (format == obj.intValue) {
            return YES;
        }
    }
    return NO;
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
        self->_lock = [[NSLock alloc] init];
        self->_capacity = HQCapacityCreate();
        self->_preferredFramesPerSecond = 30;
        self->_displayMode = HQDisplayModePlane;
        self->_scalingMode = HQScalingModeResizeAspect;
//        self->_matrixMaker = [[HQVRProjection alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self performSelectorOnMainThread:@selector(destoryDrawingLoop)
                           withObject:nil
                        waitUntilDone:YES];
    [self->_currentFrame unlock];
    self->_currentFrame = nil;
}

#pragma mark - Setter & Getter

- (HQBlock)setState:(HQRenderableState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self->_delegate renderable:self didChangeState:state];
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
    HQLockEXE00(self->_lock, ^{
        self->_rate = rate;
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

//- (SGVRViewport *)viewport
//{
//    return self->_matrixMaker.viewport;
//}

- (HQPLFImage *)currentImage
{
    __block HQPLFImage *ret = nil;
    HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_currentFrame != nil;
    }, ^HQBlock {
        HQVideoFrame *frame = self->_currentFrame;
        [frame lock];
        return ^{
            ret = [frame image];
            [frame unlock];
        };
    }, ^BOOL(HQBlock block) {
        block();
        return YES;
    });
    return ret;
}

#pragma mark - Interface

- (BOOL)open
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == HQRenderableStateNone;
    }, ^HQBlock {
        return [self setState:HQRenderableStateRendering];
    }, ^BOOL(HQBlock block) {
        block();
        [self performSelectorOnMainThread:@selector(setupDrawingLoop)
                               withObject:nil
                            waitUntilDone:YES];
        return YES;
    });
}

- (BOOL)close
{
    return HQLoclkEXE11(self->_lock, ^HQBlock {
        HQBlock b1 = [self setState:HQRenderableStateNone];
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        self->_flags.hasNewFrame = NO;
        self->_flags.framesFetched = 0;
        self->_flags.framesDisplayed = 0;
        self->_flags.currentFrameEndTime = 0;
        self->_flags.currentFrameBeginTime = 0;
        self->_capacity = HQCapacityCreate();
        return ^{b1();};
    }, ^BOOL(HQBlock block) {
        [self performSelectorOnMainThread:@selector(destoryDrawingLoop)
                               withObject:nil
                            waitUntilDone:YES];
        block();
        return YES;
    });
}

- (BOOL)pause
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == HQRenderableStateRendering ||
        self->_flags.state == HQRenderableStateFinished;
    }, ^HQBlock {
        return [self setState:HQRenderableStatePaused];
    }, ^BOOL(HQBlock block) {
        self->_metalView.paused = NO;
        self->_fetchTimer.pause = NO;
        return YES;
    });
}

- (BOOL)resume
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == HQRenderableStatePaused ||
        self->_flags.state == HQRenderableStateFinished;
    }, ^HQBlock {
        return [self setState:HQRenderableStateRendering];
    }, ^BOOL(HQBlock block) {
        self->_metalView.paused = NO;
        self->_fetchTimer.pause = NO;
        return YES;
    });
}

- (BOOL)flush
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == HQRenderableStatePaused ||
        self->_flags.state == HQRenderableStateRendering ||
        self->_flags.state == HQRenderableStateFinished;
    }, ^HQBlock {
        [self->_currentFrame unlock];
        self->_currentFrame = nil;
        self->_flags.hasNewFrame = NO;
        self->_flags.framesFetched = 0;
        self->_flags.framesDisplayed = 0;
        self->_flags.currentFrameEndTime = 0;
        self->_flags.currentFrameBeginTime = 0;
        return nil;
    }, ^BOOL(HQBlock block) {
        self->_metalView.paused = NO;
        self->_fetchTimer.pause = NO;
        return YES;
    });
}

- (BOOL)finish
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return
        self->_flags.state == HQRenderableStateRendering ||
        self->_flags.state == HQRenderableStatePaused;
    }, ^HQBlock {
        return [self setState:HQRenderableStateFinished];
    }, ^BOOL(HQBlock block) {
        self->_metalView.paused = NO;
        self->_fetchTimer.pause = NO;
        return YES;
    });
}

#pragma mark - Fecth
/// 刷新帧的定时器 > pts
- (void)fetchTimerHandler
{
    BOOL shouldFetch = NO;
    BOOL shouldPause = NO;
    [self->_lock lock];
    if (self->_flags.state == HQRenderableStateRendering ||
        (self->_flags.state == HQRenderableStatePaused &&
         self->_flags.framesFetched == 0)) {
        shouldFetch = YES;
    } else if (self->_flags.state != HQRenderableStateRendering) {
        shouldPause = YES;
    }
    [self->_lock unlock];
    if (shouldPause) {
        self->_fetchTimer.pause = YES;
    }
    if (!shouldFetch) {
        return;
    }
    __block NSUInteger framesFetched = 0;
    __block NSTimeInterval currentMediaTime = CACurrentMediaTime();
    HQWeakify(self)
    HQVideoFrame *newFrame = [self->_delegate renderable:self fetchFrame:^BOOL(CMTime *desire, BOOL *drop) {
        HQStrongify(self)
        return HQLockCondEXE10(self->_lock, ^BOOL {
            framesFetched = self->_flags.framesFetched;
            /// 如果当前帧是空的 则就不需要时钟的时间
            return self->_currentFrame && framesFetched != 0;
        }, ^HQBlock {
            /// 拿到当前的时钟的时间跟缓冲区第一帧作比较 如果第一帧的pts  <= 时钟的时间则返回第一帧
            return ^{
                currentMediaTime = CACurrentMediaTime();
                *desire = self->_clock.currentTime;
                *drop = YES;
            };
        });
    }];
    HQLockCondEXE10(self->_lock, ^BOOL {
        return !newFrame || framesFetched == self->_flags.framesFetched;
    }, ^HQBlock {
        HQBlock b1 = ^{}, b2 = ^{}, b3 = ^{};
        HQCapacity capacity = HQCapacityCreate();
        if (newFrame) {
            [newFrame lock];
            CMTime time = newFrame.timeStamp;
            CMTime duration = CMTimeMultiplyByFloat64(newFrame.duration, self->_rate);
            capacity.duration = duration;
            [self->_currentFrame unlock];
            self->_currentFrame = newFrame;
            self->_flags.hasNewFrame = YES;
            self->_flags.framesFetched += 1;
            self->_flags.currentFrameBeginTime = currentMediaTime;
            self->_flags.currentFrameEndTime = currentMediaTime + CMTimeGetSeconds(duration);
            if (self->_frameOutput) {
                [newFrame lock];
                b1 = ^{
                    self->_frameOutput(newFrame);
                    [newFrame unlock];
                };
            }
            b2 = ^{
                [self->_clock setVideoTime:time];
            };
        } else if (currentMediaTime < self->_flags.currentFrameEndTime) {
            CMTime time = self->_currentFrame.timeStamp;
            time = CMTimeAdd(time, HQCMTimeMakeWithSeconds(currentMediaTime - self->_flags.currentFrameBeginTime));
            capacity.duration = HQCMTimeMakeWithSeconds(self->_flags.currentFrameEndTime - currentMediaTime);
            b2 = ^{
                [self->_clock setVideoTime:time];
            };
        }
        if (!HQCapacityIsEqual(self->_capacity, capacity)) {
            self->_capacity = capacity;
            b3 = ^{
                [self->_delegate renderable:self didChangeCapacity:capacity];
            };
        }
        return ^{b1(); b2(); b3();};
    });
    [newFrame unlock];
}

#pragma mark - MTKViewDelegate
//// 此处只渲染当前帧  不做其他的处理  
- (void)drawInMTKView:(MTKView *)view
{
//    NSLog(@"draw --- ");
    if (!view.superview ||
        (view.frame.size.width <= 1 &&
         view.frame.size.height <= 1)) {
        return;
    }
    [self->_lock lock];
    HQVideoFrame *frame = self->_currentFrame;
    HQRational presentationSize = frame.descriptor.presentationSize;
    if (!frame ||
        presentationSize.num == 0 ||
        presentationSize.den == 0) {
        [self->_lock unlock];
        return;
    }
    BOOL shouldDraw = NO;
    if (self->_flags.hasNewFrame ||
        self->_flags.framesDisplayed == 0 ||
        (self->_displayMode == HQDisplayModeVR ||
         self->_displayMode == HQDisplayModeVRBox)) {
            shouldDraw = YES;
    }
    if (!shouldDraw) {
        BOOL shouldPause = self->_flags.state != HQRenderableStateRendering;
        [self->_lock unlock];
        if (shouldPause) {
            self->_metalView.paused = YES;
        }
        return;
    }
    NSUInteger framesFetched = self->_flags.framesFetched;
    [frame lock];
    [self->_lock unlock];
    HQDisplayMode displayMode = self->_displayMode;
    HQMetalModel *model = displayMode == HQDisplayModePlane ? self->_planedMode : self->_sphereMode;
    HQMetalRenderPipeline *pipeline = [self->_pipelinePool pipelineWithCVPixelFormat:frame.descriptor.cv_format];
    if (!model || !pipeline) {
        [frame unlock];
        return;
    }
    GLKMatrix4 baseMatrix = GLKMatrix4Identity;
    NSInteger rotate = [frame.metadata[@"rotate"] integerValue];
    if (rotate && (rotate % 90) == 0) {
        float radians = GLKMathDegreesToRadians(-rotate);
        baseMatrix = GLKMatrix4RotateZ(baseMatrix, radians);
        HQRational size = {
            presentationSize.num * ABS(cos(radians)) + presentationSize.den * ABS(sin(radians)),
            presentationSize.num * ABS(sin(radians)) + presentationSize.den * ABS(cos(radians)),
        };
        presentationSize = size;
    }
    NSArray<id<MTLTexture>> *textures = nil;
    if (frame.pixelBuffer) {
        textures = [self->_textureLoader texturesWithCVTextureBuffer:frame.pixelBuffer];
    } else {
//    WithCVPixelFormat:frame.descriptor.cv_format
//                                                         width:frame.descriptor.width
//                                                        height:frame.descriptor.height
//                                                         bytes:(void **)frame.data
//                                                   bytesPerRow:frame.linesize
        textures = [self->_textureLoader texturesWithMTLPixelFormat:frame.descriptor.cv_format textureWidth:frame.descriptor.width textureHight:frame.descriptor.height bytes:(void **)frame.data bytesPerRow:frame.linesize];
    }
    [frame unlock];
    if (!textures.count) {
        return;
    }
    MTLViewport viewports[2] = {};
    NSArray<HQMetalProjection *> *projections = nil;
    CGSize drawableSize = [self->_metalView drawableSize];
    id <CAMetalDrawable> drawable = [self->_metalView currentDrawable];
    if (drawableSize.width == 0 || drawableSize.height == 0) {
        return;
    }
    MTLSize textureSize = MTLSizeMake(presentationSize.num, presentationSize.den, 0);
    MTLSize layerSize = MTLSizeMake(drawable.texture.width, drawable.texture.height, 0);
    switch (displayMode) {
        case HQDisplayModePlane: {
            self->_projection1.matrix = baseMatrix;
            projections = @[self->_projection1];
            viewports[0] = [HQMetalViewPort viewportWithLayerSize:layerSize textureSize:textureSize mode:HQScaling2ViewPort(self->_scalingMode)];
        }
            break;
        case HQDisplayModeVR: {
//            GLKMatrix4 matrix = GLKMatrix4Identity;
//            Float64 aspect = (Float64)drawable.texture.width / drawable.texture.height;
//            if (![self->_matrixMaker matrixWithAspect:aspect matrix1:&matrix]) {
//                break;
//            }
//            self->_projection1.matrix = GLKMatrix4Multiply(baseMatrix, matrix);
//            projections = @[self->_projection1];
//            viewports[0] = [SGMetalViewport viewportWithLayerSize:layerSize];
        }
            break;
        case HQDisplayModeVRBox: {
//            GLKMatrix4 matrix1 = GLKMatrix4Identity;
//            GLKMatrix4 matrix2 = GLKMatrix4Identity;
//            Float64 aspect = (Float64)drawable.texture.width / drawable.texture.height / 2.0;
//            if (![self->_matrixMaker matrixWithAspect:aspect matrix1:&matrix1 matrix2:&matrix2]) {
//                break;
//            }
//            self->_projection1.matrix = GLKMatrix4Multiply(baseMatrix, matrix1);
//            self->_projection2.matrix = GLKMatrix4Multiply(baseMatrix, matrix2);
//            projections = @[self->_projection1, self->_projection2];
//            viewports[0] = [SGMetalViewport viewportWithLayerSizeForLeft:layerSize];
//            viewports[1] = [SGMetalViewport viewportWithLayerSizeForRight:layerSize];
        }
            break;
    }
    if (projections.count) {
        id<MTLCommandBuffer> commandBuffer = [self.metalRender
                                              drawModel:model
                                              viewports:viewports
                                              pipeline:pipeline
                                              projections:projections
                                              intextures:textures
                                              outtextures:drawable.texture];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [self->_lock lock];
        if (self->_flags.framesFetched == framesFetched) {
            self->_flags.framesDisplayed += 1;
            self->_flags.hasNewFrame = NO;
        }
        [self->_lock unlock];
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    HQLockCondEXE10(self->_lock, ^BOOL {
        return
        self->_flags.state == HQRenderableStateRendering ||
        self->_flags.state == HQRenderableStatePaused ||
        self->_flags.state == HQRenderableStateFinished;
    }, ^HQBlock{
        self->_flags.framesDisplayed = 0;
        return ^{
            self->_metalView.paused = NO;
            self->_fetchTimer.pause = NO;
        };
    });
}

#pragma mark - Metal

- (void)setupDrawingLoop
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self->_metalRender = [[HQMetalRender alloc] initWithDevice:device];
    self->_planedMode = [[HQMetalPlanedModel alloc] initWithDevice:device];
    self->_projection1 = [[HQMetalProjection alloc] initWithDevice:device];
    self->_projection2 = [[HQMetalProjection alloc] initWithDevice:device];
    self->_sphereMode = [[HQMetalSphereModel alloc] initWithDevice:device];
    self->_textureLoader = [[HQMetalTextureLoader alloc] initWithDevice:device];
    self->_pipelinePool = [[HQMetalRenderPipelinePool alloc] initWithDevice:device];
    self->_metalView = [[MTKView alloc] initWithFrame:CGRectZero device:device];
    self->_metalView.preferredFramesPerSecond = self->_preferredFramesPerSecond;
//    NSLog(@"self->_preferredFramesPerSecond = %ld",self->_preferredFramesPerSecond);
    self->_metalView.translatesAutoresizingMaskIntoConstraints = NO;
    self->_metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self->_metalView.delegate = self;
    HQWeakify(self)
    self->_fetchTimer = [[HQRenderTimer alloc] initWithHandler:^{
        HQStrongify(self)
        [self fetchTimerHandler];
    }];
    [self updateMetalView];
    [self updateTimeInterval];
}

- (void)destoryDrawingLoop
{
    [self->_fetchTimer stop];
    self->_fetchTimer = nil;
    [self->_metalView removeFromSuperview];
    self->_metalView = nil;
    self->_metalRender = nil;
    self->_planedMode = nil;
    self->_sphereMode = nil;
    self->_projection1 = nil;
    self->_projection2 = nil;
    self->_pipelinePool = nil;
    self->_textureLoader = nil;
}

- (void)setView:(HQPLFView *)view
{
    if (self->_view != view) {
        self->_view = view;
        [self updateMetalView];
        [self updateTimeInterval];
    }
}

- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond
{
    if (self->_preferredFramesPerSecond != preferredFramesPerSecond) {
        self->_preferredFramesPerSecond = preferredFramesPerSecond;
        [self updateTimeInterval];
    }
}

- (void)setDisplayMode:(HQDisplayMode)displayMode
{
    if (self->_displayMode != displayMode) {
        self->_displayMode = displayMode;
        HQLockCondEXE10(self->_lock, ^BOOL {
            return
            self->_displayMode != HQDisplayModePlane &&
            (self->_flags.state == HQRenderableStateRendering ||
             self->_flags.state == HQRenderableStatePaused ||
             self->_flags.state == HQRenderableStateFinished);
        }, ^HQBlock{
            return ^{
                self->_metalView.paused = NO;
                self->_fetchTimer.pause = NO;
            };
        });
    }
}

- (void)updateMetalView
{
    if (self->_view &&
        self->_metalView &&
        self->_metalView.superview != self->_view) {
        HQPLFViewInsertSubview(self->_view, self->_metalView, 0);
        NSLayoutConstraint *c1 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c2 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeLeft
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c3 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0];
        NSLayoutConstraint *c4 = [NSLayoutConstraint constraintWithItem:self->_metalView
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self->_view
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1.0
                                                               constant:0.0];
        [self->_view addConstraints:@[c1, c2, c3, c4]];
    } else {
        [self->_metalView removeFromSuperview];
    }
}

- (void)updateTimeInterval
{
    self->_fetchTimer.timeInterval = 0.5 / self->_preferredFramesPerSecond;
    if (self->_view &&
        self->_view == self->_metalView.superview) {
        self->_metalView.preferredFramesPerSecond = self->_preferredFramesPerSecond;
    } else {
        self->_metalView.preferredFramesPerSecond = 1;
    }
}

@end
