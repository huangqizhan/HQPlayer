//
//  HQCodecContext.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQCodecDescriptor.h"
#import "HQDecoderOptions.h"
#import "HQFrame.h"
#import "HQPacket.h"
#import "HQFFmpeg.h"


/// videotoolbox / ffmpeg   解码  
@interface HQCodecContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

///
- (instancetype)initWithTimebase:(AVRational)timebase codecpar:(AVCodecParameters *)codecpar  frameGenerator:(__kindof HQFrame *(^)(void))frameGenerator;

/// 解码参数
@property (nonatomic,strong) HQDecoderOptions *options;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (void)close;

/**
 *清空解码缓冲区 
 */
- (void)flush;

///解码
- (NSArray<__kindof HQFrame *> *)decode:(HQPacket *)packet;



@end
