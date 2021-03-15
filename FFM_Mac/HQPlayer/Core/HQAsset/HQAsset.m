//
//  HQAsset.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAsset.h"
#import "HQAsset+Interal.h"
#import "HQUrlAsset.h"

@implementation HQAsset

- (id)copyWithZone:(NSZone *)zone{
    HQAsset *asset = [[self.class alloc] init];
    return asset;
}
+ (instancetype)assetWithUrl:(NSURL *)url{
    return [[HQUrlAsset alloc] initWithURL:url];
}

- (id<HQDemuxable>)newDemuxer{
    NSAssert(NO, @"please use subclass");
    return nil;
}



@end
