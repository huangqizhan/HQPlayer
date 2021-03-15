//
//  HQAudioRender.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/6.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQAudioDescriptor.h"


@interface HQAudioRender : NSObject

/// 
+ (HQAudioDescriptor *)supportedAudioDescriptor;

/// 音调
@property (nonatomic) Float64 pitch;
/// 音量
@property (nonatomic) Float64 volume;



@end

