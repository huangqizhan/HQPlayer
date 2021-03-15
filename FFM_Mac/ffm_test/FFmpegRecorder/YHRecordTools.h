////
////  YHRecordTools.h
////  RecordVideo
////
////  Created by huizai on 2019/5/24.
////  Copyright © 2019 huizai. All rights reserved.

////

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//#import "YHNAVRecord.h"
#import "YHAVRecord.h"


@interface YHRecordTools : NSObject

+ (BOOL) WriteVideoData:(uint8_t *)rawBytesForImage andSize:(CGSize)imageSize withRecord:(YHBaseRecord*)recorder withPTS:(int64_t)pts;

+ (BOOL) WriteVideoData:(CVPixelBufferRef) pixelBuffer withRecord:(YHBaseRecord*) recorder withPTS:(int64_t)pts;

+ (BOOL) WriteAudioData:(CMSampleBufferRef) pixelBuffer withRecord:(YHBaseRecord*) recorder;

@end

