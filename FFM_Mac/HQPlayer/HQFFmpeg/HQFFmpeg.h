//
//  HQFFmpeg.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>
#import <libavutil/imgutils.h>
#import <libswresample/swresample.h>
#import <libswscale/swscale.h>
//#import <libpostproc/postprocess.h>
#import <libavdevice/avdevice.h>
#import <libswscale/swscale.h>
#import <libavfilter/avfilter.h>
 
   
void HQFFmpegSetupIfNeeded(void);

