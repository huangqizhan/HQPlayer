//
//  HQDecoderOptions.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQDecoderOptions.h"
#import "HQVideoRender.h"
#import "HQAudioRender.h"
#import "HQMapping.h"


@implementation HQDecoderOptions

- (id)copyWithZone:(NSZone *)zone{
    HQDecoderOptions *one = [HQDecoderOptions new];
    one->_options = [self->_options copy];
    one->_threadsAuto = self->_threadsAuto;
    one->_refcountedFrames = self->_refcountedFrames;
    one->_hardwareDecodeH264 = self->_hardwareDecodeH264;
    one->_hardwareDecodeH265 = self->_hardwareDecodeH265;
    one->_preferredPixelFormat = self->_preferredPixelFormat;
    one->_supportedPixelFormats = [self->_supportedPixelFormats copy];
    one->_supportedAudioDescriptors = [self->_supportedAudioDescriptors copy];
    one->_resetFrameRate = self->_resetFrameRate;
    one->_preferredFrameRate = self->_preferredFrameRate;
    return one;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self->_options = nil;
        self->_threadsAuto = YES;
        self->_refcountedFrames = YES;
        self->_hardwareDecodeH264 = YES;
        self->_hardwareDecodeH265 = YES;
        self->_preferredPixelFormat = HQPixelFormatFFM2AV(AV_PIX_FMT_NV12);
        self->_supportedPixelFormats = [HQVideoRender supportedPixelFormats];
        self->_supportedAudioDescriptors = @[[HQAudioRender supportedAudioDescriptor]];
        self->_resetFrameRate = NO;
        self->_preferredFrameRate = CMTimeMake(1, 20);
    }
    return self;
}

@end
