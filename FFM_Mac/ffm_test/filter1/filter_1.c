//
//  filter_1.c
//  FFM_Mac
//
//  Created by 黄麒展 on 2021/2/23.
//  Copyright © 2021 黄麒展. All rights reserved.
//

#include "filter_1.h"
#include <unistd.h>
#include <libavutil/avutil.h>
#include <libavformat/avformat.h>
#include <libavcodec/codec.h>
#include <libavdevice/avdevice.h>
#include <libswresample/swresample.h>

static AVCodecContext *code_ctx;
static AVFormatContext *fmt_ctx;
static int video_index = 0;

static int open_input(const char *file_name){
    
    int ret = 0;
    AVCodec *code = NULL;
    av_log_set_level(AV_LOG_DEBUG);
    ret = avformat_open_input(&fmt_ctx, file_name, NULL, NULL);
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "open input error \n");
        return -1;
    }
    
    ret = avformat_find_stream_info(fmt_ctx, NULL);
    if (ret < 0) {
        av_log(NULL, AV_LOG_DEBUG, "find stream error \n");
        return -1;
    }
    
    
    ret = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, &code, 0);
    if (ret < 0) {
        av_log(NULL, AV_LOG_DEBUG, "find best stream error \n");
        return -1;
    }
    video_index = ret;
    
    code_ctx = avcodec_alloc_context3(code);
    if (code_ctx == NULL) {
        av_log(NULL, AV_LOG_ERROR, "alloc codecctx error \n");
        return -1;
    }
    
    ret = avcodec_parameters_to_context(code_ctx, fmt_ctx->streams[video_index]->codecpar);
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "code parmeters to contex error \n");
        return -1;
    }
    
    ret = avcodec_open2(code_ctx, code, NULL);
    if (ret < 0) {
        av_log(NULL, AV_LOG_DEBUG, "avcodec oprn error \n");
        return -1;
    }
    return 1;
}

void filter_action1(const char *file_name){
    
    int ret = open_input(file_name);
    
    if (ret < 0) {
        av_log(NULL, AV_LOG_DEBUG, "open input error\n");
        return;
    }
}



