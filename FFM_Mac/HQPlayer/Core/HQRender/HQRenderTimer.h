//
//  HQRenderTimer.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/20.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HQRenderTimer : NSObject

- (instancetype)initWithHandler:(dispatch_block_t)handler;

@property (nonatomic,assign) NSTimeInterval timeInterval;
@property (nonatomic,assign) BOOL pause;

- (void)start;
- (void)stop;

@end

