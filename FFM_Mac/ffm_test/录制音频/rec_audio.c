//
//  rec_audio.c
//  Media
//
//  Created by 黄麒展 on 2021/1/28.
//

#include "rec_audio.h"
#include <unistd.h>
#include <libavdevice/avdevice.h>
#include <libavutil/avutil.h>
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>


void encode(AVCodecContext *code_ctx,AVFrame *frame,AVPacket *code_packet, FILE *outfile){
    int ret = 0;
    char str[512];
    ret = avcodec_send_frame(code_ctx, frame);
    if (ret < 0) {
        printf("encode = %d err = %s \n",ret,av_make_error_string(str, 512, ret));
    }
    while (ret >= 0) {
        ret = avcodec_receive_packet(code_ctx, code_packet);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
            break;
        }else if (ret < 0 ){
            av_log(NULL, AV_LOG_DEBUG, "code frame error");
            exit(-1);
        }
        size_t size = fwrite(code_packet->data, 1, code_packet->size, outfile);
        printf("write size = %zu \n",size);
        fflush(outfile);
    }
}

int rec_audio1(const char *a_path){

    
    AVFormatContext *pFormatCtx;
    int             i, videoindex;
    AVCodecContext  *pCodecCtx = NULL;
    AVCodec         *pCodec = NULL;

    avformat_network_init();
    pFormatCtx = avformat_alloc_context();

        //Register Device
    avdevice_register_all();


        //Linux
    AVInputFormat *ifmt=av_find_input_format("avfoundation");
    if(avformat_open_input(&pFormatCtx,":0",ifmt,NULL)!=0){
        printf("Couldn't open input stream.default\n");
        return -1;
    }
        /*if (avformat_open_input(&pFormatCtx, filepath, NULL, NULL) != 0)
        {
            printf("Couldn't open an input stream.\n");
            return -1;
        }  */
    if(avformat_find_stream_info(pFormatCtx,NULL)<0)
    {
        printf("Couldn't find stream information.\n");
        return -1;
    }
        videoindex = -1;
    for(i = 0; i<pFormatCtx->nb_streams; i++){
        AVCodecParameters *par = pFormatCtx->streams[i]->codecpar;
        if(par->codec_type == AVMEDIA_TYPE_AUDIO){
            videoindex = i;
            pCodec = avcodec_find_decoder(par->codec_id);
            pCodecCtx = avcodec_alloc_context3(pCodec);
            avcodec_parameters_to_context(pCodecCtx, par);
            break;
        }
    }
    if(videoindex == -1){
        printf("Couldn't find a video stream.\n");
        return -1;
    }
    if(pCodec == NULL){
        printf("Codec not found.\n");
        return -1;
    }
    if(avcodec_open2(pCodecCtx, pCodec,NULL)<0){
        printf("Could not open codec.\n");
        return -1;
    }

    int ret;

    AVPacket *packet = (AVPacket *)av_malloc(sizeof(AVPacket));

    AVFrame* pAudioFrame = av_frame_alloc();
    
    if(NULL == pAudioFrame){
        printf("could not alloc pAudioFrame\n");
        return -1;
    }
    ///audio output paramter //resample
    uint64_t out_channel_layout = 3;
    int out_sample_fmt = AV_SAMPLE_FMT_S16;
    int out_nb_samples = 512; //
    int out_sample_rate = 44100;
    int out_nb_channels = av_get_channel_layout_nb_channels(out_channel_layout);
    int out_buffer_size = av_samples_get_buffer_size(NULL, out_nb_channels, out_nb_samples, out_sample_fmt, 1);
    uint8_t *buffer = NULL;
    int sample_size = av_get_bytes_per_sample(AV_SAMPLE_FMT_S16);
    int audio_size = out_nb_samples * out_nb_channels *sample_size;
    buffer = (uint8_t *)av_malloc(audio_size);
    int64_t in_channel_layout = av_get_default_channel_layout(pCodecCtx->channels);

    struct SwrContext *audio_convert_ctx = NULL;
    audio_convert_ctx = swr_alloc();
    if (audio_convert_ctx == NULL){
        printf("Could not allocate SwrContext  \n");
        return -1;
    }
#if 0
        /* set options */
        av_opt_set_int       (audio_convert_ctx, "in_channel_count",   pCodecCtx->channels,       0);
        av_opt_set_int       (audio_convert_ctx, "in_sample_rate",     pCodecCtx->sample_rate,    0);
        av_opt_set_sample_fmt(audio_convert_ctx, "in_sample_fmt",      pCodecCtx->sample_fmt, 0);
        av_opt_set_int       (audio_convert_ctx, "out_channel_count",  out_nb_channels,       0);
        av_opt_set_int       (audio_convert_ctx, "out_sample_rate",   out_sample_rate,    0);
        av_opt_set_sample_fmt(audio_convert_ctx, "out_sample_fmt",     out_sample_fmt,     0);

    /* initialize the resampling context */
        if ((ret = swr_init(audio_convert_ctx)) < 0) {
            fprintf(stderr, "Failed to initialize the resampling context\n");
            exit(1);
        }
#else

    audio_convert_ctx = swr_alloc_set_opts(audio_convert_ctx, out_channel_layout, out_sample_fmt,\
                                           out_sample_rate,in_channel_layout, \
                                           pCodecCtx->sample_fmt, pCodecCtx->sample_rate, 0, NULL);
    if(audio_convert_ctx == NULL) {
        printf("Could not swr_alloc_set_opts\n");
        return -1;
    }
     if ((ret = swr_init(audio_convert_ctx)) < 0) {
            fprintf(stderr, "Failed to initialize the resampling context\n");
            exit(1);
        }
#endif

    int frameCnt = 0;
    FILE *fp_pcm = fopen(a_path,"wb+");

    while(1){
        if(av_read_frame(pFormatCtx, packet) >= 0){
        if(packet->stream_index == videoindex){
            ret = avcodec_send_packet(pCodecCtx, packet);
            if (ret >= 0) {
                while (avcodec_receive_frame(pCodecCtx, pAudioFrame) >= 0) {
                    swr_convert(audio_convert_ctx, &buffer, audio_size, (const uint8_t **)pAudioFrame->data, pAudioFrame->nb_samples);
                    frameCnt += 1;
                    fwrite(buffer,1,out_buffer_size,fp_pcm);
                    printf("write size = %d cnt =%d \n ",out_buffer_size,frameCnt);
                }
            }else{
                continue;
            }
        }
            av_packet_unref(packet);
        }
    }
    fclose(fp_pcm);
    swr_free(&audio_convert_ctx);
    av_free(buffer);
    //av_free(out_buffer);
    av_free(pAudioFrame);
    avcodec_close(pCodecCtx);
    avformat_close_input(&pFormatCtx);

return 0;
}

