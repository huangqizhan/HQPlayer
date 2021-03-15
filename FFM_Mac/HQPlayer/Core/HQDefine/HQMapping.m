//
//  HQMapping.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/7.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMapping.h"


// 填充模式转换 HQ <-> Metal
HQMetalViewportMode HQScaling2ViewPort(HQScalingMode mode){
    switch (mode) {
        case HQScalingModeResize:
            return HQMetalViewportModeResize;
        case HQScalingModeResizeAspect:
            return HQMetalViewportModeResizeAspect;
        case HQScalingModeResizeAspectFill:
            return HQMetalViewportModeResizeAspectFill;
    }
    return HQMetalViewportModeResizeAspect;
}
HQScalingMode HQMeatalViewPortModel2Scaling(HQMetalViewportMode mode){
    switch (mode) {
        case HQMetalViewportModeResize:
            return HQScalingModeResize;
        case HQMetalViewportModeResizeAspect:
            return HQScalingModeResizeAspect;
        case HQMetalViewportModeResizeAspectFill:
            return HQScalingModeResizeAspectFill;
    }
    return HQScalingModeResizeAspect;
}
// 媒体类型转换 FFM <->HQ
HQMediaType HQMediaTypeFFM2HQ(enum AVMediaType mediaType){
    switch (mediaType) {
        case AVMEDIA_TYPE_AUDIO:
            return HQMediaTypeAudio;
        case AVMEDIA_TYPE_VIDEO:
            return HQMediaTypeVideo;
        case AVMEDIA_TYPE_SUBTITLE:
            return HQMediaTypeSubtitle;
        default:
            return HQMediaTypeUnknown;
    }
}
enum AVMediaType HQMediaType2FFM(HQMediaType mediaType){
    switch (mediaType) {
        case HQMediaTypeAudio:
            return AVMEDIA_TYPE_AUDIO;
        case HQMediaTypeVideo:
            return AVMEDIA_TYPE_VIDEO;
        case HQMediaTypeSubtitle:
            return AVMEDIA_TYPE_SUBTITLE;
        default:
            return AVMEDIA_TYPE_UNKNOWN;
    }
}
// 像素格式转换 FFM <-> AV
OSType HQPixelFormatFFM2AV(enum AVPixelFormat format){
    switch (format) {
        case AV_PIX_FMT_YUV420P:
            return kCVPixelFormatType_420YpCbCr8Planar;
        case AV_PIX_FMT_UYVY422:
            return kCVPixelFormatType_422YpCbCr8;
        case AV_PIX_FMT_BGRA:
            return kCVPixelFormatType_32BGRA;
        case AV_PIX_FMT_NV12:
            return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        default:
            return 0;
    }
    return 0;
}
enum AVPixelFormat HQPixelFormatAV2FFM(OSType format){
    switch (format) {
        case kCVPixelFormatType_420YpCbCr8Planar:
            return AV_PIX_FMT_YUV420P;
        case kCVPixelFormatType_422YpCbCr8:
            return AV_PIX_FMT_UYVY422;
        case kCVPixelFormatType_32BGRA:
            return AV_PIX_FMT_BGRA;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            return AV_PIX_FMT_NV12;
        default:
            return AV_PIX_FMT_NONE;
    }
    return AV_PIX_FMT_NONE;
}

// FFM <-> NS
AVDictionary *HQDictionaryNS2FFM(NSDictionary *dictionary){
    __block AVDictionary *ret = NULL;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            av_dict_set_int(&ret, [key UTF8String], [obj integerValue], 0);
        }else if ([obj isKindOfClass:[NSString class]]){
            av_dict_set(&ret, [key UTF8String], [obj UTF8String], 0);
        }
    }];
    return ret;
}
NSDictionary *HQDictionaryFFM2NS(AVDictionary *dictionary){
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    AVDictionaryEntry *entry = NULL;
    while ((entry = av_dict_get(dictionary, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        NSString *key = [NSString stringWithUTF8String:entry->key];
        NSString *value = [NSString stringWithUTF8String:entry->value];
        [ret setObject:value forKey:key];
    }
    if (ret.count == 0) {
        ret = nil;
    }
    return [ret copy];
}


