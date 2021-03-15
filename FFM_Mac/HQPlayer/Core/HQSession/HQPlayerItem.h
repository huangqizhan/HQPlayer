//
//  HQPlayerItem.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/7/1.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQTrackSelection.h"
#import "HQTrack.h"
#import "HQAsset.h"

@interface HQPlayerItem : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;


- (instancetype)initWithAsset:(HQAsset *)asset;

@property (nonatomic,readonly,copy) NSError *error;

@property (nonatomic,readonly,copy) NSArray <HQTrack *> *tracks;

@property (nonatomic,readonly,copy) NSDictionary *metaData;

@property (nonatomic,readonly) CMTime duration;

@property (nonatomic,readonly,copy) HQTrackSelection *audioSelection;

- (void)setAudioSelection:(HQTrackSelection *)audioSelection action:(HQTrackSelectionAction)action;

@property (nonatomic,readonly,copy) HQTrackSelection *videoSelection;

- (void)setVideoSelection:(HQTrackSelection *)videoSelection action:(HQTrackSelectionAction)action;



@end




