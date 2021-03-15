//
//  HQTrack+Interal.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQTrack.h"
#import "HQMutableTrack.h"
#import "HQFFmpeg.h"

@interface HQTrack ()

- (instancetype)initWithType:(HQMediaType)type index:(NSInteger)index;

/// ffmpeg ->avstream
@property (nonatomic) AVStream *core;

@end


@interface HQMutableTrack ()

/// subtracks
@property (nonatomic,copy) NSArray <HQTrack *> *subTracks;


@end


