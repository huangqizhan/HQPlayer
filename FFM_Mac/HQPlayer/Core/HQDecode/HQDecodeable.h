//
//  HQDecodeable.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDecoderOptions.h"
#import "HQPacket.h"
#import "HQFrame.h"

@protocol HQDecodeable <NSObject>

/// 解码参数
@property (nonatomic) HQDecoderOptions *options;


/// 解码
- (NSArray <__kindof HQFrame *> *)decode:(HQPacket *)pkt;


/// finish
- (NSArray <__kindof HQFrame *> *)finish;


/// flush
- (void)flush;

@end

