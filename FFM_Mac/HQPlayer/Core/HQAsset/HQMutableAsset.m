//
//  HQMutableAsset.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMutableAsset.h"
#import "HQTrack+Interal.h"
#import "HQAsset+Interal.h"
#import "HQTrackDemuxer.h"
#import "HQMutiDemuxer.h"

@interface HQMutableAsset (){
    NSMutableArray <HQMutableTrack *> *_tracks;
}

@end

@implementation HQMutableAsset


- (id)copyWithZone:(NSZone *)zone{
    HQMutableAsset *one = [super copyWithZone:zone];
    one->_tracks = self->_tracks.mutableCopy;
    return one;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self->_tracks = [NSMutableArray new];
    }
    return self;
}

- (NSArray <HQMutableTrack *> *)tracks{
    return self->_tracks.copy;
}

- (HQMutableTrack *)addtrack:(HQMediaType)type{
    NSUInteger index = self->_tracks.count;
    HQMutableTrack *track = [[HQMutableTrack alloc] initWithType:type index:index];
    [self->_tracks addObject:track];
    return track;
}

- (id<HQDemuxable>)newDemuxer{
    NSMutableArray <HQTrackDemuxer *>*trackMuxers = [NSMutableArray new];
    for (HQMutableTrack *track in self->_tracks) {
        HQTrackDemuxer *demuxer = [[HQTrackDemuxer alloc] initWithTrack:track];
        [trackMuxers addObject:demuxer];
    }
    return [[HQMutiDemuxer alloc] initWithDemuxers:trackMuxers];
}

@end
