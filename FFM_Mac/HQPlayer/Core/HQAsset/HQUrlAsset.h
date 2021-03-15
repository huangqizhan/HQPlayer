//
//  HQUrlAsset.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAsset.h"
#import "HQMutableTrack.h"
/// URL媒体资源
@interface HQUrlAsset : HQAsset

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 */
- (instancetype)initWithURL:(NSURL *)URL;

/*!
 */
@property (nonatomic, copy, readonly) NSURL *URL;


@end

