//
//  HQTrackSelection.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQTrack.h"

#warning =========
typedef NS_OPTIONS(NSUInteger, HQTrackSelectionAction) {
    HQTrackSelectionActionTracks  = 1 << 0,
    HQTrackSelectionActionWeights = 1 << 1,
};

@interface HQTrackSelection : NSObject <NSCopying>


/*!
 @property tracks
 @abstract
    Provides array of SGTrackSelection tracks.
 */
@property (nonatomic, copy) NSArray<HQTrack *> *tracks;

/*!
 @property weights
 @abstract
    Provides array of SGTrackSelection weights.
 */
@property (nonatomic, copy) NSArray<NSNumber *> *weights;


@end
