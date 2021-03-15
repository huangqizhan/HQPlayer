//
//  HQAudioDescriptor.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/3.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAudioDescriptor.h"
#import "HQDescriptor+Internal.h"
#import "HQFFmpeg.h"

@implementation HQAudioDescriptor

- (id)copyWithZone:(NSZone *)zone{
    HQAudioDescriptor *one = [[HQAudioDescriptor alloc] init];
    one->_format = self->_format;
    one->_sampleRate = self->_sampleRate;
    one->_numberofChannels = self->_numberofChannels;
    one->_channelLayout = self->_channelLayout;
    return one;
}
- (instancetype)init{
    self = [super init];
    if (self) {
        self->_format = AV_SAMPLE_FMT_FLTP;
        self->_sampleRate = 44100;
        self->_numberofChannels = 2;
        self->_channelLayout = av_get_default_channel_layout(2);
    }
    return self;
}
- (instancetype)initWithFrame:(AVFrame *)frame{
    self = [super init];
    if (self) {
        self->_format = frame->format;
        self->_sampleRate = frame->sample_rate;
        self->_numberofChannels = frame->channels;
        self->_channelLayout = frame->channel_layout ? frame->channel_layout : av_get_default_channel_layout(frame->channels);
    }
    return self;
}

- (BOOL)isPlanar{
    return av_sample_fmt_is_planar(self->_format);
}
- (int)bytesPerSample{
    return av_get_bytes_per_sample(self->_format);
}
- (int)numberOfPlanes{
    return av_sample_fmt_is_planar(self->_format) ? self->_numberofChannels : 1;
}
- (int)linesize:(int)numberOfSamples{
    int lineSize = av_get_bytes_per_sample(self->_format) * numberOfSamples;
    lineSize *= av_sample_fmt_is_planar(self->_format) ? 1 : self->_numberofChannels;
    return lineSize;
}
- (BOOL)isEqualToDescriptor:(HQAudioDescriptor *)descriptor{
    return descriptor->_format == self->_format && descriptor->_sampleRate == self->_sampleRate && self->_channelLayout == descriptor->_channelLayout && self->_sampleRate == descriptor->_sampleRate;
}


@end
