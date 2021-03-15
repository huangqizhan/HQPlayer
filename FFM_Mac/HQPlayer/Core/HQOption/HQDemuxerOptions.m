//
//  HQDemuxerOptions.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQDemuxerOptions.h"

@implementation HQDemuxerOptions

- (id)copyWithZone:(NSZone *)zone{
    HQDemuxerOptions *one = [HQDemuxerOptions new];
    one->_options = [self->_options copy];
    return one;
}


- (instancetype)init{
    self = [super init];
    if (self) {
        self->_options = @{@"reconnect" : @(1),
                           @"user-agent" : @"HQPlayer",
                           @"timeout" : @(20 * 1000 * 1000)};
    }
    return self;
}
@end
