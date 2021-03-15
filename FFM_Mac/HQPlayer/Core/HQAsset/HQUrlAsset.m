//
//  HQUrlAsset.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQUrlAsset.h"
#import "HQAsset+Interal.h"
#import "HQUrlDemuxer.h"

@implementation HQUrlAsset

- (id)copyWithZone:(NSZone *)zone{
    HQUrlAsset *one = [super copyWithZone:zone];
    one->_URL = self->_URL.copy;
    return one;
}

- (instancetype)initWithURL:(NSURL *)URL{
    self = [super init];
    if (self) {
        self->_URL = URL.copy;
    }
    return self;
}

- (id<HQDemuxable>)newDemuxer{
    return [[HQUrlDemuxer alloc] initWithURL:self->_URL];
}
@end
