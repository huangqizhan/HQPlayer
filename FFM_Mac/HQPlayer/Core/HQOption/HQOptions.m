//
//  HQOptions.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQOptions.h"

@implementation HQOptions

- (id)copyWithZone:(NSZone *)zone{
    HQOptions *one = [HQOptions new];
    one->_decoder = [self->_decoder copy];
    one->_demuxer = [self->_demuxer copy];
    one->_processor = [self->_processor copy];
    return one;
}
+ (instancetype)shareOptions{
    static HQOptions *options = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [[HQOptions alloc] init];
    });
    return options;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self->_decoder = [HQDecoderOptions new];
        self->_demuxer = [HQDemuxerOptions new];
        self->_processor = [HQProcessorOptions new];
    }
    return self;
}

@end
