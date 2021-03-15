//
//  HQAudioFormater.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQAudioFrame.h"
#import "HQAudioDescriptor.h"

/// 音频重采样
@interface HQAudioFormater : NSObject

@property (nonatomic,copy) HQAudioDescriptor *descriptor;

///
- (HQAudioFrame *)format:(HQAudioFrame *)frame;

///
- (HQAudioFrame *)finish;

///
- (void)flush;

@end
