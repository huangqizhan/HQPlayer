//
//  HQAudioPlayer.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/20.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class HQAudioPlayer;

@protocol HQAudioPlayerDelegate <NSObject>

/// 获取音频渲染数据
/// @param player player
/// @param timeStamp pts
/// @param data pcm data
/// @param numberFrames numberFrames
- (void)audioPlayer:(HQAudioPlayer *)player render:(const AudioTimeStamp *)timeStamp data:(AudioBufferList *)data numberOfFrames:(UInt32)numberFrames;

@optional;


/// 将要渲染
/// @param player player
/// @param timestamp pts
- (void)audioPlayer:(HQAudioPlayer *)player willRender:(const AudioTimeStamp *)timestamp;


/// 已经渲染
/// @param player player
/// @param timestamp pts 
- (void)audioPlayer:(HQAudioPlayer *)player didRender:(const AudioTimeStamp *)timestamp;

@end

@interface HQAudioPlayer : NSObject

/**
 *  Delegate.
 */
@property (nonatomic, weak) id<HQAudioPlayerDelegate> delegate;

/**
 *  倍速
 */
@property (nonatomic) float rate;

/**
 *  音调(频率)
 */
@property (nonatomic) float pitch;

/**
 *  音量
 */
@property (nonatomic) float volume;

/**
 *  ASBD.
 */
@property (nonatomic) AudioStreamBasicDescription asbd;

/**
 *  Playback.
 */
- (BOOL)isPlaying;

/**
 *  Play.
 */
- (void)play;

/**
 *  Pause.
 */
- (void)pause;

/**
 *  Flush.
 */
- (void)flush;


@end

