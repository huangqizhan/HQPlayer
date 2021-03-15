//
//  rec_video.c
//  Media
//
//  Created by 黄麒展 on 2021/1/28.
//

#include "rec_video.h"
#include <unistd.h>
#include <libavdevice/avdevice.h>
#include <libavutil/avutil.h>
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
#include <libswscale/swscale.h>



//Show AVFoundation Device
void show_avfoundation_device(){
    AVFormatContext *pFormatCtx = avformat_alloc_context();
    AVDictionary* options = NULL;
    av_dict_set(&options,"list_devices","true",0);
    AVInputFormat *iformat = av_find_input_format("avfoundation");
    printf("==AVFoundation Device Info===\n");
    avformat_open_input(&pFormatCtx,"",iformat,&options);
    printf("=============================\n");
}
 
 
static AVFrame* create_frame11(int width ,int height){
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
int open_video_device(const char *yuv_path,const char *h_path){
 
    
    if (yuv_path == NULL || h_path == NULL) {
        return -1;
    }
    AVFormatContext   *pFormatCtx;
    int                videoindex;
    AVCodecContext    *pCodecCtx = NULL;
    AVCodec            *pCodec;
    int                 ret;

    av_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
    AVDictionary *option = NULL;

    //Open File
    //char filepath[]="src01_480x272_22.h265";
    //avformat_open_input(&pFormatCtx,filepath,NULL,NULL)
 
    //Register Device
    avdevice_register_all();
    //Windows

    show_avfoundation_device();
    //Mac
    AVInputFormat *ifmt = av_find_input_format("avfoundation");
    //Avfoundation
    
    /// AVCaptureSessionPreset320x240
    /// AVCaptureSessionPreset352x288
    ///AVCaptureSessionPreset640x480
    /// AVCaptureSessionPreset960x540
    /// AVCaptureSessionPreset1280x720
    /// AVCaptureSessionPreset1920x1080
    /// AVCaptureSessionPreset3840x2160
//
    /*
     /// 此处屏幕录制2880x1800
     //    av_dict_set(&option, "video_size", "2880x1800", 0);
     //    av_dict_set(&option, "framerate", "30", 0);
         av_dict_set(&option, "pixel_format", "nv12", 0);
         
     
         //[video]:[audio]
         if(avformat_open_input(&pFormatCtx,"1",ifmt,&option) != 0){
             printf("Couldn't open input stream.\n");
             return -1;
         }
     */
    
        av_dict_set(&option, "video_size", "3840x2160", 0);
        av_dict_set(&option, "framerate", "30", 0);
        av_dict_set(&option, "pixel_format", "nv12", 0);
        
        
        
        /// 此处屏幕录制2880x1800
        //[video]:[audio]
        if(avformat_open_input(&pFormatCtx,"0",ifmt,&option) != 0){
            printf("Couldn't open input stream.\n");
            return -1;
        }
    
    videoindex = -1;
    for(int i = 0; i < pFormatCtx->nb_streams; i++){
        AVStream *stream = pFormatCtx->streams[i];
        if(stream->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoindex = i;
            break;
        }
    }
    if(videoindex == -1){
        printf("Didn't find a video stream.\n");
        return -1;
    }
    
    if(avformat_find_stream_info(pFormatCtx,NULL)<0)
    {
        printf("Couldn't find stream information.\n");
        return -1;
    }
    pCodec = avcodec_find_decoder(pFormatCtx->streams[videoindex]->codecpar->codec_id);
    pCodecCtx = avcodec_alloc_context3(pCodec);
    
    avcodec_parameters_to_context(pCodecCtx, pFormatCtx->streams[videoindex]->codecpar);
//    pCodecCtx = pFormatCtx->streams[videoindex]->codec;
//    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    
    
    if (pCodec == NULL) {
        printf("find codec error \n");
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
    AVFrame *pFrame, *pFrameYUV;
    
    pFrame = create_frame11(pCodecCtx->width, pCodecCtx->height);
    
    pFrameYUV = create_frame11(pCodecCtx->width/4, pCodecCtx->height/4);
    
    AVPacket *packet=(AVPacket *)av_malloc(sizeof(AVPacket));
 
    FILE *fp_yuv=fopen(yuv_path,"wb+");

    if (pCodecCtx->width == 0 || pCodecCtx->height == 0) {
        printf("width height error\n");
        return -1;
    }
    struct SwsContext *img_convert_ctx;
    img_convert_ctx = sws_getContext(pFrame->width, pFrame->height, pFrame->format, pFrameYUV->width, pFrameYUV->height, pFrameYUV->format, SWS_FAST_BILINEAR, NULL, NULL, NULL);

//  img_convert_ctx = sws_getContext(frame->width, frame->height, frame->format, sw_frame->width, sw_frame->height, sw_frame->format, SWS_FAST_BILINEAR, NULL, NULL, NULL);

    if (img_convert_ctx == NULL) {
        printf("allco imgscalecontex error \n");
        return -1;
    }
    while (1) {
        ret = av_read_frame(pFormatCtx, packet);
            if(ret < -35){
                printf("code errpe -35 \n");
                continue;
            }
            if(ret >= 0){
                /// NV12         YYYYYYYYUVUV     8个像素    采集数据的格式
                /// YUV420p   YYYYYYYYUUVV    8个像素    编码数据的格式
                ///
                /// nv12 -> yuv420p
                int y_num = pCodecCtx->width * pCodecCtx->height;
                memcpy(pFrame->data[0], packet->data, y_num);
                for (int i = 0; i < y_num/4; i++) {
                    pFrame->data[1][i] = packet->data[y_num + i*2];
                    pFrame->data[2][i] = packet->data[y_num + i*2 + 1];
                }
//                fwrite(pFrame->data[0], 1, y_num, fp_yuv);
//                fwrite(pFrame->data[1], 1, y_num/4, fp_yuv);
//                fwrite(pFrame->data[2], 1, y_num/4, fp_yuv);
//                 sws_scale(img_convert_ctx, (const unsigned char* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height, pFrameYUV->data, pFrameYUV->linesize);

                int ty_num = pFrameYUV->width * pFrameYUV->height;
                sws_scale(img_convert_ctx, (const unsigned char* const*)pFrame->data, pFrame->linesize, 0, pFrame->height, pFrameYUV->data, pFrameYUV->linesize);
                

                fwrite(pFrameYUV->data[0], 1, ty_num, fp_yuv);
                fwrite(pFrameYUV->data[1], 1, ty_num/4, fp_yuv);
                fwrite(pFrameYUV->data[2], 1, ty_num/4, fp_yuv);
                
                printf("packet .size = %d width = %d height = %d \n",packet->size,pFrameYUV->width,pFrameYUV->height);
//                av_frame_unref(pFrame);
                fflush(fp_yuv);
                
//            }
        }
        av_packet_unref(packet);
    }
 
    sws_freeContext(img_convert_ctx);
 
#if OUTPUT_YUV420P
    fclose(fp_yuv);
#endif
 
 
    //av_free(out_buffer);
//    av_free(pFrameYUV);
    avcodec_close(pCodecCtx);
    avformat_close_input(&pFormatCtx);
 
    return 0;
}


//static int rec_status = 0;
//void set_status(int status){
//    rec_status = status;
//}



#pragma mark ------ video
//static void video_encode(AVCodecContext *codec_ctx,AVFrame *frame ,AVPacket *pkt,FILE *out_file){
//    if (frame == NULL) {
//        av_log(NULL, AV_LOG_DEBUG, "encode frame error \n");
//        return;
//    }
//    int ret = 0;
//    ret = avcodec_send_frame(codec_ctx, frame);
//    if (ret < 0) {
//        av_log(NULL, AV_LOG_DEBUG, "avcodec send frame error \n");
//        return;
//    }
//    while (ret >= 0) {
//        ret = avcodec_receive_packet(codec_ctx, pkt);
//        /// 从新开始 已经结束
//        if (ret == AVERROR(EAGAIN) || ret == AVERROR(AVERROR_EOF)) {
//            return;
//        }else if (ret < 0){
//            av_log(NULL, AV_LOG_DEBUG, "encode error \n");
//            exit(0);
//        }
//        fwrite(pkt->data, 1, pkt->size, out_file);
//        fflush(out_file);
//        av_packet_unref(pkt);
//    }
//}
///// 打开视频编码器
//static void open_video(int width, int height , AVCodecContext **enc_ctx){
////    AVCodec *codec = NULL;
////    codec = avcodec_find_decoder_by_name("libx264");
////    printf("codec.type = %d",codec->type);
//
//    AVCodec *codec = NULL;
//    codec = avcodec_find_encoder_by_name("libx264");
//    printf("codec.type = %d",codec->type);
//    if (codec == NULL) {
//        av_log(NULL, AV_LOG_DEBUG, "find codec error \n");
//        return;
//    }
//    *enc_ctx = avcodec_alloc_context3(codec);
//    if ((*enc_ctx) == NULL) {
//        av_log(NULL, AV_LOG_DEBUG, "alloc avcodec error \n");
//        return;
//    }
//#pragma mark ---- h264的 SPS PPS 参数
//    //// h264 的编码格式
//    (*enc_ctx)->profile = FF_PROFILE_H264_HIGH_444;
//    /// 编码格式的级别
//    (*enc_ctx)->level = 50;
//
//    /// 设置码率
//    (*enc_ctx)->bit_rate = 500000;     ///600kbps
////    (*enc_ctx)->rc_min_rate = 500000;
////    (*enc_ctx)->rc_max_rate = 500000;
////    (*enc_ctx)->rc_buffer_size= 500000;
//
//    /// 分辨率
//    (*enc_ctx)->width = 640; //不能改变分辩率大小
//    (*enc_ctx)->height = 480;
//    /// GOP
//    /// gop帧数
//    (*enc_ctx)->gop_size = 250;
//    /// gop内的I帧数
//    (*enc_ctx)->keyint_min = 25;   /// option
//
//    ///参考帧数量
//    (*enc_ctx)->max_b_frames = 3;   /// option
////    (*enc_ctx)->has_b_frames = 1;   /// option
//
//    (*enc_ctx)->refs = 3;           /// 参考帧数量
//
//    ///输入的YUV数据
//    (*enc_ctx)->pix_fmt = AV_PIX_FMT_YUV420P;
//
//
//
//
//    // 设置帧率
//    (*enc_ctx)->time_base = (AVRational){1,25};  /// 每帧的时长
//    (*enc_ctx)->framerate = (AVRational){25,1};  /// 帧率
//
////    (*enc_ctx)->flags|= AV_CODEC_FLAG_LOOP_FILTER;   // flags=+loop
////    (*enc_ctx)->me_cmp|= 1;                       // cmp=+chroma, where CHROMA = 1
////
////
////    (*enc_ctx)->me_subpel_quality = 7;   // subq=7
////    (*enc_ctx)->me_range = 16;   // me_range=16
////    (*enc_ctx)->i_quant_factor = 0.71; // i_qfactor=0.71
////    (*enc_ctx)->qcompress = 0; // qcomp=0.6
////    (*enc_ctx)->qmin = 51;   // qmin=10
////    (*enc_ctx)->qmax = 51;   // qmax=51
////    (*enc_ctx)->max_qdiff = 4;   // qdiff=4
////    (*enc_ctx)->trellis = 1; // trellis=1
//    /// 打开编码器
//    int ret = avcodec_open2(*enc_ctx, codec, NULL);
//    if (ret < 0) {
//        av_log(NULL, AV_LOG_DEBUG, "open codec faild \n");
//    }
//}
//
///// 创建frame
//static AVFrame* create_frame(int width ,int height){
//    AVFrame* frame = NULL;
//    int ret = 0;
//    frame = av_frame_alloc();
//    if (frame == NULL) {
//        av_log(NULL, AV_LOG_DEBUG, "alloc frame error \n");
//        goto FAILD;
//    }
//
//    frame->width = width;
//    frame->height = height;
//    frame->format = AV_PIX_FMT_YUV420P;
//
//    /// 创建buffer
//    ret = av_frame_get_buffer(frame, 32);
//    if (ret < 0) {
//        av_log(NULL, AV_LOG_DEBUG, "alloc frame buffer error \n");
//        goto FAILD;
//    }
//    return frame;
//FAILD:
//    if (frame) {
//        av_frame_free(&frame);
//    }
//    return NULL;

//}
