//
//  HQPacket+Internal.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/3.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPacket.h"
#import "HQFFmpeg.h"
#import "HQCodecDescriptor.h"


@interface HQPacket ()

+ (instancetype)packet;

@property (nonatomic,readonly) AVPacket *core;

@property (nonatomic,strong) HQCodecDescriptor *codecDescriptor;

- (void)fill;

@end

