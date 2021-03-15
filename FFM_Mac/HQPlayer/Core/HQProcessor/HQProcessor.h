//
//  HQProcessor.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQTrackSelection.h"
#import "HQCapacity.h"
#import "HQFrame.h"

@protocol HQProcessor <NSObject>

///
- (void)setSelection:(HQTrackSelection *)selection action:(HQTrackSelectionAction)action;

///
- (__kindof HQFrame *)putFrame:(__kindof HQFrame *)frame;

///
- (__kindof HQFrame *)finish;

///
- (HQCapacity)capatity;

///
- (void)flush;

///
- (void)close;

@end
