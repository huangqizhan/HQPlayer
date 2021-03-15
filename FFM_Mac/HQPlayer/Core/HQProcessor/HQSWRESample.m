//
//  HQSWRESample.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQSWRESample.h"
#import "HQFFmpeg.h"
#import "HQFrame.h"


@interface HQSWRESample (){
    AVBufferRef *_buffer[HQFramePlaneCount];
}

@property (nonatomic) struct SwrContext *swrContext;

@end

@implementation HQSWRESample

- (void)dealloc{
    if (self->_swrContext) {
        swr_free(&self->_swrContext);
        self->_swrContext = nil;
    }
    for (int i = 0; i < HQFramePlaneCount; i++) {
        av_buffer_unref(&self->_buffer[i]);
        self->_buffer[i] = nil;
    }
}
- (BOOL)open{
    if (self->_outputDescriptor == nil || self->_inputDescriptor == nil) {
        return NO;
    }
    
    self->_swrContext = swr_alloc_set_opts(NULL, self->_outputDescriptor.channelLayout, self->_outputDescriptor.format, self->_outputDescriptor.sampleRate, self->_inputDescriptor.channelLayout, self->_inputDescriptor.format, self->_inputDescriptor.sampleRate, 0, NULL);
    if (swr_init(self->_swrContext) < 0) {
        return NO;
    }
    return YES;
}
- (int)write:(uint8_t **)data nb_samples:(int)nb_samples{
    int numberofPlanes = self->_outputDescriptor.numberOfPlanes;
    int numberofsamples = swr_get_out_samples(self->_swrContext, nb_samples);
    int linesize = [self->_outputDescriptor linesize:numberofsamples];
    uint8_t *out_data[HQFramePlaneCount] = {NULL};
    for (int i = 0; i < numberofPlanes; i++) {
        if (!self->_buffer[i] || self->_buffer[i]->size < linesize) {
            av_buffer_realloc(&self->_buffer[i], linesize);
        }
        out_data[i] = self->_buffer[i]->data;
    }
    return swr_convert(self->_swrContext, out_data, numberofsamples, (const uint8_t **)data, nb_samples);
}
- (int)read:(uint8_t **)data nb_samples:(int)nb_samples{
    int numberofPlanes = self->_outputDescriptor.numberOfPlanes;
    int linesize = [self->_outputDescriptor linesize:nb_samples];
    for (int i = 0; i < numberofPlanes; i++) {
        memcpy(data[i], self->_buffer[i]->data, linesize);
    }
    return nb_samples;
}

- (int)delay{
    int64_t delay = swr_get_delay(self->_swrContext, self->_outputDescriptor.sampleRate);
    NSAssert(delay < INT32_MAX, @"Invalid ");
    return (int)delay;
}

@end
