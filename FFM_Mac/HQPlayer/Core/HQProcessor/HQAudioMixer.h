//
//  HQAudioMixer.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQAudioDescriptor.h"
#import "HQFrame.h"
#import "HQAudioFrame.h"
#import "HQCapacity.h"

/// 音频audioframe 合并
@interface HQAudioMixer : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


- (instancetype)initWith:(NSArray <HQTrack *> *)tracks weights:(NSArray <NSNumber *> *)weights;

@property (nonatomic,readonly,copy) NSArray <HQTrack *> *tracks;

@property (nonatomic,copy) NSArray <NSNumber *> *weights;

///
- (HQAudioFrame *)putFrame:(HQAudioFrame *)frame;

///
- (HQAudioFrame *)finish;

///
- (HQCapacity)capatity;

///
- (void)flush;

@end

