//
//  HQAudioFrame.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/13.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAudioFrame.h"
#import "HQFrame+Interal.h"
#import "HQObjectPool.h"
#import "HQDescriptor+Internal.h"

@interface HQAudioFrame (){
    int _linesize[HQFramePlaneCount];
    uint8_t *_data[HQFramePlaneCount];
}

@end

@implementation HQAudioFrame

+ (instancetype)frame{
    NSString *reuseName = @"HQAudioFrame";
    return [[HQObjectPool sharedPool] objectWithClass:[HQAudioFrame class] reuseName:reuseName];
}

+ (instancetype)frameWithDescriptor:(HQAudioDescriptor *)descriptor numberofSamples:(int)numofSamples{
    HQAudioFrame *frame = [self frame];
    frame.core->format = descriptor.format;
    frame.core->nb_samples = numofSamples;
    frame.core->sample_rate = descriptor.sampleRate;
    frame.core->channels = descriptor.numberofChannels;
    frame.core->channel_layout = descriptor.channelLayout;
    int samplesBytes = [descriptor linesize:numofSamples];
    for (int i = 0; i < descriptor.numberOfPlanes; i++) {
        uint8_t *date = av_malloc(samplesBytes);
        memset(date, 0, samplesBytes);
        AVBufferRef *buffer = av_buffer_create(date, samplesBytes, NULL, NULL, 0);
        frame.core->buf[i] = buffer;
        frame.core->data[i] = buffer->data;
        frame.core->linesize[i] = buffer->size;
    }
    return frame;
}

- (HQMediaType)type{
    return HQMediaTypeAudio;
}

- (int *)lineSize{
    return _linesize;
}
- (uint8_t **)data{
    return _data;
}

#pragma mark --- HQData
- (void)clear{
    [super clear];
    self->_numberOfSamples = 0;
    for (int i = 0 ; i < HQFramePlaneCount; i++) {
        self->_data[i] = NULL;
        self->_linesize[i] = 0;
    }
    self->_descriptor = nil;
}

- (void)fill{
    AVFrame *frame = self.core;
    AVRational rational = self.codeDescriptor.timebase;
    HQCodecDescriptor *cd = self.codeDescriptor;
    CMTime duration = CMTimeMake(frame->nb_samples, frame->sample_rate);
    CMTime timeStamp = CMTimeMake(frame->best_effort_timestamp *rational.num, rational.den);
    CMTime codeTime = CMTimeMake(frame->pkt_dts * rational.num, rational.den);
    duration = [cd convertDuration:duration];
    timeStamp = [cd convertDuration:timeStamp];
    codeTime = [cd convertTimeStamp:codeTime];
    [self fillWithTimeStamp:timeStamp decodeTimeStamp:codeTime duration:duration];
}
- (void)fillWithFrame:(HQFrame *)frame{
    [super fillWithFrame:frame];
    HQAudioFrame *audioFrame = (HQAudioFrame *)frame;
    self->_numberOfSamples = audioFrame->_numberOfSamples;
    self->_descriptor = audioFrame->_descriptor.copy;
    for (int i = 0; i < HQFramePlaneCount; i++) {
        self->_data[i] = audioFrame->_data[i];
        self->_linesize[i] = audioFrame->_linesize[i];
    }
}
- (void)fillWithTimeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp duration:(CMTime)duration{
    [super fillWithTimeStamp:timeStamp decodeTimeStamp:decodeTimeStamp duration:duration];
    AVFrame *frame = self.core;
    self->_numberOfSamples = frame->nb_samples;
    self->_descriptor = [[HQAudioDescriptor alloc] initWithFrame:frame];
    for (int i = 0; i < HQFramePlaneCount; i++) {
        self->_data[i] = frame->data[i];
        self->_linesize[i] = frame->linesize[i];
    }
}

@end
