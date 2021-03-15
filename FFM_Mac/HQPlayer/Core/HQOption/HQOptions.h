//
//  HQOptions.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDemuxerOptions.h"
#import "HQDecoderOptions.h"
#import "HQProcessorOptions.h"

@interface HQOptions : NSObject <NSCopying> 


+ (instancetype)shareOptions;

/// 解复用
@property (nonatomic,strong) HQDemuxerOptions *demuxer;
/// 解码
@property (nonatomic,strong) HQDecoderOptions *decoder;
/// 
@property (nonatomic,strong) HQProcessorOptions *processor;


@end

