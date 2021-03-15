//
//  HQVideoDecoder.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQVideoDecoder.h"
#import "HQFrame+Interal.h"
#import "HQPacket+Internal.h"
#import "HQVideoFrame.h"
#import "HQSWScale.h"
#import "HQCodecContext.h"


//@interface HQVideoDecoder (){
//
//    struct {
//        BOOL needKeyFrame;
//        BOOL needAligment;
//        BOOL sessionFinished;
//        NSUInteger outPutCount;
//    } _flags;
//}
///// 视频帧处理
//@property (nonatomic,readonly) HQSWScale *swScale;
/////  解码上下文
//@property (nonatomic,readonly) HQCodecContext *codeContext;
//@property (nonatomic,readonly) HQAudioFrame *lastDecodeFrame;
//@property (nonatomic,readonly) HQAudioFrame *lastOutputFrame;
//@property (nonatomic,readonly) HQCodecDescriptor *codecDescriptor;
//
//@end
//
//@implementation HQVideoDecoder
//
//@synthesize options = _options;
//
//- (instancetype)init{
//    self = [super init];
//    if (self) {
//        self->_outputFromKeyFrom = YES;
//    }
//    return self;
//}
//- (void)setup{
//    self->_flags.needAligment = YES;
//    self->_codeContext = [[HQCodecContext alloc] initWithTimebase:self->_codecDescriptor.timebase codecpar:self->_codecDescriptor.codecpar frameGenerator:^__kindof HQFrame *{
//        return [HQVideoFrame frame];
//    }];
//    self->_codeContext.options = self->_options;
//    [self->_codeContext open];
//}
//- (void)destory{
//    self->_flags.outPutCount = 0;
//    self->_flags.needKeyFrame = YES;
//    self->_flags.needAligment = YES;
//    self->_flags.sessionFinished = NO;
//    [self->_codeContext close];
//    self->_codeContext = nil;
//    [self->_lastDecodeFrame unlock];
//    self->_lastDecodeFrame = nil;
//    [self->_lastOutputFrame unlock];
//    self->_lastOutputFrame = nil;
//}
//
//- (void)flush{
//    self->_flags.outPutCount = 0;
//    self->_flags.needKeyFrame = YES;
//    self->_flags.needAligment = YES;
//    self->_flags.sessionFinished = NO;
//    [self->_codeContext flush];
//    [self->_lastDecodeFrame unlock];
//    self->_lastDecodeFrame = nil;
//    [self->_lastOutputFrame unlock];
//    self->_lastOutputFrame = nil;
//}
//- (NSArray <__kindof HQFrame *> *)decode:(HQPacket *)pkt{
//    NSMutableArray *ret = [NSMutableArray new];
//    HQCodecDescriptor *cd = pkt.codecDescriptor;
//    NSAssert(cd, @"codecDescriptor is nil");
//    BOOL cdIsEqual = [cd isEqualToDescriptor:self->_codecDescriptor];
//    BOOL codeContextIsEqual = [cd isEqualCodeContextToDescriptor:self->_codecDescriptor];
//    if (!cdIsEqual) {
//        NSArray <HQFrame *> *frames = [self finish];
//        for (HQFrame *f in frames) {
//            [ret addObject:f];
//        }
//        self->_codecDescriptor = cd.copy;
//        if (codeContextIsEqual) {
//            [self flush];
//        }else{
//            [self destory];
//            [self setup];
//        }
//    }
//    if (self->_flags.sessionFinished) {
//        return nil;
//    }
//    [cd fillTodDescriptor:self->_codecDescriptor];
//    if (pkt.flags & HQDataFlagPadding) {
//        /// 预留
//    }else{
//        NSArray *frames = [self processPacket:pkt];
//        for (HQVideoFrame *frame in frames) {
//            [ret addObject:frame];
//        }
//    }
//    if (ret.count) {
//        [self->_lastOutputFrame unlock];
//        self->_lastOutputFrame = ret.lastObject;
//        [self->_lastOutputFrame lock];
//    }
//    self->_flags.outPutCount += ret.count;
//    return ret;
//}
///// 返回的frames 是为了衔接上次的解码
//- (NSArray <__kindof HQFrame *> *)finish{
//    if (self->_flags.sessionFinished) {
//        return nil;
//    }
//    NSArray <__kindof HQFrame *> *frames = [self processPacket:nil];
//    /// 最后一个frame 不够 当前的timerange
//    if (frames.count == 0 && self->_lastDecodeFrame && self->_flags.outPutCount == 0) {
//        CMTimeRange timeRange = self->_codecDescriptor.timeRange;
//        if (CMTIME_IS_NUMERIC(timeRange.start) && CMTIME_IS_NUMERIC(timeRange.duration)) {
//            HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
//            cd.track = self->_lastDecodeFrame.track;
//            cd.metadata = self->_lastDecodeFrame.metadata;
//            [self->_lastDecodeFrame setCodeDescriptor:cd];
//            [self->_lastDecodeFrame fillWithTimeStamp:timeRange.start decodeTimeStamp:timeRange.start duration:timeRange.duration];
//        }
//        frames = @[self->_lastDecodeFrame];
//        [self->_lastDecodeFrame lock];
//    }else if (frames.count == 0 && self->_lastOutputFrame){
//        /// 正常情况下
//        CMTimeRange timeRange = self->_codecDescriptor.timeRange;
//        if (CMTIME_IS_NUMERIC(timeRange.start) && CMTIME_IS_NUMERIC(timeRange.duration)) {
//            CMTime end = CMTimeRangeGetEnd(timeRange);
//            CMTime lastEnd = CMTimeAdd(self->_lastOutputFrame.timeStamp, self->_lastOutputFrame.duration);
//            CMTime duration = CMTimeSubtract(end, lastEnd);
//            if (CMTimeCompare(duration, kCMTimeZero) > 0) {
//                HQVideoFrame *vframe = [HQVideoFrame frame];
//                [vframe fillWithFrame:self->_lastOutputFrame];
//                HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
//                cd.track = vframe.track;
//                cd.metadata = vframe.codeDescriptor.metadata;
//                [vframe setCodeDescriptor:cd];
//                [vframe fillWithTimeStamp:lastEnd decodeTimeStamp:lastEnd duration:duration];
//                frames = @[vframe];
//            }
//        }
//    } else if (frames.count > 0 ){
//        CMTimeRange timerange = self.codecDescriptor.timeRange;
//        if (CMTIME_IS_NUMERIC(timerange.start) && CMTIME_IS_NUMERIC(timerange.duration)) {
//            HQFrame *frame = frames.lastObject;
//            CMTime end  = CMTimeRangeGetEnd(timerange);
//            CMTime lastEnd = CMTimeAdd(frame.timeStamp, frame.duration);
//            CMTime duration = CMTimeSubtract(end, lastEnd);
//            if (CMTimeCompare(duration, kCMTimeZero) > 0) {
//                HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
//                cd.track = frame.track;
//                cd.metadata = frame.codeDescriptor.metadata;
//                [frame setCodeDescriptor:cd];
//                [frame fillWithTimeStamp:frame.timeStamp decodeTimeStamp:frame.timeStamp duration:CMTimeSubtract(end, frame.timeStamp)];
//            }
//        }
//    }
//
//    [self->_lastDecodeFrame unlock];
//    self->_lastDecodeFrame = nil;
//    [self->_lastOutputFrame unlock];
//    self->_lastOutputFrame = nil;
//    NSArray <HQFrame *> *ret = [self resampleFrames:frames];
//    self->_flags.outPutCount += ret.count;
//    return ret;
//}
//#pragma mark ---- process
//- (NSArray <__kindof HQFrame *> *)processPacket:(HQPacket *)packet{
//    HQCodecDescriptor *cd = self->_codecDescriptor;
//    NSArray *frames = [self->_codeContext decode:packet];
//    frames = [self processFrames:frames];
//    frames = [self clipFrames:frames range:cd.timeRange];
//    frames = [self formatFrames:frames];
//    frames = [self clipKeyFrame:frames];
//    return frames;
//}
///// t填充数据
//- (NSArray <__kindof HQFrame *> *)processFrames:(NSArray <__kindof HQFrame *> *)frames {
//    NSMutableArray *ret = [NSMutableArray new];
//    for (HQVideoFrame *frame in frames) {
//        [frame setCodeDescriptor:self->_codecDescriptor.copy];
//        [frame fill];
//        [ret addObject:frame];
//    }
//    return ret;
//}
///// 裁关键帧
//- (NSArray <__kindof HQFrame *> *)clipKeyFrame:(NSArray <__kindof HQFrame *> *)frames {
//    if (self->_outputFromKeyFrom == NO || self->_flags.needKeyFrame == NO) {
//        return frames;
//    }
//    NSMutableArray *ret = [NSMutableArray new];
//    for (HQVideoFrame *frame in frames) {
//        if (self->_flags.needKeyFrame == NO) {
//            [ret addObject:frame];
//        }else if (frame.core->key_frame){
//            [ret addObject:frame];
//            self->_flags.needKeyFrame = NO;
//        }else{
//            [frame unlock];
//        }
//    }
//    return ret;
//}
///// 裁剪帧
//- (NSArray <__kindof HQFrame *> *)clipFrames:(NSArray <__kindof HQFrame *> *)frames range:(CMTimeRange )timeRange{
//    if (frames.count == 0) {
//        return nil;
//    }
//    if (!HQCMTimeIsValid(timeRange.start, NO)) {
//        return nil;
//    }
//    [self->_lastDecodeFrame lock];
//    self->_lastDecodeFrame = frames.lastObject;
//    [self->_lastDecodeFrame unlock];
//    NSMutableArray *ret = [NSMutableArray new];
//    for (HQVideoFrame *frame in frames) {
//        //// frame 不在范围之内
//        if (CMTimeCompare(frame.timeStamp, timeRange.start) < 0) {
//            [frame unlock];
//            continue;
//        }
//        if (!HQCMTimeIsValid(timeRange.duration, NO) && CMTimeCompare(frame.timeStamp, CMTimeRangeGetEnd(timeRange)) >= 0) {
//            [frame unlock];
//            continue;
//        }
//        /// 对齐 第一个fframe跟timerange 开始时间对齐
//        if (self->_flags.needAligment) {
//            self->_flags.needAligment = NO;
//            CMTime start = timeRange.start;
//            CMTime duration = CMTimeSubtract(CMTimeAdd(frame.timeStamp, frame.duration), start);
//            if (CMTimeCompare(frame.timeStamp, start) > 0) {
//                HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
//                cd.track = frame.track;
//                cd.metadata = frame.metadata;
//                [frame setCodeDescriptor:cd];
//                [frame fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
//            }
//        }
//
//        //// 最后一个frame跟timerange 的结束时间对齐
//        if (HQCMTimeIsValid(timeRange.duration, NO)) {
//            CMTime start = frame.timeStamp;
//            CMTime duration = CMTimeSubtract(CMTimeRangeGetEnd(timeRange), start);
//            if (CMTimeCompare(frame.duration, duration) > 0) {
//                self->_flags.sessionFinished = YES;
//                HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
//                cd.track = frame.track;
//                cd.metadata = frame.metadata;
//                [frame setCodeDescriptor:cd];
//                [frame fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
//            }else if (CMTimeCompare(frame.duration, duration) == 0){
//                self->_flags.sessionFinished = YES;
//            }
//        }
//        [ret addObject:frame];
//    }
//    return ret;
//}
///// 格式配置
//- (NSArray <__kindof HQFrame *> *)formatFrames:(NSArray <__kindof HQFrame *> *)frames{
//    NSArray <NSNumber *> *foramts = self->_options.supportedPixelFormats;
//    if (foramts.count <= 0) {
//        return frames;
//    }
//    NSMutableArray *ret = [NSMutableArray new];
//    for (HQVideoFrame *frame in frames) {
//        BOOL supported = NO;
//        for (NSNumber *format in foramts) {
//            if (frame.pixelBuffer || frame.descriptor.format == format.intValue) {
//                supported = YES;
//                break;
//            }
//        }
//        ///如果支持就直接返回
//        if (supported) {
//            [ret addObject:frame];
//            continue;
//        }
//        int format = foramts.firstObject.intValue;
//        if (![self->_swScale.inputDescriptor isEqualToDescriptor:frame.descriptor]) {
//            HQSWScale *swscale = [[HQSWScale alloc] init];
//            swscale.inputDescriptor = frame.descriptor;
//            swscale.outputDescriptor = [frame.descriptor copy];
//            swscale.outputDescriptor.format = format;
//            if ([swscale open]) {
//                self->_swScale = swscale;
//            }
//        }
//        if (!self->_swScale) {
//            [frame unlock];
//            continue;
//        }
//
//        //// 创建新的frame  格式转换
//        HQVideoFrame *newFrame = [HQVideoFrame frameWithDescriptor:self->_swScale.outputDescriptor];
//        int result = [self->_swScale convert:(void *)frame.data inputLinesize:frame.linesize outputData:newFrame.core->data outputLinesize:newFrame.core->linesize];
//        if (result < 0) {
//            [frame unlock];
//            [newFrame unlock];
//            continue;
//        }
//
//        [newFrame setCodeDescriptor:frame.codeDescriptor];
//        [newFrame fillWithTimeStamp:frame.timeStamp decodeTimeStamp:frame.decodeTimeStamp duration:frame.duration];
//        [ret addObject:newFrame];
//        [frame unlock];
//    }
//    return ret;
//}
////// 重新采样
//- (NSArray <__kindof HQFrame *> *)resampleFrames:(NSArray <__kindof HQFrame *> *)frames{
//    ///不需要重置帧率 并且已有最佳帧率
//    if (!self->_options.resetFrameRate && CMTIME_IS_NUMERIC(self->_options.preferredFrameRate)) {
//        return frames;
//    }
//    CMTime frameRate = self->_options.preferredFrameRate;
//    NSMutableArray *ret = [NSMutableArray new];
//
//    for (HQVideoFrame *videoFrame in frames) {
//        HQVideoFrame *frame = videoFrame;
//        /// 如果当前帧的时长大于帧率  重新采样
//        while (CMTimeCompare(frame.duration, frameRate) > 0) {
//            /// 开始时间+每一帧的时间
//            CMTime start = CMTimeAdd(frame.timeStamp, frameRate);
//            /// 截取前面一段
//            CMTime duration = CMTimeSubtract(frame.duration, frameRate);
//            HQCodecDescriptor *cd =[[HQCodecDescriptor alloc] init];
//            cd.track = frame.track;
//            cd.metadata = frame.codeDescriptor.metadata;
//            frame.codeDescriptor = cd;
//            //// 截取前面的一段
//            [frame fillWithTimeStamp:frame.timeStamp decodeTimeStamp:frame.timeStamp duration:frameRate];
//            [ret addObject:frame];
//
//            HQVideoFrame *nextFrame = [HQVideoFrame frame];
//            [nextFrame fillWithFrame:frame];
//            [nextFrame fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
//            frame = nextFrame;
//        }
//        /// 最后一帧
//        [ret addObject:frame];
//    }
//    return ret;
//}
//@end




@interface HQVideoDecoder ()

{
    struct {
        BOOL needsKeyFrame;
        BOOL needsAlignment;
        BOOL sessionFinished;
        NSUInteger outputCount;
    } _flags;
}

@property (nonatomic, strong, readonly) HQSWScale *scaler;
@property (nonatomic, strong, readonly) HQCodecContext *codecContext;
@property (nonatomic, strong, readonly) HQVideoFrame *lastDecodeFrame;
@property (nonatomic, strong, readonly) HQVideoFrame *lastOutputFrame;
@property (nonatomic, strong, readonly) HQCodecDescriptor *codecDescriptor;

@end

@implementation HQVideoDecoder

@synthesize options = _options;

- (instancetype)init
{
    if (self = [super init]) {
        self->_outputFromKeyFrom = YES;
    }
    return self;
}

- (void)dealloc
{
    [self destroy];
}

- (void)setup
{
    self->_flags.needsAlignment = YES;
    self->_codecContext = [[HQCodecContext alloc] initWithTimebase:self->_codecDescriptor.timebase
                                                          codecpar:self->_codecDescriptor.codecpar
                                                    frameGenerator:^__kindof HQFrame *{
        return [HQVideoFrame frame];
    }];
    self->_codecContext.options = self->_options;
    [self->_codecContext open];
}

- (void)destroy
{
    self->_flags.outputCount = 0;
    self->_flags.needsKeyFrame = YES;
    self->_flags.needsAlignment = YES;
    self->_flags.sessionFinished = NO;
    [self->_codecContext close];
    self->_codecContext = nil;
    [self->_lastDecodeFrame unlock];
    self->_lastDecodeFrame = nil;
    [self->_lastOutputFrame unlock];
    self->_lastOutputFrame = nil;
}

#pragma mark - Control

- (void)flush
{
    self->_flags.outputCount = 0;
    self->_flags.needsKeyFrame = YES;
    self->_flags.needsAlignment = YES;
    self->_flags.sessionFinished = NO;
    [self->_codecContext flush];
    [self->_lastDecodeFrame unlock];
    self->_lastDecodeFrame = nil;
    [self->_lastOutputFrame unlock];
    self->_lastOutputFrame = nil;
}

- (NSArray<__kindof HQFrame *> *)decode:(HQPacket *)packet
{
    NSMutableArray *frames = [NSMutableArray array];
    HQCodecDescriptor *cd = packet.codecDescriptor;
    NSAssert(cd, @"Invalid Codec Descriptor.");
    BOOL isEqual = [cd isEqualToDescriptor:self->_codecDescriptor];
    BOOL isEqualCodec = [cd isEqualToDescriptor:self->_codecDescriptor];
    if (!isEqual) {
        NSArray<HQFrame *> *objs = [self finish];
        for (HQFrame *obj in objs) {
            [frames addObject:obj];
        }
        self->_codecDescriptor = [cd copy];
        if (isEqualCodec) {
            [self flush];
        } else {
            [self destroy];
            [self setup];
        }
    }
    if (self->_flags.sessionFinished) {
        return nil;
    }
    [cd fillTodDescriptor:self->_codecDescriptor];
    if (packet.flags & HQDataFlagPadding) {
        
    } else {
        NSArray<HQFrame *> *objs = [self processPacket:packet];
        for (HQFrame *obj in objs) {
            [frames addObject:obj];
        }
    }
    NSArray *ret = [self resampleFrames:frames];
    if (ret.lastObject) {
        [self->_lastOutputFrame unlock];
        self->_lastOutputFrame = ret.lastObject;
        [self->_lastOutputFrame lock];
    }
    self->_flags.outputCount += ret.count;
    return ret;
}

- (NSArray<__kindof HQFrame *> *)finish
{
    if (self->_flags.sessionFinished) {
        return nil;
    }
    NSArray<HQFrame *> *frames = [self processPacket:nil];
    if (frames.count == 0 &&
        self->_lastDecodeFrame &&
        self->_flags.outputCount == 0) {
        CMTimeRange timeRange = self->_codecDescriptor.timeRange;
        if (CMTIME_IS_NUMERIC(timeRange.start) &&
            CMTIME_IS_NUMERIC(timeRange.duration)) {
            HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
            cd.track = self->_lastDecodeFrame.track;
            cd.metadata = self->_lastDecodeFrame.codeDescriptor.metadata;
            [self->_lastDecodeFrame setCodeDescriptor:cd];
            [self->_lastDecodeFrame fillWithTimeStamp:timeRange.start decodeTimeStamp:timeRange.start duration:timeRange.duration];
        }
        frames = @[self->_lastDecodeFrame];
        [self->_lastDecodeFrame lock];
    } else if (frames.count == 0 &&
               self->_lastOutputFrame) {
        CMTimeRange timeRange = self->_codecDescriptor.timeRange;
        if (CMTIME_IS_NUMERIC(timeRange.start) &&
            CMTIME_IS_NUMERIC(timeRange.duration)) {
            CMTime end = CMTimeRangeGetEnd(timeRange);
            CMTime lastEnd = CMTimeAdd(self->_lastOutputFrame.timeStamp, self->_lastOutputFrame.duration);
            CMTime duration = CMTimeSubtract(end, lastEnd);
            if (CMTimeCompare(duration, kCMTimeZero) > 0) {
                HQVideoFrame *obj = [HQVideoFrame frame];
                [obj fillWithFrame:self->_lastOutputFrame];
                HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
                cd.track = obj.track;
                cd.metadata = obj.codeDescriptor.metadata;
                [obj setCodeDescriptor:cd];
                [obj fillWithTimeStamp:lastEnd decodeTimeStamp:lastEnd duration:duration];
                frames = @[obj];
            }
        }
    } else if (frames.count > 0) {
        CMTimeRange timeRange = self->_codecDescriptor.timeRange;
        if (CMTIME_IS_NUMERIC(timeRange.start) &&
            CMTIME_IS_NUMERIC(timeRange.duration)) {
            HQFrame *obj = frames.lastObject;
            CMTime end = CMTimeRangeGetEnd(timeRange);
            CMTime lastEnd = CMTimeAdd(obj.timeStamp, obj.duration);
            CMTime duration = CMTimeSubtract(end, lastEnd);
            if (CMTimeCompare(duration, kCMTimeZero) > 0) {
                HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
                cd.track = obj.track;
                cd.metadata = obj.codeDescriptor.metadata;
                [obj setCodeDescriptor:cd];
                [obj fillWithTimeStamp:obj.timeStamp decodeTimeStamp:obj.timeStamp duration:CMTimeSubtract(end, obj.timeStamp)];
            }
        }
    }
    [self->_lastDecodeFrame unlock];
    self->_lastDecodeFrame = nil;
    [self->_lastOutputFrame unlock];
    self->_lastOutputFrame = nil;
    NSArray *ret = [self resampleFrames:frames];
    self->_flags.outputCount += ret.count;
    return ret;
}

#pragma mark - Process

- (NSArray<__kindof HQFrame *> *)processPacket:(HQPacket *)packet
{
    if (!self->_codecContext || !self->_codecDescriptor) {
        return nil;
    }
    HQCodecDescriptor *cd = self->_codecDescriptor;
    NSArray *frames = [self->_codecContext decode:packet];
    frames = [self processFrames:frames done:!packet];
    frames = [self clipKeyFrames:frames];
    frames = [self clipFrames:frames timeRange:cd.timeRange];
    frames = [self formatFrames:frames];
    return frames;
}

- (NSArray<__kindof HQFrame *> *)processFrames:(NSArray<__kindof HQFrame *> *)frames done:(BOOL)done
{
    NSMutableArray *ret = [NSMutableArray array];
    for (HQAudioFrame *obj in frames) {
        [obj setCodeDescriptor:[self->_codecDescriptor copy]];
        [obj fill];
        [ret addObject:obj];
    }
    return ret;
}
/// 关键帧操作
- (NSArray<__kindof HQFrame *> *)clipKeyFrames:(NSArray<__kindof HQFrame *> *)frames
{
    if (self->_outputFromKeyFrom == NO ||
        self->_flags.needsKeyFrame == NO) {
        return frames;
    }
    NSMutableArray *ret = [NSMutableArray array];
    for (HQFrame *obj in frames) {
        if (self->_flags.needsKeyFrame == NO) {
            [ret addObject:obj];
        } else if (obj.core->key_frame) {
            [ret addObject:obj];
            self->_flags.needsKeyFrame = NO;
        } else {
            [obj unlock];
        }
    }
    return ret;
}
/// 添加帧
- (NSArray<__kindof HQFrame *> *)clipFrames:(NSArray<__kindof HQFrame *> *)frames timeRange:(CMTimeRange)timeRange
{
    if (frames.count <= 0) {
        return nil;
    }
    if (!HQCMTimeIsValid(timeRange.start, NO)) {
        return frames;
    }
    [self->_lastDecodeFrame unlock];
    self->_lastDecodeFrame = frames.lastObject;
    [self->_lastDecodeFrame lock];
    NSMutableArray *ret = [NSMutableArray array];
    for (HQFrame *obj in frames) {
        if (CMTimeCompare(obj.timeStamp, timeRange.start) < 0) {
            [obj unlock];
            continue;
        }
        if (HQCMTimeIsValid(timeRange.duration, NO) &&
            CMTimeCompare(obj.timeStamp, CMTimeRangeGetEnd(timeRange)) >= 0) {
            [obj unlock];
            continue;
        }
        if (self->_flags.needsAlignment) {
            self->_flags.needsAlignment = NO;
            CMTime start = timeRange.start;
            CMTime duration = CMTimeSubtract(CMTimeAdd(obj.timeStamp, obj.duration), start);
            if (CMTimeCompare(obj.timeStamp, start) > 0) {
                HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
                cd.track = obj.track;
                cd.metadata = obj.codeDescriptor.metadata;
                [obj setCodeDescriptor:cd];
                [obj fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
            }
        }
        if (HQCMTimeIsValid(timeRange.duration, NO)) {
            CMTime start = obj.timeStamp;
            CMTime duration = CMTimeSubtract(CMTimeRangeGetEnd(timeRange), start);
            if (CMTimeCompare(obj.duration, duration) > 0) {
                self->_flags.sessionFinished = YES;
                HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
                cd.track = obj.track;
                cd.metadata = obj.codeDescriptor.metadata;
                [obj setCodeDescriptor:cd];
                [obj fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
            } else if (CMTimeCompare(obj.duration, duration) == 0) {
                self->_flags.sessionFinished = YES;
            }
        }
        [ret addObject:obj];
    }
    return ret;
}
//// 格式转换
- (NSArray<__kindof HQFrame *> *)formatFrames:(NSArray<__kindof HQFrame *> *)frames
{
    NSArray<NSNumber *> *formats = self->_options.supportedPixelFormats;
    if (formats.count <= 0) {
        return frames;
    }
    NSMutableArray *ret = [NSMutableArray array];
    for (HQVideoFrame *obj in frames) {
        BOOL supported = NO;
        for (NSNumber *format in formats) {
            if (obj.pixelBuffer ||
                obj.descriptor.format == format.intValue) {
                supported = YES;
                break;
            }
        }
        /// 格式支持
        if (supported) {
            [ret addObject:obj];
            continue;
        }
        /// 不支持的情况下
        int format = formats.firstObject.intValue;
        if (![self->_scaler.inputDescriptor isEqualToDescriptor:obj.descriptor]) {
            HQSWScale *scaler = [[HQSWScale alloc] init];
            scaler.inputDescriptor = obj.descriptor;
            scaler.outputDescriptor = obj.descriptor.copy;
            scaler.outputDescriptor.format = format;
            if ([scaler open]) {
                self->_scaler = scaler;
            }
        }
        if (!self->_scaler) {
            [obj unlock];
            continue;
        }
        HQVideoFrame *newObj = [HQVideoFrame frameWithDescriptor:self->_scaler.outputDescriptor];
        int result = [self->_scaler convert:(void *)obj.data
                              inputLinesize:obj.linesize
                                 outputData:newObj.core->data
                             outputLinesize:newObj.core->linesize];
        if (result < 0) {
            [newObj unlock];
            [obj unlock];
            continue;
        }
        [newObj setCodeDescriptor:obj.codeDescriptor];
        [newObj fillWithTimeStamp:obj.timeStamp decodeTimeStamp:obj.decodeTimeStamp duration:obj.duration];
        [ret addObject:newObj];
        [obj unlock];
    }
    return ret;
}
/// 重新调整帧率  
- (NSArray<__kindof HQFrame *> *)resampleFrames:(NSArray<__kindof HQFrame *> *)frames
{
    if (!self->_options.resetFrameRate &&
        CMTIME_IS_NUMERIC(self->_options.preferredFrameRate)) {
        return frames;
    }
    CMTime frameRate = self->_options.preferredFrameRate;
    NSMutableArray *ret = [NSMutableArray array];
    for (HQVideoFrame *obj in frames) {
        HQVideoFrame *frame = obj;
        while (CMTimeCompare(frame.duration, frameRate) > 0) {
            CMTime start = CMTimeAdd(frame.timeStamp, frameRate);
            CMTime duration = CMTimeSubtract(frame.duration, frameRate);
            HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
            cd.track = frame.track;
            cd.metadata = frame.codeDescriptor.metadata;
            [frame setCodeDescriptor:cd];
            [frame fillWithTimeStamp:frame.timeStamp decodeTimeStamp:frame.timeStamp duration:frameRate];
            HQVideoFrame *newFrame = [HQVideoFrame frame];
            [newFrame fillWithFrame:frame];
            [newFrame fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
            [ret addObject:frame];
            frame = newFrame;
        }
        [ret addObject:frame];
    }
    return ret;
}

@end
