//
//  HQSWScale.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/14.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQVideoDescriptor.h"

/// 视频帧的处理
@interface HQSWScale : NSObject

+ (BOOL)isSupportedInputFormat:(int)format;

+ (BOOL)isSupportedOutputFormat:(int)format;

@property (nonatomic,copy) HQVideoDescriptor *inputDescriptor;

@property (nonatomic,copy) HQVideoDescriptor *outputDescriptor;

/// SWS_FAST_BILINEAR
@property (nonatomic) int flags;


- (BOOL)open;


- (int)convert:(const uint8_t * const [])inputData inputLinesize:(const int[])inputLinesize outputData:(uint8_t * const [])outputData outputLinesize:(const int[])outputLinesize;

@end


