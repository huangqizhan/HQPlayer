//
//  video_info.c
//  FFM_Mac
//
//  Created by 8km_mac_mini on 2020/3/8.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#include "video_info.h"
#include <libavformat/avformat.h>

void videoInfo(const char *file_name){
    
    if (file_name == NULL) {return;}
    
    AVFormatContext *in_ctx = NULL;
    
    int ret = 0;
    ret = avformat_open_input(&in_ctx, file_name, 0, 0);
    if (ret < 0) {
        printf("can not open input %s \n",file_name);
        return;
    }
    
    for (int i = 0 ; i < in_ctx->nb_streams; i++) {
        AVStream *stream = in_ctx->streams[i];
        AVCodecParameters *inpar = stream->codecpar;
        if (inpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            AVRational ratio = stream->time_base;
            printf("ratio.num = %d \n",ratio.num);
            printf("ratio.den = %d \n",ratio.den);
            AVCodec *in_codec = avcodec_find_decoder(stream->codecpar->codec_id);
            AVCodecContext *incode_ctx = avcodec_alloc_context3(in_codec);
            printf("incode_ctx->time_base.num = %d \n",incode_ctx->time_base.num);
            printf("incode_ctx->time_base.den = %d \n",incode_ctx->time_base.den);
            printf("incode_ctx time = %f \n",av_q2d(stream->time_base));
            printf("stream time = %f \n",av_q2d(stream->time_base));
            printf("stream->duration = %lld \n",stream->duration);
            
        }
    }
    
}
