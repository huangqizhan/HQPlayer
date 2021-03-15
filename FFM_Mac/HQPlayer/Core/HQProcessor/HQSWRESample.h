//
//  HQSWRESample.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQAudioDescriptor.h"

/// 音频重新采样 （有时不同的编解码器支持的音频格式不一样，原始采样的音频数据可能没法直接直接为编解码器支持  这就需要对不同的音频格式转换，需要重采样  ）
@interface HQSWRESample : NSObject


/// ouput / input
@property (nonatomic,copy) HQAudioDescriptor *inputDescriptor;
@property (nonatomic,copy) HQAudioDescriptor *outputDescriptor;

/**
 *
 */
- (BOOL)open;

/**
 * 写入数据
 */
- (int)write:(uint8_t **)data nb_samples:(int)nb_samples;

/**
 * 读出数据
 */
- (int)read:(uint8_t **)data nb_samples:(int)nb_samples;

/**
 * 输出的延迟
 */
- (int)delay;



@end
