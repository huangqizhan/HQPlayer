//
//  HQMetalRenderPipeline.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/13.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMetalRenderPipeline.h"

@implementation HQMetalRenderPipeline
- (instancetype)initWithDevice:(id<MTLDevice>)device library:(id)library{
    self = [super init];
    if (self) {
        self.device = device;
        self.library = library;
    }
    return self;
}

@end
