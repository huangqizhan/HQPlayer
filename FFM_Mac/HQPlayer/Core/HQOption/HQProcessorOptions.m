//
//  HQProcessorOptions.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQProcessorOptions.h"
#import "HQVideoProcessor.h"
#import "HQAudioProcessor.h"

@implementation HQProcessorOptions

- (id)copyWithZone:(NSZone *)zone{
    HQProcessorOptions *one = [[HQProcessorOptions alloc] init];
    one->_audioClass = self->_audioClass;
    one->_videoClass = self->_videoClass;
    return one;
}
- (instancetype)init{
    self = [super init];
    if (self) {
        self->_audioClass = [HQAudioProcessor class];
        self->_videoClass = [HQVideoProcessor class];
    }
    return self;
}

@end
