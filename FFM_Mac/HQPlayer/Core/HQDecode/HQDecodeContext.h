//
//  HQDecodeContext.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDecoderOptions.h"
#import "HQCapacity.h"
#import "HQFrame.h"
#import "HQPacket.h"

///  解码上下文  包含多个 HQCodeContext 
@interface HQDecodeContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;


- (instancetype)initWithDecoderClass:(Class)decodeClass;


@property (nonatomic,copy) HQDecoderOptions *options;

/// dts
@property (nonatomic,readonly) CMTime decodeTimeStamp;


- (HQCapacity)capacity;

- (void)putPacket:(HQPacket *)packet;

/// 是否需要预解码 
- (BOOL)needPreDecode;

/// 视频packet 预解码
- (void)preDecode:(HQBlock)lock unlock:(HQBlock)unlock;

/// 解码
- (NSArray <__kindof HQFrame *> *)decode:(HQBlock)lock unlock:(HQBlock)unlock;


- (void)setNeedsFlush;

- (void)markAsFinshed;

- (void)destory;


@end

