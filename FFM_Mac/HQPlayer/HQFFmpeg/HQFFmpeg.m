//
//  HQFFmpeg.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQFFmpeg.h"

static void HQFFmpegLogCallback(void * context, int level, const char * format, va_list args){
//    NSString * message = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:args];
//    NSLog(@"HQFFLog : %@", message);
}

void HQFFmpegSetupIfNeeded(void){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        av_log_set_callback(HQFFmpegLogCallback);
        avformat_network_init();
    });
}
