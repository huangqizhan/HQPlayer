//
//  ex_yuv.c
//  FFM_Mac
//
//  Created by 黄麒展 on 2021/3/6.
//  Copyright © 2021 黄麒展. All rights reserved.
//

#include "ex_yuv.h"


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <libavutil/frame.h>
#include <libavutil/mem.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>

#define VIDEO_INBUF_SIZE 20480
#define VIDEO_REFILL_THRESH 4096

static char err_buf[128] = {0};
static char* av_get_err(int errnum)
{
    av_strerror(errnum, err_buf, 128);
    return err_buf;
}

static void print_video_format(const AVFrame *frame)
{
    printf("width: %u\n", frame->width);
    printf("height: %u\n", frame->height);
    printf("format: %u\n", frame->format);// 格式需要注意
}

static void decode(AVCodecContext *dec_ctx, AVPacket *pkt, AVFrame *frame,
                   FILE *outfile,struct SwsContext *sw_ctx,AVFrame *sw_frame,AVFrame *dst_frame,struct SwsContext *dst_sw_ctx)
{
    int ret;
    /* send the packet with the compressed data to the decoder */
    ret = avcodec_send_packet(dec_ctx, pkt);
    if(ret == AVERROR(EAGAIN))
    {
        fprintf(stderr, "Receive_frame and send_packet both returned EAGAIN, which is an API violation.\n");
    }
    else if (ret < 0)
    {
        fprintf(stderr, "Error submitting the packet to the decoder, err:%s, pkt_size:%d\n",
                av_get_err(ret), pkt->size);
        return;
    }

    /* read all the output frames (infile general there may be any number of them */
    static int frame_index = 0;
    while (ret >= 0)
    {
        // 对于frame, avcodec_receive_frame内部每次都先调用
        ret = avcodec_receive_frame(dec_ctx, frame);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
            return;
//        else if (ret < 0)
//        {
//            fprintf(stderr, "Error during decoding\n");
//            exit(1);
//        }
        static int s_print_format = 0;
        if(s_print_format == 0)
        {
            s_print_format = 1;
            print_video_format(frame);
        }
//        sws_scale(sw_ctx, (const unsigned char* const*)frame->data, frame->linesize, 0, frame->height, sw_frame->data , sw_frame->linesize);
        //  写入y分量
//        fwrite(sw_frame->data[0], 1, sw_frame->width * sw_frame->height,  outfile);      //Y
//        // 写入u分量
//        fwrite(sw_frame->data[1], 1, ((sw_frame->width) * (sw_frame->height))/4,outfile);   //U:宽高均是Y的一半
//        //  写入v分量
//        fwrite(sw_frame->data[2], 1, ((sw_frame->width) * (sw_frame->height))/4,outfile);   //V：宽高均是Y的一半
//
//        printf("frame index = %d height = %d width = %d \n",frame_index,frame->height,frame->width);
//        frame_index ++;
        
        sws_scale(dst_sw_ctx, (const unsigned char* const*)frame->data, frame->linesize, 0, frame->height, dst_frame->data , dst_frame->linesize);
//
        //  写入y分量
        fwrite(dst_frame->data[0], 1, dst_frame->width * dst_frame->height,  outfile);//Y
        // 写入u分量
        fwrite(dst_frame->data[1], 1, (dst_frame->width) *(dst_frame->height)/4,outfile);//U:宽高均是Y的一半
        //  写入v分量
        fwrite(dst_frame->data[2], 1, (dst_frame->width) *(dst_frame->height)/4,outfile);//V：宽高均是Y的一半

        printf("frame index = %d width = %d height = %d \n",frame_index,dst_frame->width,dst_frame->height);
        frame_index ++;
    }
}

static AVFrame* create_frame22(int width ,int height){
    AVFrame* frame = NULL;
    int ret = 0;
    frame = av_frame_alloc();
    if (frame == NULL) {
        av_log(NULL, AV_LOG_DEBUG, "alloc frame error \n");
        goto FAILD;
    }
    
    frame->width = width;
    frame->height = height;
    frame->format = AV_PIX_FMT_YUV420P;
    
    /// 创建buffer
    ret = av_frame_get_buffer(frame, 1);
    if (ret < 0) {
        av_log(NULL, AV_LOG_DEBUG, "alloc frame buffer error \n");
        goto FAILD;
    }
    return frame;
FAILD:
    if (frame) {
        av_frame_free(&frame);
    }
    return NULL;
}
// 提取H264: ffmpeg -i source.200kbps.768x320_10s.flv -vcodec libx264 -an -f h264 source.200kbps.768x320_10s.h264
// 提取MPEG2: ffmpeg -i source.200kbps.768x320_10s.flv -vcodec mpeg2video -an -f mpeg2video source.200kbps.768x320_10s.mpeg2
// 播放：ffplay -pixel_format yuv420p -video_size 768x320 -framerate 25  source.200kbps.768x320_10s.yuv
int ex_video_yuv(const char *src_path, const char *dst_path){
    int ret = 0;
    AVFormatContext *fmt_ctx = NULL;
    
    const AVCodec *codec;
    AVCodecContext *codeCtx = NULL;

    AVStream *stream = NULL;
    int stream_index;

    AVPacket avpkt;

    AVFrame *frame;
    
    AVFrame *sw_frame;
    
    AVFrame *dst_frame;

    FILE *f_file;
    
    struct SwsContext *img_convert_ctx;

    struct SwsContext *swimg_convert_ctx;
    // 1
    if (avformat_open_input(&fmt_ctx, src_path, NULL, NULL) < 0) {
        printf("Could not open source file %s\n", src_path);
        exit(1);
    }
    
    if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
        printf("Could not find stream information\n");
        exit(1);
    }

    av_dump_format(fmt_ctx, 0, src_path, 0);

    av_init_packet(&avpkt);
    avpkt.data = NULL;
    avpkt.size = 0;

     // 2
    stream_index = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if (ret < 0) {
        fprintf(stderr, "Could not find %s stream in input file '%s'\n",
                av_get_media_type_string(AVMEDIA_TYPE_VIDEO), src_path);
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

    
    f_file = fopen(dst_path, "wb+");
    if (f_file == NULL) {
        printf("open  file %s error \n",dst_path);
        return -1;
    }
    //初始化frame，解码后数据
    frame = create_frame22(codeCtx->width, codeCtx->height);
    if (!frame) {
        fprintf(stderr, "Could not allocate video frame\n");
        exit(1);
    }
    
    sw_frame = create_frame22(codeCtx->width, codeCtx->height);
    
    
    if (sw_frame == NULL) {
        printf("sw frame create error \n");
        return -1;
    }
    /// 此处注意内存对齐 
    dst_frame = create_frame22(codeCtx->width*0.5, 900);
    img_convert_ctx = sws_getContext(frame->width, frame->height, frame->format, sw_frame->width, sw_frame->height, sw_frame->format, SWS_BILINEAR, NULL, NULL, NULL);
    
    swimg_convert_ctx =  sws_getContext(frame->width, frame->height, AV_PIX_FMT_YUV420P, dst_frame->width, dst_frame->height, AV_PIX_FMT_YUV420P, SWS_BILINEAR, NULL, NULL, NULL);
    
    while (av_read_frame(fmt_ctx, &avpkt) >= 0) {
        if (avpkt.stream_index == stream_index) {
            decode(codeCtx, &avpkt, frame, f_file,img_convert_ctx,sw_frame,dst_frame,swimg_convert_ctx);
        }
        av_packet_unref(&avpkt);
    }
    return ret;
    return 0;
}
