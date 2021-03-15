//
//  HQMetalModel.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/12.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMetalModel.h"

@implementation HQMetalModel

- (instancetype)initWithDevice:(id<MTLDevice>)device{
    self = [super init];
    if (self) {
        self.device = device;
    }
    return self;
}

@end
