//
//  HQRender+Interal.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/20.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQAudioRender.h"
#import "HQVideoRender.h"
#import "HQReanderable.h"
#import "HQAudioDescriptor.h"
#import "HQClock.h"

@interface HQAudioRender ()<HQRenderable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


- (instancetype)initWithClock:(HQClock *)clock;

@property (nonatomic,readonly,copy ) HQAudioDescriptor *descriptor;

@property (nonatomic) Float64 rate;


@end





@interface HQVideoRender ()<HQRenderable>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


- (instancetype)initWithClock:(HQClock *)clock;

@property (nonatomic) Float64 rate;


@end
