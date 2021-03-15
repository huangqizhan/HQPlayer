//
//  HQAudioDescriptor.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/3.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>

 
@interface HQAudioDescriptor : NSObject <NSCopying>

/* 音频采样格式 */
@property (nonatomic) int format;

/* 音频采样率 */
@property (nonatomic) int sampleRate;

/* 声道 */
@property (nonatomic) int numberofChannels;

/* 音频布局  */
@property (nonatomic) uint64_t channelLayout;

/* 声道数据是否分开存放 */
- (BOOL)isPlanar;

/* 每个采样的字节 */
- (int)bytesPerSample;

/* 如果数据交错存放则是1条 如果是分开存放则是多条 */
- (int)numberOfPlanes;

/* 采样数对应的大小包括单声道或多声道 */
- (int)linesize:(int)numberOfSamples;

/* audiodescoptor is equal  */
- (BOOL)isEqualToDescriptor:(HQAudioDescriptor *)descriptor;

@end

 
