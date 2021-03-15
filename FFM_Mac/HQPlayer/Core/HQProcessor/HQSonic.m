//
//  HQSonic.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQSonic.h"

@implementation HQSonic

- (instancetype)initWithDescriptor:(HQAudioDescriptor *)descriptor
{
    if (self = [super init]) {
//        self->_descriptor = [descriptor copy];
//        self->_speed = 1.0;
//        self->_pitch = 1.0;
//        self->_rate = 1.0;
//        self->_volume = 1.0;
    }
    return self;
}

- (void)dealloc
{
//    if (self->_sonic) {
//        sonicDestroyStream(self->_sonic);
//        self->_sonic = nil;
//    }
//    if (self->_buffer) {
//        av_buffer_unref(&self->_buffer);
//        self->_buffer = nil;
//    }
}

- (BOOL)open
{
//    if (!self->_sonic) {
//        int format = self->_descriptor.format;
//        if (format != AV_SAMPLE_FMT_U8 &&
//            format != AV_SAMPLE_FMT_U8P &&
//            format != AV_SAMPLE_FMT_S16 &&
//            format != AV_SAMPLE_FMT_S16P &&
//            format != AV_SAMPLE_FMT_FLT &&
//            format != AV_SAMPLE_FMT_FLTP) {
//            return NO;
//        }
//        int channels = self->_descriptor.numberOfChannels;
//        int sampleRate = self->_descriptor.sampleRate;
//        self->_sonic = sonicCreateStream(sampleRate, channels);
//        sonicSetSpeed(self->_sonic, self->_speed);
//        sonicSetPitch(self->_sonic, self->_pitch);
//        sonicSetRate(self->_sonic, self->_rate);
//        sonicSetRate(self->_sonic, self->_volume);
//    }
    return YES;
}

- (int)flush
{
//    if (!self->_sonic) {
//        return 0;
//    }
//    sonicFlushStream(self->_sonic);
//    return sonicSamplesAvailable(self->_sonic);
    return 0;
}

- (int)samplesInput
{
//    if (!self->_sonic) {
//        return 0;
//    }
//    return sonicSamplesInput(self->_sonic);
    return 0;
}

- (int)samplesAvailable
{
//    if (!self->_sonic) {
//        return 0;
//    }
//    return sonicSamplesAvailable(self->_sonic);
    return 0;
}

- (int)write:(uint8_t **)data nb_samples:(int)nb_samples
{
//    if (!self->_sonic) {
//        return 0;
//    }
//    void *samples = data[0];
//    int planes = self->_descriptor.numberOfPlanes;
//    if (planes > 1) {
//        int size = [self->_descriptor linesize:nb_samples] * planes;
//        if (!self->_buffer || self->_buffer->size < size) {
//            av_buffer_realloc(&self->_buffer, size);
//        }
//        samples = self->_buffer->data;
//    }
//    if (planes > 1) {
//        int bytes = self->_descriptor.bytesPerSample;
//        for (int i = 0; i < nb_samples; i++) {
//            for (int j = 0; j < planes; j++) {
//                memcpy(samples + (i * bytes * planes + j * bytes),
//                       data[j] + (i * bytes),
//                       bytes);
//            }
//        }
//    }
//    int format = self->_descriptor.format;
//    if (format == AV_SAMPLE_FMT_U8 ||
//               format == AV_SAMPLE_FMT_U8P) {
//        sonicWriteUnsignedCharToStream(self->_sonic, samples, nb_samples);
//    } else if (format == AV_SAMPLE_FMT_S16 ||
//               format == AV_SAMPLE_FMT_S16P) {
//        sonicWriteShortToStream(self->_sonic, samples, nb_samples);
//    } else if (format == AV_SAMPLE_FMT_FLT ||
//               format == AV_SAMPLE_FMT_FLTP) {
//        sonicWriteFloatToStream(self->_sonic, samples, nb_samples);
//    }
//    return sonicSamplesAvailable(self->_sonic);
    return 0;
}

- (int)read:(uint8_t **)data nb_samples:(int)nb_samples
{
//    if (!self->_sonic) {
//        return 0;
//    }
//    void *samples = data[0];
//    int planes = self->_descriptor.numberOfPlanes;
//    if (planes > 1) {
//        int size = [self->_descriptor linesize:nb_samples] * planes;
//        if (!self->_buffer || self->_buffer->size < size) {
//            av_buffer_realloc(&self->_buffer, size);
//        }
//        samples = self->_buffer->data;
//    }
//    int ret = 0;
//    int format = self->_descriptor.format;
//    if (format == AV_SAMPLE_FMT_U8 ||
//               format == AV_SAMPLE_FMT_U8P) {
//        ret = sonicReadUnsignedCharFromStream(self->_sonic, samples, nb_samples);
//    } else if (format == AV_SAMPLE_FMT_S16 ||
//               format == AV_SAMPLE_FMT_S16P) {
//        ret = sonicReadShortFromStream(self->_sonic, samples, nb_samples);
//    } else if (format == AV_SAMPLE_FMT_FLT ||
//               format == AV_SAMPLE_FMT_FLTP) {
//        ret = sonicReadFloatFromStream(self->_sonic, samples, nb_samples);
//    }
//    if (planes > 1) {
//        int bytes = self->_descriptor.bytesPerSample;
//        for (int i = 0; i < nb_samples; i++) {
//            for (int j = 0; j < planes; j++) {
//                memcpy(data[j] + (i * bytes),
//                       samples + (i * bytes * planes + j * bytes),
//                       bytes);
//            }
//        }
//    }
//    return ret;
    return 0;
}




@end
