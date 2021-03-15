//
//  HQVideoDescriptor.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/3.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDefine.h"
 
@interface HQVideoDescriptor : NSObject<NSCopying>

/* ffmpeg video format AVPixelFormat  */
@property (nonatomic) int format;

/*  CoreVideo video format   kCVPixelFormat */
@property (nonatomic) OSType cv_format;

/* 宽  */
@property (nonatomic) int width;

/* 高 */
@property (nonatomic) int height;

/* 宽高比  */
@property (nonatomic) HQRational sampleAspacrRatio;

/* 帧宽高 */
@property (nonatomic,readonly) HQRational frameSize;

/* 当前显示的 宽高   */
@property (nonatomic,readonly) HQRational presentationSize;

/* 如果数据交错存放则是1条 如果是分开存放则是多条 */
- (int)numberOfPlanes;

/* isequal  */
- (BOOL)isEqualToDescriptor:(HQVideoDescriptor *)descriptor;

@end

 
