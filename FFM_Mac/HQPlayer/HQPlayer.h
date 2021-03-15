//
//  HQPlayer.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPlayerHeader.h"

#pragma mark --- NotificationName

HQPLAYER_EXTERN NSString *const  HQPlayerDidChangeInfosNotification;

HQPLAYER_EXTERN NSString *const HQPlayerTimeinfoUserInfoKey;

HQPLAYER_EXTERN NSString *const HQPlayerStateInfoUserInfoKey;

HQPLAYER_EXTERN NSString *const HQPlayerInfoActionUserInfoKey;


@interface HQPlayer : NSObject

@property (nonatomic,strong) HQOptions *options;

- (NSError *)error;

- (HQTimeInfo)timeInfo;

- (HQStateInfo)stateInfo;

- (BOOL)stateInfo:(HQStateInfo *)stateInfo timeInfo:(HQTimeInfo *)timeInfo error:(NSError **)error;

@end

#pragma mark --- item

@interface HQPlayer ()

- (HQPlayerItem *)currentItem;

@property (nonatomic,copy) HQHandler readyHanler;

- (BOOL)replaceWithUrl:(NSURL *)url;

- (BOOL)replaceWithAsset:(HQAsset *)asset;

- (BOOL)replaceWithItem:(HQPlayerItem *)item;

@end



#pragma mark --- 回放
@interface HQPlayer ()

@property (nonatomic) Float64 rate;

@property (nonatomic,assign) BOOL wantsToPlay;


#if HQCPLATFORM_TARGET_OS_IPHONE_OR_TV

@property (nonatomic) BOOL pausesWhenInterrupted;

@property (nonatomic) BOOL pausesWhenEnteredBackground;

@property (nonatomic) BOOL pausesWhenEnteredBackgroundIfNoAudioTrack;

#endif

- (BOOL)play;

- (BOOL)pause;

- (BOOL)seekable;

- (BOOL)seekToTime:(CMTime)time;

- (BOOL)seekToTime:(CMTime)time result:(HQSeekResult)result;

- (BOOL)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter result:(HQSeekResult)result;

@end


#pragma mark --- render

@interface HQPlayer ()

- (HQAudioRender *)audioRenderer;

- (HQVideoRender *)videoRenderer;

@end

#pragma mark --- info

@interface HQPlayer ()

+ (HQTimeInfo)timeInfoFromUserInfo:(NSDictionary *)userInfo;

+ (HQStateInfo)stateInfoFromUserInfo:(NSDictionary *)userInfo;

+ (HQInfoAction)infoActionFromUserInfo:(NSDictionary *)userInfo;

@property (nonatomic) HQInfoAction actionMask;

@property (nonatomic) NSTimeInterval minimumTimeInfoInterval;

@property (nonatomic, strong) NSOperationQueue *notificationQueue;

@end

