//
//  HQCodecContext.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQCodecContext.h"
#import "HQFrame+Interal.h"
#import "HQPacket+Internal.h"
#import "HQOptions.h"
#import "HQMapping.h"
#import "HQError.h"
#import "HQMacro.h"

//@interface HQCodecContext ()
//
///// 时间基
//@property (nonatomic,readonly) AVRational timebase;
//
///// ffm 解码参数
//@property (nonatomic, readonly) AVCodecParameters *codecpar;
//
///// 解码上下文
//@property (nonatomic,readonly) AVCodecContext *codeContext;
//
//@property (nonatomic,copy,readonly) __kindof HQFrame *(^frameGener)(void);
//
//@end
//
//@implementation HQCodecContext
//
//- (instancetype)initWithTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar frameGenerator:(__kindof HQFrame *(^)(void))frameGenerator{
//    self = [super init];
//    if (self) {
//        self->_timebase = timebase;
//        self->_codecpar = codecpar;
//        self->_frameGener = [frameGenerator copy];
//        self->_options = [HQOptions shareOptions].decoder.copy;
//    }
//    return self;
//}
//
//- (void)dealloc{
//    [self close];
//}
//
//#pragma mark -- inteface
//- (BOOL)open{
//    if (!self->_codecpar) {
//        return NO;
//    }
//    self->_codeContext = [self createAVCodecContext];
//    if (!self->_codeContext) {
//        return NO;
//    }
//    return YES;
//}
//
//- (void)close{
//    if (self->_codeContext) {
//        avcodec_free_context(&self->_codeContext);
//        self->_codeContext = NULL;
//    }
//}
//- (void)flush{
//    if (self->_codeContext) {
//        avcodec_flush_buffers(self->_codeContext);
//    }
//}
//- (NSArray<__kindof HQFrame *> *)decode:(HQPacket *)packet{
//    if (!self->_codeContext) {
//        return nil;
//    }
//    int res = avcodec_send_packet(self->_codeContext, packet ? packet.core : NULL);
//    if (res < 0) {
//        return nil;
//    }
//    NSMutableArray *frames = [NSMutableArray array];
//    while (res != AVERROR(EAGAIN)) {
//        __kindof HQFrame *frame = self->_frameGener();
//        res = avcodec_receive_frame(self->_codeContext, frame.core);
////        if (res == -35) {
////            continue;
////        }
//        NSLog(@"receive frame = %d",res);
//        [frames addObject:frame];
//
////        if (res < 0) {
////            [frame unlock];
////            break;
////        }else{
////            [frames addObject:frame];
////        }
//    }
//    return frames;
//}
//
//#pragma mark --- AVCodecContext
//- (AVCodecContext *)createAVCodecContext{
//    AVCodecContext *context = avcodec_alloc_context3(NULL);
//    if (!context) {
//        return nil;
//    }
//
//    context->opaque = (__bridge void *)self;
//    /// 设置参数
//    BOOL res = avcodec_parameters_to_context(context, self->_codecpar);
//    NSError *error = HQGetFFError(res, HQActionCodeCodecSetParametersToContext);
//    if (error) {
//        avcodec_free_context(&context);
//        return nil;
//    }
//    context->pkt_timebase = self->_timebase;
//    /// AVFoundation 硬件解码
//    if ((self->_options.hardwareDecodeH264 && self->_codecpar->format == AV_CODEC_ID_H264) || (self->_options.hardwareDecodeH265 && self->_codecpar->format == AV_CODEC_ID_H265)) {
//        context->get_format = HQCodecContextGetFormat;
//    }
//    /// 解码器
//    AVCodec *codec = avcodec_find_decoder(self->_codecpar->codec_id);
//    if (codec == NULL) {
//        avcodec_free_context(&context);
//        return nil;
//    }
//    context->codec_id = codec->id;
//    /// 设置解码参数
//    AVDictionary *option = HQDictionaryNS2FFM(self->_options.options);
//    if (self->_options.threadsAuto && !av_dict_get(option, "threads", NULL, 0)) {
//        av_dict_set(&option, "threads", "auto", 0);
//    }
//
//    if (self->_options.resetFrameRate && !av_dict_get(option, "refcounted_frames", NULL, 0)) {
//        av_dict_set(&option, "refcounted_frames", "1", 0);
//    }
//
//    ///打开解码器
//    res = avcodec_open2(context, codec, &option);
//    if (option) {
//        av_dict_free(&option);
//    }
//    error = HQGetFFError(res, HQActionCodeCodecOpen2);
//    if (error) {
//        avcodec_free_context(&context);
//        return nil;
//    }
//    return context;
//}
//
///// AVFoundation 硬件解码
//static enum AVPixelFormat HQCodecContextGetFormat(struct AVCodecContext *s, const enum AVPixelFormat * fmt){
//    HQCodecContext *condeContext = (__bridge HQCodecContext *) s->opaque;
//    for (int i = 0; fmt[i] != AV_PIX_FMT_NONE; i++) {
//        ///< hardware decoding through Videotoolbox
//        if (fmt[i] == AV_PIX_FMT_VIDEOTOOLBOX) {
//            AVBufferRef *device_ctx = av_hwdevice_ctx_alloc(AV_HWDEVICE_TYPE_VIDEOTOOLBOX);
//            if (!device_ctx) {
//                break;
//            }
//            AVBufferRef *frame_ctx = av_hwframe_ctx_alloc(device_ctx);
//            av_buffer_unref(&device_ctx);
//            if (!frame_ctx) {
//                break;
//            }
//            AVHWFramesContext *frame_ctx_data = (AVHWFramesContext *)frame_ctx->data;
//            frame_ctx_data->format = AV_PIX_FMT_VIDEOTOOLBOX;
//            /// 输出格式
//            frame_ctx_data->sw_format = HQPixelFormatAV2FFM(condeContext.options.preferredPixelFormat);
//            frame_ctx_data->width = s->width;
//            frame_ctx_data->height = s->height;
//            int err = av_hwframe_ctx_init(frame_ctx);
//            if (err < 0) {
//                av_buffer_unref(&frame_ctx);
//                break;
//            }
//            s->hw_frames_ctx = frame_ctx;
////            s->hw_device_ctx = device_ctx;
//            return fmt[i];
//        }
//    }
//    return fmt[0];
//}
//@end



@interface HQCodecContext ()

@property (nonatomic, readonly) AVRational timebase;
@property (nonatomic, readonly) AVCodecParameters *codecpar;
@property (nonatomic, readonly) AVCodecContext *codecContext;
@property (nonatomic, copy, readonly) __kindof HQFrame *(^frameGenerator)(void);

@end

@implementation HQCodecContext

- (instancetype)initWithTimebase:(AVRational)timebase
                        codecpar:(AVCodecParameters *)codecpar
                  frameGenerator:(__kindof HQFrame *(^)(void))frameGenerator
{
    if (self = [super init]) {
        self->_timebase = timebase;
        self->_codecpar = codecpar;
        self->_frameGenerator = frameGenerator;
        self->_options = [HQOptions shareOptions].decoder.copy;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Interface

- (BOOL)open
{
    if (!self->_codecpar) {
        return NO;
    }
    self->_codecContext = [self createCcodecContext];
    if (!self->_codecContext) {
        return NO;
    }
    return YES;
}

- (void)close
{
    if (self->_codecContext) {
        avcodec_free_context(&self->_codecContext);
        self->_codecContext = nil;
    }
}

- (void)flush
{
    if (self->_codecContext) {
        avcodec_flush_buffers(self->_codecContext);
    }
}

- (NSArray<__kindof HQFrame *> *)decode:(HQPacket *)packet
{
    if (!self->_codecContext) {
        return nil;
    }
    int result = avcodec_send_packet(self->_codecContext, packet ? packet.core : NULL);
    if (result < 0) {
        return nil;
    }
    NSMutableArray *array = [NSMutableArray array];
    while (result != AVERROR(EAGAIN)) {
        __kindof HQFrame *frame = self->_frameGenerator();
        result = avcodec_receive_frame(self->_codecContext, frame.core);
        if (result < 0) {
            [frame unlock];
            break;
        } else {
            [array addObject:frame];
        }
    }
    return array;
}

#pragma mark - AVCodecContext

- (AVCodecContext *)createCcodecContext
{
    AVCodecContext *codecContext = avcodec_alloc_context3(NULL);
    if (!codecContext) {
        return nil;
    }
    codecContext->opaque = (__bridge void *)self;
    
    int result = avcodec_parameters_to_context(codecContext, self->_codecpar);
    NSError *error = HQGetFFError(result, HQActionCodeCodecSetParametersToContext);
    if (error) {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->pkt_timebase = self->_timebase;
    if ((self->_options.hardwareDecodeH264 && self->_codecpar->codec_id == AV_CODEC_ID_H264) ||
        (self->_options.hardwareDecodeH265 && self->_codecpar->codec_id == AV_CODEC_ID_H265)) {
        codecContext->get_format = SGCodecContextGetFormat;
    }
    
    AVCodec *codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec) {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->codec_id = codec->id;
    
    AVDictionary *opts = HQDictionaryNS2FFM(self->_options.options);
    if (self->_options.threadsAuto &&
        !av_dict_get(opts, "threads", NULL, 0)) {
        av_dict_set(&opts, "threads", "auto", 0);
    }
    if (self->_options.refcountedFrames &&
        !av_dict_get(opts, "refcounted_frames", NULL, 0) &&
        (codecContext->codec_type == AVMEDIA_TYPE_VIDEO || codecContext->codec_type == AVMEDIA_TYPE_AUDIO)) {
        av_dict_set(&opts, "refcounted_frames", "1", 0);
    }
    
    result = avcodec_open2(codecContext, codec, &opts);
    
    if (opts) {
        av_dict_free(&opts);
    }
    
    error = HQGetFFError(result, HQActionCodeCodecOpen2);
    if (error) {
        avcodec_free_context(&codecContext);
        return nil;
    }
    
    return codecContext;
}

static enum AVPixelFormat SGCodecContextGetFormat(struct AVCodecContext *s, const enum AVPixelFormat *fmt)
{
    HQCodecContext *self = (__bridge HQCodecContext *)s->opaque;
    for (int i = 0; fmt[i] != AV_PIX_FMT_NONE; i++) {
        if (fmt[i] == AV_PIX_FMT_VIDEOTOOLBOX) {
            AVBufferRef *device_ctx = av_hwdevice_ctx_alloc(AV_HWDEVICE_TYPE_VIDEOTOOLBOX);
            if (!device_ctx) {
                break;
            }
            AVBufferRef *frames_ctx = av_hwframe_ctx_alloc(device_ctx);
            av_buffer_unref(&device_ctx);
            if (!frames_ctx) {
                break;
            }
            AVHWFramesContext *frames_ctx_data = (AVHWFramesContext *)frames_ctx->data;
            frames_ctx_data->format = AV_PIX_FMT_VIDEOTOOLBOX;
            frames_ctx_data->sw_format = HQPixelFormatAV2FFM(self->_options.preferredPixelFormat);
            frames_ctx_data->width = s->width;
            frames_ctx_data->height = s->height;
            int err = av_hwframe_ctx_init(frames_ctx);
            if (err < 0) {
                av_buffer_unref(&frames_ctx);
                break;
            }
            s->hw_frames_ctx = frames_ctx;
            return fmt[i];
        }
    }
    return fmt[0];
}

@end