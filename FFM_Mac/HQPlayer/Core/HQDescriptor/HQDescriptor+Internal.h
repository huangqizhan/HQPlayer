//
//  HQDescriptor+Internal.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//
#import "HQFFmpeg.h"
#import "HQPacket.h"
#import "HQAudioDescriptor.h"
#import "HQVideoDescriptor.h"


@interface HQAudioDescriptor ()

- (instancetype)initWithFrame:(AVFrame *)frame;

@end


@interface HQVideoDescriptor ()

- (instancetype)initWithFrame:(AVFrame *)frame;


@end
