//
//  HQTrackDemuxer.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQTrackDemuxer.h"
#import "HQMutableTrack.h"
#import "HQSegment+Inteal.h"
#import "HQTimeLayout.h"
#import "HQSegment.h"
#import "HQTrack+Interal.h"
#import "HQError.h"
#import "HQPacket+Internal.h"

@interface HQTrackDemuxer ()

@property (nonatomic, readonly) NSInteger currentIndex;
@property (nonatomic, strong, readonly) HQMutableTrack *track;
@property (nonatomic, strong, readonly) HQTimeLayout *currentLayout;
@property (nonatomic, strong, readonly) id<HQDemuxable> currentDemuxer;
@property (nonatomic, strong, readonly) NSMutableArray<HQTimeLayout *> *layouts;
@property (nonatomic, strong, readonly) NSMutableArray<id<HQDemuxable>> *demuxers;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, id<HQDemuxable>> *sharedDemuxers;

@end

@implementation HQTrackDemuxer

@synthesize tracks = _tracks;
@synthesize delegate = _delegate;
@synthesize duration = _duration;
@synthesize finishedTracks = _finishedTracks;
@synthesize options = _options;
@synthesize metadata = _metadata;

- (instancetype)initWithTrack:(HQMutableTrack *)track{
    self = [super init];
    if (self) {
        self->_tracks = [track copy];
        self->_layouts = [NSMutableArray new];
        self->_demuxers = [NSMutableArray new];
        self->_sharedDemuxers = [NSMutableDictionary dictionary];
    }
    return self;
}


#pragma mark --- setter getter
- (void)setDelegate:(id<HQDemuxerableDelegate>)delegate{
    self->_delegate = delegate;
    for (id<HQDemuxable>demuxer in self->_demuxers) {
        demuxer.delegate = delegate;
    }
}
- (void)setOptions:(HQDemuxerOptions *)options{
    self->_options = options;
    for (id<HQDemuxable>demuxer in self->_demuxers) {
        demuxer.options = options;
    }
}


#pragma mark --controll
- (id<HQDemuxable>)shareDemuxer{
    return nil;
}
- (NSError *)open{
    CMTime basetime = kCMTimeZero;
    NSMutableArray<HQTrack *> *subTracks = [NSMutableArray array];
    for (HQSegment *obj in self->_track.segments) {
        HQTimeLayout *layout = [[HQTimeLayout alloc] initWithOffset:basetime];
        NSString *demuxerKey = [obj sharedDemuxerKey];
        id<HQDemuxable> sharedDemuxer = self->_sharedDemuxers[demuxerKey];
        id<HQDemuxable> demuxer = nil;
        if (!demuxerKey) {
            demuxer = [obj newDemuxer];
        } else if (sharedDemuxer) {
            demuxer = [obj newDemuxerWithSharedMuxer:sharedDemuxer];
        } else {
            demuxer = [obj newDemuxer];
            id<HQDemuxable> reuseDemuxer = [demuxer shareDemuxer];
            if (reuseDemuxer) {
                self->_sharedDemuxers[demuxerKey] = reuseDemuxer;
            }
        }
        demuxer.options = self->_options;
        demuxer.delegate = self->_delegate;
        [self->_layouts addObject:layout];
        [self->_demuxers addObject:demuxer];
        NSError *error = [demuxer open];
        if (error) {
            return error;
        }
        NSAssert(CMTIME_IS_VALID(demuxer.duration), @"Invaild Duration.");
        NSAssert(!demuxer.tracks.firstObject || demuxer.tracks.firstObject.type == self->_track.type, @"Invaild mediaType.");
        basetime = CMTimeAdd(basetime, demuxer.duration);
        if (demuxer.tracks.firstObject) {
            [subTracks addObject:demuxer.tracks.firstObject];
        }
    }
    self->_duration = basetime;
    self->_track.subTracks = subTracks;
    self->_currentIndex = 0;
    self->_currentLayout = self->_layouts.firstObject;
    self->_currentDemuxer = self->_demuxers.firstObject;
    [self->_currentDemuxer seekToTime:kCMTimeZero];
    return nil;
}

- (NSError *)close
{
    for (id<HQDemuxable> obj in self->_demuxers) {
        [obj close];
    }
    return nil;
}

- (NSError *)seekable
{
    for (id<HQDemuxable> obj in self->_demuxers) {
        NSError *error = [obj seekable];
        if (error) {
            return error;
        }
    }
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}

- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter
{
    if (!CMTIME_IS_NUMERIC(time)) {
        return HQCreateError(HQErrorCodeInvlidTime, HQActionCodeFormatSeekFrame);
    }
    time = CMTimeMaximum(time, kCMTimeZero);
    time = CMTimeMinimum(time, self->_duration);
    NSInteger currentIndex = self->_demuxers.count - 1;
    HQTimeLayout *currentLayout = self->_layouts.lastObject;
    id<HQDemuxable> currentDemuxer = self->_demuxers.lastObject;
    for (NSUInteger i = 0; i < self->_demuxers.count; i++) {
        HQTimeLayout *layout = [self->_layouts objectAtIndex:i];
        id<HQDemuxable> demuxer = [self->_demuxers objectAtIndex:i];
        if (CMTimeCompare(time, CMTimeAdd(layout.offset, demuxer.duration)) <= 0) {
            currentIndex = i;
            currentLayout = layout;
            currentDemuxer = demuxer;
            break;
        }
    }
    time = CMTimeSubtract(time, currentLayout.offset);
    self->_finishedTracks = nil;
    self->_currentIndex = currentIndex;
    self->_currentLayout = currentLayout;
    self->_currentDemuxer = currentDemuxer;
    return [self->_currentDemuxer seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter];
}

- (NSError *)nextPacket:(HQPacket **)packet
{
    NSError *error = nil;
    while (YES) {
        if (!self->_currentDemuxer) {
            error = HQCreateError(HQErrorCodeDemuxerEndOfFile, HQActionCodeFormatReadFrame);
            break;
        }
        error = [self->_currentDemuxer nextPacket:packet];
        if (error) {
            if (error.code == HQErrorImmediateExitRequested) {
                break;
            }
            NSInteger nextIndex = self->_currentIndex + 1;
            if (nextIndex < self->_demuxers.count) {
                self->_currentIndex = nextIndex;
                self->_currentLayout = [self->_layouts objectAtIndex:nextIndex];
                self->_currentDemuxer = [self->_demuxers objectAtIndex:nextIndex];
                [self->_currentDemuxer seekToTime:kCMTimeZero];
            } else {
                self->_currentIndex = 0;
                self->_currentLayout = nil;
                self->_currentDemuxer = nil;
            }
            continue;
        }
        [(*packet).codecDescriptor  setTrack:self->_track];
        [(*packet).codecDescriptor appendingTimeLayput:self->_currentLayout];
        [(*packet) fill];
        break;
    }
    if (error.code == HQErrorCodeDemuxerEndOfFile) {
        self->_finishedTracks = self->_tracks.copy;
    }
    return error;
}

@end
