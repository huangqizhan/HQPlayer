//
//  HQClock.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 /// 创建主时钟
 CMTimebaseCreateWithMasterClock();
 /// 设置主时基时间
 CMTimebaseSetRateAndAnchorTime();

 /// 在主时基的基础上创建音频时基
 CMTimebaseCreateWithMasterTimebase();
 /// 在主时基的基础上创建视频时基
 CMTimebaseCreateWithMasterTimebase();
 
 /// 获取主时基时间
 CMTime playbackTime = CMTimebaseGetTime(self->_playtimebase);
 /// 设置子时基到具体的时间/及运行速率
 CMTimebaseSetRateAndAnchorTime(self->_audioTimeBase, 0.0, kCMTimeZero, playbackTime);
 CMTimebaseSetRateAndAnchorTime(self->_videoTimeBase, 0.0, kCMTimeZero, playbackTime);
 
 
 同时钟原理类似
 
 */

/// 时钟  用来同步音视频  (以时钟为驱动 以音频为时间标准  来做音视频的同步 )

@interface HQClock : NSObject


@end



