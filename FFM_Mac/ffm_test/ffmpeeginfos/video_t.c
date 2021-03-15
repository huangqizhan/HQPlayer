//
//  video_t.c
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/14.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#include "video_t.h"
#include <libavutil/avutil.h>
#include <libavutil/imgutils.h>
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
#include <libavformat/avformat.h>
#include <CoreMedia/CoreMedia.h>

int audio_info_t(const char *in_filename) {
    
    int ret = 0;
    AVFormatContext *fmt_ctx = NULL;
    
    const AVCodec *codec;
    AVCodecContext *codeCtx = NULL;

    AVStream *stream = NULL;
    int stream_index;

    AVPacket avpkt;

    int frame_count;
    AVFrame *frame;

    // 1
    if (avformat_open_input(&fmt_ctx, in_filename, NULL, NULL) < 0) {
        printf("Could not open source file %s\n", in_filename);
        exit(1);
    }
    
    if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
        printf("Could not find stream information\n");
        exit(1);
    }

    av_dump_format(fmt_ctx, 0, in_filename, 0);

    av_init_packet(&avpkt);
    avpkt.data = NULL;
    avpkt.size = 0;

     // 2
    stream_index = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    if (ret < 0) {
        fprintf(stderr, "Could not find %s stream in input file '%s'\n",
                av_get_media_type_string(AVMEDIA_TYPE_AUDIO), in_filename);
        return ret;
    }

    stream = fmt_ctx->streams[stream_index];

    // 3
    codec = avcodec_find_decoder(stream->codecpar->codec_id);
    if (codec == NULL) {
        return -1;
    }

    // 4
    codeCtx = avcodec_alloc_context3(NULL);
    if (!codeCtx) {
        fprintf(stderr, "Could not allocate video codec context\n");
        exit(1);
    }


    // 5
    if ((ret = avcodec_parameters_to_context(codeCtx, stream->codecpar)) < 0) {
        fprintf(stderr, "Failed to copy %s codec parameters to decoder context\n",
                av_get_media_type_string(AVMEDIA_TYPE_VIDEO));
        return ret;
    }

    // 6
    avcodec_open2(codeCtx, codec, NULL);


    //初始化frame，解码后数据
    frame = av_frame_alloc();
    if (!frame) {
        fprintf(stderr, "Could not allocate video frame\n");
        exit(1);
    }

    frame_count = 0;
    char buf[1024];
    // 7
    bool isbre = false;
    while (av_read_frame(fmt_ctx, &avpkt) >= 0) {
        if (avpkt.stream_index == stream_index) {
            // 8
            int re = avcodec_send_packet(codeCtx, &avpkt);
            if (re < 0) {
                continue;
            }
            
            // 9 这里必须用while()，因为一次avcodec_receive_frame可能无法接收到所有数据
            while (avcodec_receive_frame(codeCtx, frame) == 0) {
                // 拼接图片路径、名称
//                snprintf(buf, sizeof(buf), "%s/Demo-%d.jpg", out_filename, frame_count);
//                saveJpg(frame, buf); //保存为jpg图片
                enum AVPixelFormat fmt = frame->format;
                printf("fmt = %lld  pts = %lld pkt_duration = %lld \n",frame->best_effort_timestamp,frame->pts,frame->pkt_duration);
//                int num = av_pix_fmt_count_planes(fmt);
//                printf("planes = %d \n",num);
//                for (int i = 0; i < AV_NUM_DATA_POINTERS; i++) {
//                    printf("frame->linesize = %d \n",frame->linesize[i]);
//                }
//                for (int i = 0; i < 3; i++) {
//                    uint8_t *da = frame->data[i];
//                    for (int j = 0; i < 3 ; j++) {
//                        uint8_t n = da[j];
//                        if (j == 2) {
//                            printf("%d \n",n);
//                        }else{
//                            printf("%d ",n);
//                        }
//                    }
//                }
//                frame->nb 
//                int linesize = av_get_bytes_per_sample(fmt);
//                printf("linesize = %d \n",linesize);
//                int isplanar = av_sample_fmt_is_planar(fmt);
//                printf("isplanar = %d \n",isplanar);
//                int channels = frame->channels;
//                printf("channerls = %d \n",channels);
//                size_t fs = sizeof(float);
//                printf("fs = %zu \n",fs);
//                for (int i = 0; i < AV_NUM_DATA_POINTERS; i++) {
//                    printf("linesize = %d \n",frame->linesize[i]);
//                }
                
//                AVRational rational = stream->time_base;
////                printf("duration = %lld \n",frame->pkt_duration);
//                CMTime duration = CMTimeMake(frame->nb_samples, frame->sample_rate);
//                Float64 d = CMTimeGetSeconds(duration);
//                printf("d = %lf \n",d);
//                printf("d-- = %lf \n",d*rational.den);
//                CMTime mt = CMTimeMake(frame->pkt_duration * rational.num, rational.den);
//                Float64 dt = CMTimeGetSeconds(mt);
//                printf("d = %ld \n",frame->nb_samples);
//                break;
//                sws_freeContext
                
//                isbre = true;
//                break;
            }
            frame_count++;
            if (isbre) {
                break;
            }
        }
        av_packet_unref(&avpkt);
    }
    return ret;
}


