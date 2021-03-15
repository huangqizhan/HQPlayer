//
//  HQVideoDescriptor.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/3.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQVideoDescriptor.h"
#import "HQDescriptor+Internal.h"
#import "HQMapping.h"
#import "HQFFmpeg.h"

@implementation HQVideoDescriptor

- (id)copyWithZone:(NSZone *)zone{
    HQVideoDescriptor *one = [[HQVideoDescriptor alloc] init];
    one->_format = self->_format;
    one->_cv_format = self->_cv_format;
    one->_width = self->_width;
    one->_height = self->_height;
    one->_sampleAspacrRatio = self->_sampleAspacrRatio;
    return one;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self->_format = AV_PIX_FMT_NONE;
        self->_cv_format = HQPixelFormatFFM2AV(self->_format);
        self->_width = 0;
        self->_height = 0;
        self->_sampleAspacrRatio = (HQRational){0,0};
    }
    return self;
}
- (instancetype)initWithFrame:(AVFrame *)frame{
    self = [super init];
    if (self) {
        self->_format = frame->format;
        self->_cv_format = HQPixelFormatFFM2AV(self->_format);
        self->_width = frame->width;
        self->_height = frame->height;
        HQRational sampleRational = {frame->sample_aspect_ratio.num,frame->sample_aspect_ratio.den};
        self->_sampleAspacrRatio = sampleRational;
    }
    return self;
}

- (void)setFormat:(int)format{
    self->_format = format;
    self->_cv_format = HQPixelFormatFFM2AV(self->_format);
}
- (void)setCv_format:(OSType)cv_format{
    self->_cv_format = cv_format;
    self->_format = HQPixelFormatAV2FFM(cv_format);
}
- (HQRational)frameSize{
    return (HQRational){self->_width,self->_height};
}
- (HQRational)presentationSize{
    int width = self->_width;
    int height = self->_height;
    AVRational aspectRatio = {
        self->_sampleAspacrRatio.num,
        self->_sampleAspacrRatio.den,
    };
    if (av_cmp_q(aspectRatio, av_make_q(0, 1)) <= 0) {
        aspectRatio = av_make_q(1, 1);
    }
    aspectRatio = av_mul_q(aspectRatio, av_make_q(width, height));
    HQRational size1 = {width, av_rescale(width, aspectRatio.den, aspectRatio.num) & ~1};
    HQRational size2 = {av_rescale(height, aspectRatio.num, aspectRatio.den) & ~1, height};
    int64_t pixels1 = size1.num * size1.den;
    int64_t pixels2 = size2.num * size2.den;
    return (pixels1 > pixels2) ? size1 : size2;
}

- (int)numberOfPlanes{
    return av_pix_fmt_count_planes(self->_format);
}
- (BOOL)isEqualToDescriptor:(HQVideoDescriptor *)descriptor{
    if (!descriptor) {
        return NO;
    }
    return
    self->_format == descriptor->_format &&
    self->_cv_format == descriptor->_cv_format &&
    self->_width == descriptor->_width &&
    self->_height == descriptor->_height &&
    self->_sampleAspacrRatio.num == descriptor->_sampleAspacrRatio.num &&
    self->_sampleAspacrRatio.den == descriptor->_sampleAspacrRatio.den;
}
@end
