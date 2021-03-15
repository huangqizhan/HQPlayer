//
//  HQVideoFrame.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/13.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQVideoFrame.h"
#import "HQSWScale.h"
#import "HQMapping.h"
#import "HQObjectPool.h"
#import "HQDescriptor+Internal.h"
#import "HQFrame+Interal.h"

@interface HQVideoFrame (){
    CVPixelBufferRef _pixelBuffer;
    int _linesize[HQFramePlaneCount];
    uint8_t *_data[HQFramePlaneCount];
}
@end

@implementation HQVideoFrame

+ (instancetype)frame{
    NSString *reuseName = @"HQVideoFrame";
    return [[HQObjectPool sharedPool] objectWithClass:[self class] reuseName:reuseName];
}

+ (instancetype)frameWithDescriptor:(HQVideoDescriptor *)descriptor{
    HQVideoFrame *frame = [self frame];
    int linesize[HQFramePlaneCount] = {0};
    uint8_t *data[HQFramePlaneCount] = {NULL};
    /// allocted data & linesize
    int success = av_image_alloc(data, linesize, descriptor.width, descriptor.height, descriptor.format, 1);
    if (success < 0) {
        return frame;
    }
    frame.core->width = descriptor.width;
    frame.core->height = descriptor.height;
    frame.core->format = descriptor.format;
    frame.core->sample_aspect_ratio = (AVRational){
      descriptor.sampleAspacrRatio.num,
      descriptor.sampleAspacrRatio.den
    };
    for (int i = 0; i < descriptor.numberOfPlanes; i++) {
        AVBufferRef *buffer = av_buffer_create(data[i], linesize[i], NULL, NULL, 0);
        frame.core->buf[i] = buffer;
        frame.core->data[i] = buffer->data;
        frame.core->linesize[i] = buffer->size;
    }
    return frame;
}
#pragma mark --- getter
- (HQMediaType )type{
    return HQMediaTypeVideo;
}
- (int *)linesize{
    return _linesize;
}
- (uint8_t **)data{
    return _data;
}
- (CVPixelBufferRef )pixelBuffer{
    return self->_pixelBuffer;
}
- (HQPLFImage *)image{
    HQRational rational = self->_descriptor.presentationSize;
    if (rational.den == 0 || rational.num == 0) {
        return nil;
    }
    HQVideoDescriptor *vdes = [[HQVideoDescriptor alloc] init];
    vdes.width = rational.num;
    vdes.height = rational.den;
    vdes.format = AV_PIX_FMT_RGB24;
    const uint8_t *src_data[HQFramePlaneCount] = {nil};
    uint8_t *des_data[HQFramePlaneCount] = {nil};
    int src_linesize[HQFramePlaneCount] = {0};
    int des_linesize[HQFramePlaneCount] = {0};
    if (self->_pixelBuffer) {
        CVReturn error = CVPixelBufferLockBaseAddress(self->_pixelBuffer, kCVPixelBufferLock_ReadOnly);
        if (error != kCVReturnSuccess) {
            return nil;
        }
        if (CVPixelBufferIsPlanar(self->_pixelBuffer)) {
            int planes = (int)CVPixelBufferGetPlaneCount(self->_pixelBuffer);
            for (int i = 0; i < planes; i++) {
                src_data[i] = CVPixelBufferGetBaseAddressOfPlane(self->_pixelBuffer, i);
                src_linesize[i] = (int)CVPixelBufferGetBytesPerRowOfPlane(self->_pixelBuffer, i);
            }
        }else{
            src_data[0] = CVPixelBufferGetBaseAddress(self->_pixelBuffer);
            src_linesize[0] = (int)CVPixelBufferGetBytesPerRow(self->_pixelBuffer);
        }
        CVPixelBufferUnlockBaseAddress(self->_pixelBuffer, kCVPixelBufferLock_ReadOnly);
    }else{
        for (int i = 0; i < HQFramePlaneCount; i++) {
            AVFrame *frame = self.core;
            src_data[i] = frame->data[i];
            src_linesize[i] = frame->linesize[i];
        }
    }
    if (!src_data[0] || !src_linesize[0]) {
        return nil;
    }
    HQSWScale *swsContext = [[HQSWScale alloc] init];
    swsContext.inputDescriptor = self->_descriptor;
    swsContext.outputDescriptor = vdes;
    if (![swsContext open]) {
        return nil;
    }
    /// alloc des_data & des_linesize
    BOOL success = av_image_alloc(des_data, des_linesize, vdes.width, vdes.height, vdes.format, 1);
    if (!success) {
        av_freep(des_data);
        return nil;
    }

    success = [swsContext convert:src_data inputLinesize:src_linesize outputData:des_data outputLinesize:des_linesize];
    if (!success) {
        av_freep(des_data);
    }
    HQPLFImage *image = (HQPLFImageWithRGBData(des_data[0], des_linesize[0], vdes.width, vdes.height));
    av_freep(des_data);
    return image;
}
#pragma mark --- HQData
- (void)clear{
    [super clear];
    for (int i = 0; i < HQFramePlaneCount; i++) {
        self->_data[i] = nil;
        self->_linesize[i] = 0;
    }
    self->_descriptor = nil;
    self->_pixelBuffer = nil;
}
- (void)fill{
    [super fill];
    [self fillData];
}
- (void)fillWithFrame:(HQFrame *)frame{
    [super fillWithFrame:frame];
    HQVideoFrame *videoFrame = (HQVideoFrame *)frame;
    self->_pixelBuffer = videoFrame->_pixelBuffer;
    self->_descriptor = videoFrame->_descriptor.copy;
    for (int i = 0; i < HQFramePlaneCount; i++) {
        self->_data[i] = videoFrame->_data[i];
        self->_linesize[i] = videoFrame->_linesize[i];
    }
}
- (void)fillWithTimeStamp:(CMTime)timeStamp decodeTimeStamp:(CMTime)decodeTimeStamp duration:(CMTime)duration{
    [super fillWithTimeStamp:timeStamp decodeTimeStamp:decodeTimeStamp duration:duration];
    [self fillData];
}
- (void)fillData{
    AVFrame *frame = self.core;
    self->_descriptor = [[HQVideoDescriptor alloc] initWithFrame:frame];
    if (frame->format == AV_PIX_FMT_VIDEOTOOLBOX) {
        self->_pixelBuffer = (CVPixelBufferRef)(frame->data[3]);
        self->_descriptor.cv_format = CVPixelBufferGetPixelFormatType(self->_pixelBuffer);
    }
    for (int i = 0; i < HQFramePlaneCount; i++) {
        self->_data[i] = frame->data[i];
        self->_linesize[i] = frame->linesize[i];
    }
}
@end
