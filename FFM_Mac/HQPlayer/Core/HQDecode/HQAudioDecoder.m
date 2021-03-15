//
//  HQAudioDecoder.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAudioDecoder.h"
#import "HQPacket+Internal.h"
#import "HQFrame+Interal.h"
#import "HQDescriptor+Internal.h"
#import "HQAudioFormater.h"
#import "HQAudioFrame.h"
#import "HQCodecContext.h"
#import "HQSonic.h"

@interface HQAudioDecoder  (){
    struct {
        /// 第一针的开始时间跟时间范围的开始时间对齐
        BOOL needsAlignment;
        ///  sonic 倍速播放
        BOOL needResetSonic;
        ///
        BOOL sessionFinished;
        /// 下一帧 pts
        int64_t nextTimeStamp;
        /// 最后一帧 pts
        CMTime lastEndTimeStamp;
    } _flags;
}

@property (nonatomic,readonly) HQSonic *sonic;
@property (nonatomic,readonly) HQAudioFormater *audioFormater;
@property (nonatomic,readonly) HQCodecContext *codecContext;
@property (nonatomic,readonly) HQCodecDescriptor *codecDescriptor;
@property (nonatomic,readonly) HQAudioDescriptor *audioDescriptor;

@end

@implementation HQAudioDecoder

@synthesize options = _options;

- (void)dealloc{
    [self destory];
}
- (void)setup{
    self->_flags.nextTimeStamp = 0;
    self->_flags.needResetSonic = YES;
    self->_flags.needsAlignment = YES;
    self->_codecContext = [[HQCodecContext alloc] initWithTimebase:self->_codecDescriptor.timebase codecpar:self->_codecDescriptor.codecpar frameGenerator:^__kindof HQFrame *{
        return [HQAudioFrame frame];
    }];
    self->_codecContext.options = self->_options;
    [self->_codecContext open];
}

- (void)destory{
    self->_flags.nextTimeStamp = 0;
    self->_flags.needResetSonic = YES;
    self->_flags.needsAlignment = YES;
    self->_flags.lastEndTimeStamp = kCMTimeInvalid;
    self->_flags.sessionFinished = NO;
    [self->_codecContext close];
    self->_codecContext = nil;
    self->_audioFormater = nil;
}
- (void)flush{
    self->_flags.nextTimeStamp = 0;
    self->_flags.needsAlignment = YES;
    self->_flags.needResetSonic = YES;
    self->_flags.sessionFinished = NO;
    self->_flags.lastEndTimeStamp = kCMTimeInvalid;
    [self->_codecContext flush];
    [self->_audioFormater flush];
}
- (NSArray <__kindof HQFrame *> *)decode:(HQPacket *)pkt{
    NSMutableArray *frames = [NSMutableArray new];
    HQCodecDescriptor *cd = pkt.codecDescriptor;
    BOOL isEqual = [cd isEqualToDescriptor:self->_codecDescriptor];
    BOOL isCodecEqual = [cd isEqualCodeContextToDescriptor:self->_codecDescriptor];
    if (!isEqual) {
        NSArray *objs = [self finish];
        for (HQFrame *obj in objs) {
            [frames addObject:obj];
        }
        self->_codecDescriptor = [cd copy];
        if (isCodecEqual) {
            [self flush];
        }else{
            [self destory];
            [self setup];
        }
    }
    if (self->_flags.sessionFinished) {
        return nil;
    }
    [cd fillTodDescriptor:self->_codecDescriptor];
    /// 插入的packet  创建跟 HQAudioDescriptor 同样采样大小的frame
    if (pkt.flags & HQDataFlagPadding) {
        HQAudioDescriptor *ad = self->_audioDescriptor;
        if (ad == nil) {
            ad = [[HQAudioDescriptor alloc] init];
        }
        CMTime start = pkt.timeStamp;
        CMTime duration = pkt.duration;
        int nb_samples = (int)CMTimeConvertScale(duration, ad.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
        if (nb_samples > 0) {
            duration = CMTimeMake(nb_samples, ad.sampleRate);
            HQAudioFrame *newFrame = [HQAudioFrame frameWithDescriptor:ad numberofSamples:nb_samples];
            HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
            cd.track = pkt.track;
            cd.metadata = pkt.metadata;
            [newFrame setCodeDescriptor:cd];
            [newFrame fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
            [frames addObject:newFrame];
        }
    }else{
        NSArray *frs = [self processPacket:pkt];
        for (HQFrame *fr in frs) {
            [frames addObject:fr];
        }
    }
    if (frames.count > 0) {
        HQFrame *obj = frames.lastObject;
        self->_flags.lastEndTimeStamp = CMTimeAdd(obj.timeStamp, obj.duration);
    }
    return frames;
}
- (NSArray <__kindof HQFrame *> *)finish{
    if (self->_flags.sessionFinished) {
        return nil;
    }
    NSArray <HQFrame *> *frames = [self processPacket:nil];
    if (frames.count) {
        self->_flags.lastEndTimeStamp = CMTimeAdd(frames.lastObject.timeStamp, frames.lastObject.duration);
    }
    HQCodecDescriptor *cd = self->_codecDescriptor;
    CMTime lastEnd = self->_flags.lastEndTimeStamp;
    CMTimeRange timeRange = cd.timeRange;
    if (CMTIME_IS_NUMERIC(lastEnd) && CMTIME_IS_NUMERIC(timeRange.start) && CMTIME_IS_NUMERIC(timeRange.duration)) {
        CMTime end = CMTimeRangeGetEnd(timeRange);
        CMTime duration = CMTimeSubtract(end, lastEnd);
        HQAudioDescriptor *ad = self->_audioDescriptor;
        int nb_samples = (int)CMTimeConvertScale(duration, ad.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
        if (nb_samples > 0) {
            duration = CMTimeMake(nb_samples, ad.sampleRate);
            HQAudioFrame *obj = [HQAudioFrame frameWithDescriptor:ad numberofSamples:nb_samples];
            HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
            cd.track = self->_codecDescriptor.track;
            cd.metadata = self->_codecDescriptor.metadata;
            [obj setCodeDescriptor:cd];
            [obj fillWithTimeStamp:lastEnd decodeTimeStamp:lastEnd duration:duration];
            NSMutableArray<HQFrame *> *newFrames = [NSMutableArray arrayWithArray:frames];
            [newFrames addObject:obj];
            frames = [newFrames copy];
        }
    }
    return frames;
}
/// 解析packet
- (NSArray <__kindof HQFrame *> *)processPacket:(HQPacket *)packet{
    if (!self->_codecContext || !self->_codecDescriptor) {
        return nil;
    }
    HQCodecDescriptor *cd = self->_codecDescriptor;
    NSArray *frames = [self->_codecContext decode:packet];
    frames = [self processFrames:frames done:!packet];
    frames = [self clipFrames:frames timeRange:cd.timeRange];
//    frames = [self formatFrames:frames];
    return frames;
}
/// 填充数据
- (NSArray <__kindof HQFrame *> *)processFrames:(NSArray <__kindof HQFrame *> *)frames done:(BOOL)done{
    NSMutableArray <__kindof HQFrame *> *ret = [NSMutableArray new];
    for (HQAudioFrame *frame in frames) {
        AVFrame *avFrame = frame.core;
        if (self->_audioDescriptor == nil) {
            self->_audioDescriptor = [[HQAudioDescriptor alloc] initWithFrame:avFrame];
        }
        self->_flags.nextTimeStamp = avFrame->best_effort_timestamp + avFrame->pkt_duration;
        HQAudioDescriptor *ad = self->_audioDescriptor;
        HQCodecDescriptor *cd = self->_codecDescriptor;
        /// 如果不是1倍速播放
        if (CMTimeCompare(cd.scale, CMTimeMake(1, 1)) != 0) {
            if (self->_flags.needResetSonic) {
                self->_flags.needResetSonic = NO;
                self->_sonic = [[HQSonic alloc] initWithDescriptor:ad];
                self->_sonic.speed = 1.0/CMTimeGetSeconds(cd.scale);
                [self->_sonic open];
            }
            int64_t input = av_rescale_q(self->_sonic.samplesInput, av_make_q(1, ad.sampleRate), cd.timebase);
            int64_t pts = avFrame->best_effort_timestamp - input;
            if ([self->_sonic read:avFrame->data nb_samples:avFrame->nb_samples]) {
                [ret addObject:[self readSonicFrame:pts]];
            }
            [frame unlock];
        }else{
            [frame setCodeDescriptor:cd.copy];
            [frame fill];
            [ret addObject:frame];
        }
    }
    if (done) {
        HQAudioDescriptor *ad = self->_audioDescriptor;
        HQCodecDescriptor *cd = self->_codecDescriptor;
        int64_t input = av_rescale_q(self->_sonic.samplesInput, av_make_q(1, ad.sampleRate), cd.timebase);
        int64_t pts = self->_flags.nextTimeStamp - input;
        if ([self->_sonic flush]) {
            [ret addObject:[self readSonicFrame:pts]];
        }
    }
    return ret;
}

/// 根据时间范围截取frames
- (NSArray <__kindof HQFrame *> *)clipFrames:(NSArray <__kindof HQFrame *> *)frames timeRange:(CMTimeRange)timeRanege{
    if (frames.count <= 0) {
        return nil;
    }
    if (!HQCMTimeIsValid(timeRanege.start, NO)) {
        return frames;
    }
    NSMutableArray *ret = [NSMutableArray new];
    for (HQAudioFrame *audioFrame in frames) {
        /// 如果pts 小于 开始时间
        if (CMTimeCompare(audioFrame.timeStamp, timeRanege.start) < 0) {
            [audioFrame unlock];
            continue;
        }
        /// 如果pts 大于 结束时间
        if (HQCMTimeIsValid(timeRanege.duration, NO) && CMTimeCompare(audioFrame.timeStamp, CMTimeRangeGetEnd(timeRanege))) {
            [audioFrame unlock];
            continue;
        }
        HQAudioDescriptor *audioDescriptor = audioFrame.descriptor;
        /// 第一针的开始时间跟时间范围的开始时间对齐
        if (self->_flags.needsAlignment) {
            self->_flags.needsAlignment = NO;
            CMTime start = timeRanege.start;
            CMTime duration = CMTimeSubtract(audioFrame.timeStamp, timeRanege.start);
            int nb_samples = (int)CMTimeConvertScale(duration, audioDescriptor.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
            if (nb_samples > 0) {
                duration = CMTimeMake(nb_samples, audioDescriptor.sampleRate);
                HQAudioFrame *firstFrame = [HQAudioFrame frameWithDescriptor:audioDescriptor numberofSamples:nb_samples];
                HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
                cd.track = audioFrame.track;
                cd.metadata = audioFrame.metadata;
                [firstFrame setCodeDescriptor:cd];
                [firstFrame fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
                [ret addObject:firstFrame];
            }
        }
        
        if (HQCMTimeIsValid(timeRanege.duration, NO)) {
            CMTime start = audioFrame.timeStamp;
            /// 总时长
            CMTime totalDuration = CMTimeSubtract(CMTimeRangeGetEnd(timeRanege), start);
            /// 总采样数
            int totalSamples = (int)CMTimeConvertScale(totalDuration, audioDescriptor.sampleRate, kCMTimeRoundingMethod_RoundTowardZero).value;
            /// 如果总的采样数小于当前帧的采样数
            if (totalSamples < audioFrame.numberOfSamples) {
                self->_flags.sessionFinished = YES;
                totalDuration = CMTimeMake(totalSamples, audioDescriptor.sampleRate);
                HQAudioFrame *oneFrame = [HQAudioFrame frameWithDescriptor:audioDescriptor numberofSamples:totalSamples];
                for (int i = 0; i < _audioDescriptor.numberofChannels; i++) {
                    memcpy(oneFrame.core->data[i], audioFrame.core->data[i], audioFrame.core->linesize[i]);
                }
                HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
                cd.track = audioFrame.track;
                cd.metadata = audioFrame.metadata;
                [oneFrame setCodeDescriptor:cd];
                [oneFrame fillWithTimeStamp:start decodeTimeStamp:start duration:totalDuration];
                [ret addObject:oneFrame];
                [audioFrame unlock];
                continue;
            }else if (totalSamples == audioFrame.numberOfSamples){
                self->_flags.sessionFinished = YES;
            }
        }
        [ret addObject:audioFrame];
    }
    return ret;
}
/// frames  支持的格式配置
- (NSArray <__kindof HQFrame *> *)formatFrames:(NSArray <__kindof HQFrame *> *)frames{
    NSArray <HQAudioDescriptor *> *audioDescriptors = [self->_options supportedAudioDescriptors];
    if (audioDescriptors.count <= 0) {
        return frames;
    }
    NSMutableArray *ret = [NSMutableArray new];
    for (HQAudioFrame * frame in frames) {
        BOOL supported = NO;
        for (HQAudioDescriptor *des in audioDescriptors) {
            if ([frame.descriptor isEqualToDescriptor:des]) {
                supported = YES;
                break;
            }
        }
        if (supported) {
            [ret addObject:frame];
            continue;
        }
        if (self->_audioFormater == nil) {
            self->_audioFormater = [[HQAudioFormater alloc] init];
            self->_audioFormater.descriptor = audioDescriptors.firstObject;
        }
        HQAudioFrame *newFrame = [self->_audioFormater format:frame];
        if (newFrame) {
            [ret addObject:newFrame];
        }
    }
    return ret;
}
/// sonic decode
- (HQAudioFrame *)readSonicFrame:(int64_t)pts{
    int nb_samples = [self->_sonic samplesAvailable];
    HQAudioDescriptor *audioDescriptor = self->_audioDescriptor;
    HQCodecDescriptor *codecDescriptor = self->_codecDescriptor;
    CMTime start = CMTimeMake(pts * codecDescriptor.timebase.num, codecDescriptor.timebase.den);
    CMTime duration = CMTimeMake(nb_samples, audioDescriptor.sampleRate);
    start = [codecDescriptor convertTimeStamp:start];
    HQAudioFrame *one = [HQAudioFrame frameWithDescriptor:audioDescriptor numberofSamples:nb_samples];
    [self->_sonic read:one.core->data nb_samples:nb_samples];
    HQCodecDescriptor *oneCodeDescriptor = [[HQCodecDescriptor alloc] init];
    oneCodeDescriptor.track = codecDescriptor.track;
    oneCodeDescriptor.metadata = codecDescriptor.metadata;
    [one setCodeDescriptor:oneCodeDescriptor];
    [one fillWithTimeStamp:start decodeTimeStamp:start duration:duration];
    return one;
}
@end
