//
//  HQUrlDemuxer.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQUrlDemuxer.h"
#import "HQPacket+Internal.h"
#import "HQTrack+Interal.h"
#import "HQOptions.h"
#import "HQMapping.h"
#import "HQFFmpeg.h"
#import "HQError.h"

@interface HQUrlDemuxer ()
/// 时间基
@property (nonatomic,readonly) CMTime baseTime;
@property (nonatomic,readonly) CMTime seekTime;
/// seek 之后 可以容忍的最小值
@property (nonatomic,readonly) CMTime seekTimeMinimum;
@property (nonatomic,readonly) AVFormatContext *context;

@end

@implementation HQUrlDemuxer

@synthesize tracks = _tracks;
@synthesize options = _options;
@synthesize delegate = _delegate;
@synthesize metadata = _metadata;
@synthesize duration = _duration;
@synthesize finishedTracks = _finishedTracks;


- (instancetype)initWithURL:(NSURL *)url{
    self = [super init];
    if (self) {
        self->_URL = [url copy];
        self->_duration = kCMTimeInvalid;
        self->_baseTime = kCMTimeInvalid;
        self->_seekTime = kCMTimeInvalid;
        self->_seekTimeMinimum = kCMTimeInvalid;
        self->_options = [HQOptions shareOptions].demuxer.copy;
    }
    return self;
}
- (void)dealloc{
    NSAssert(!self.context, @"avformatcontext is not released");
}
#pragma mark  Controll
- (id<HQDemuxable>)shareDemuxer{
    return self;
}
- (NSError *)open{
    if (self->_context) {
        return nil;
    }
    HQFFmpegSetupIfNeeded();
    NSError *error = HQCreateAVFormatContext(&self->_context, self->_URL, self->_options.options, (__bridge void *)self, *HQURLDEMuxerInteruptHandler);
    if (error) {
        return error;
    }
    
    if (self->_context->duration > 0) {
        self->_duration = CMTimeMake(self->_context->duration, AV_TIME_BASE);
    }
    if (self->_context->metadata) {
        self->_metadata = HQDictionaryFFM2NS(self->_context->metadata);
    }
    NSMutableArray <HQTrack *> *tracks = [NSMutableArray array];
    for (int i = 0; i < self->_context->nb_streams ; i++) {
        AVStream *stream = self->_context->streams[i];
        HQMediaType type = HQMediaTypeFFM2HQ(stream->codecpar->codec_type);
        /// 该流是视频信息 但只有一张图片 一般是音频文件的封面
        if (type == HQMediaTypeVideo && stream->disposition & AV_DISPOSITION_ATTACHED_PIC) {
            type = HQMediaTypeUnknown;
        }
        HQTrack *track = [[HQTrack alloc] initWithType:type index:i];
        track.core = stream;
        [tracks addObject:track];
    }
    self->_tracks = [tracks copy];
    return nil;
}

- (NSError *)close{
    if (self->_context) {
        avformat_close_input(&self->_context);
        self->_context = NULL;
    }
    return nil;
}
- (NSError *)seekable{
    if (self->_context) {
        if (self->_context->pb && self->_context->pb->seekable) {
            return nil;
        }
        return HQCreateError(HQErrorCodeFormatNotSeekable, HQActionCodeFormatGetSeekable);
    }
    return HQCreateError(HQErrorCodeNoValidFormat, HQActionCodeFormatGetSeekable);
}
- (NSError *)seekToTime:(CMTime)time{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}
- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter{
    if (!CMTIME_IS_NUMERIC(time)) {
        return HQCreateError(HQErrorCodeInvlidTime, HQActionCodeFormatSeekFrame);
    }
    NSError *error = [self seekable];
    if (error) {
        return error;
    }
    if (self->_context) {
        /// 以ffmpeg 的时间刻度换算时间
        int64_t timeStamp = CMTimeConvertScale(time, AV_TIME_BASE, kCMTimeRoundingMethod_RoundTowardZero).value;
        int ret = avformat_seek_file(self->_context, -1, INT64_MIN, timeStamp, INT64_MAX, AVSEEK_FLAG_BACKWARD);
        if (ret >= 0) {
            self->_seekTime = time;
            self->_baseTime = kCMTimeInvalid;
            if (CMTIME_IS_NUMERIC(toleranceBefor)) {
                self->_seekTimeMinimum = CMTimeSubtract(time,CMTimeMaximum(toleranceBefor, kCMTimeZero));
            }else{
                self->_seekTimeMinimum = kCMTimeInvalid;
            }
            self->_finishedTracks = nil;
        }
        return HQCreateError(ret, HQActionCodeFormatSeekFrame);
    }
    return HQCreateError(HQErrorCodeNoValidFormat, HQActionCodeFormatSeekFrame);
}
- (NSError *)nextPacket:(HQPacket **)packet{
    if (self->_context) {
        HQPacket *pkt = [HQPacket packet];
        int ret = av_read_frame(self->_context, pkt.core);
        if (ret < 0) {
            [pkt unlock];
        }else{
            AVStream *stream = self->_context->streams[pkt.core->stream_index];
            if (CMTIME_IS_NUMERIC(self->_baseTime)) {
                self->_baseTime = CMTimeMake(pkt.core->pts * stream->time_base.num, stream->time_base.den);
            }
            CMTime start = self->_baseTime;
            if (CMTIME_IS_NUMERIC(self->_seekTime)) {
                start = CMTimeMinimum(self->_baseTime, self->_seekTime);
            }
            if (CMTIME_IS_NUMERIC(self->_seekTimeMinimum)) {
                start = CMTimeMaximum(start, self->_seekTimeMinimum);
            }
            HQCodecDescriptor *cd = [[HQCodecDescriptor alloc] init];
            cd.track = self->_tracks[pkt.core->stream_index];
            cd.metadata = HQDictionaryFFM2NS(stream->metadata);
            cd.timebase = stream->time_base;
            cd.codecpar = stream->codecpar;
            [cd appendTimeRange:CMTimeRangeMake(start, kCMTimePositiveInfinity)];
            [pkt setCodecDescriptor:cd];
            [pkt fill];
            *packet = pkt;
        }
        NSError *error = HQGetFFError(ret, HQActionCodeFormatReadFrame);
        ///如果到最后了
        if (error.code == HQErrorCodeDemuxerEndOfFile) {
            self->_finishedTracks = self->_tracks.copy;
        }
        return error;
    }
    return HQCreateError(HQErrorCodeNoValidFormat, HQActionCodeFormatReadFrame);
}
#pragma mark -- AVFormatContext
static NSError * HQCreateAVFormatContext(AVFormatContext **context,NSURL *url,NSDictionary *optins,void *opaque , int(*callback)(void *)){
    AVFormatContext *ctx = avformat_alloc_context();
    if (!ctx) {
        return HQCreateError(HQErrorCodeNoValidFormat, HQActionCodeFormatCreate);
    }
    ctx->interrupt_callback.callback = callback;
    ctx->interrupt_callback.opaque = opaque;
    
    NSString *urlString = url.isFileURL ? url.path : url.absoluteString;
    AVDictionary *avoptoin = HQDictionaryNS2FFM(optins);
    if ([[urlString lowercaseString] hasPrefix:@"rtmp"] || [[urlString lowercaseString] hasPrefix:@"rtsp"]) {
        av_dict_set(&avoptoin, "timeout", NULL, 0);
    }
    int success = avformat_open_input(&ctx, urlString.UTF8String, NULL, NULL);
    if (avoptoin) {
        av_dict_free(&avoptoin);
    }
    NSError *error = HQGetFFError(success, HQActionCodeFormatOpenInput);
    if (error) {
        if (ctx) {
            avformat_free_context(ctx);
        }
        return error;
    }
    success = avformat_find_stream_info(ctx, NULL);
    error = HQGetFFError(success, HQActionCodeFormatFindStreamInfo);
    if (error) {
        if (ctx) {
            avformat_close_input(&ctx);
            avformat_free_context(ctx);
        }
        return error;
    }
    *context = ctx;
    return nil;
}
static int HQURLDEMuxerInteruptHandler(void *demuxer){
    HQUrlDemuxer *urlDemuxer =  (__bridge HQUrlDemuxer *)demuxer;
    if ([urlDemuxer->_delegate respondsToSelector:@selector(demuxableShouldAbortBlockingFunctions:)]) {
        return [urlDemuxer->_delegate demuxableShouldAbortBlockingFunctions:urlDemuxer];
    }
    return 0;
}
@end
