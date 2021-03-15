//
//  YHBaseRecord.h
//  RecordVideo
//
//  Created by huizai on 2019/6/24.
//  Copyright © 2019 huizai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AudioToolbox/AudioToolbox.h>

#include <libavcodec/avcodec.h>
#include <libavcodec/avcodec.h>
#include <libavfilter/avfilter.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
#include <libavfilter/buffersink.h>
#include <libavfilter/buffersrc.h>
#include <libavutil/imgutils.h>

NS_ASSUME_NONNULL_BEGIN



@interface YHBaseRecord : NSObject{
    NSArray   *YH_AV_CH_Layout_Selector;
}

- (BOOL) initParameters;

- (BOOL) startRecord: (NSString *)outPath
               withW: (int)width
               withH: (int)height;

- (void) stopRecord;

- (BOOL) copyVideo:  (UInt8*)pY
            withUV: (UInt8*)pUV
         withYSize: (int)yBs
        withUVSize: (int)uvBs;

- (BOOL) writeVideo: (int64_t) intPTS;

- (BOOL) copyAudio: (const char*) pcmBuffer
    withBufferSize: (int)pcmBufferSize
        withFrames: (int)numFrames;

- (BOOL) writeAudio: (int)numFrames
            withPTS: (int64_t)intPTS;
@end

NS_ASSUME_NONNULL_END
