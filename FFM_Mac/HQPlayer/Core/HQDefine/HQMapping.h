//
//  HQMapping.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/7.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQVideoRender.h"
#import "HQMetalViewPort.h"
#import "HQFFmpeg.h"
#import "HQDefine.h"
// 填充模式转换 HQ <-> Metal
HQMetalViewportMode HQScaling2ViewPort(HQScalingMode model);
HQScalingMode HQMeatalViewPortModel2Scaling(HQMetalViewportMode model);

// 媒体类型转换 FFM <->HQ
HQMediaType HQMediaTypeFFM2HQ(enum AVMediaType mediaType);
enum AVMediaType HQMediaType2FFM(HQMediaType mediaType);

// 像素格式转换 FFM <-> AV
OSType HQPixelFormatFFM2AV(enum AVPixelFormat formar);
enum AVPixelFormat HQPixelFormatAV2FFM(OSType format);

// FFM <-> NS
NSDictionary *HQDictionaryFFM2NS(AVDictionary *dictionary);
AVDictionary *HQDictionaryNS2FFM(NSDictionary *dictionary);


