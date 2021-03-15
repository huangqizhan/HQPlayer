//
//  HQEXTractingDemuxer.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQEXTractingDemuxer.h"
#import "HQPacket+Internal.h"
#import "HQTrack.h"
#import "HQTimeLayout.h"
#import "HQObjectQueue.h"
#import "HQTime.h"
#import "HQError.h"
#import "HQMacro.h"

@interface HQEXTractingDemuxer (){
    struct {
        BOOL finished;
        BOOL inputing;
        BOOL outputing;
    } _flags;
}

@property (nonatomic,readonly) HQTrack *track;
/// 精度偏移量
@property (nonatomic,readonly) HQTimeLayout *scaleLayout;
/// 前后偏移量
@property (nonatomic,readonly) HQTimeLayout *offsetLayout;
@property (nonatomic,readonly) HQObjectQueue *packetQueue;

@end

@implementation HQEXTractingDemuxer

@synthesize tracks = _tracks;
@synthesize duration = _duration;
@synthesize finishedTracks = _finishedTracks;


- (instancetype)initWith:(id<HQDemuxable>)demuxer index:(NSInteger)index timerange:(CMTimeRange)timerange scale:(CMTime)scale{
    self = [super init];
    if (self) {
        self->_demuxer = demuxer;
        self->_index = index;
        self->_timeRange = HQCMTimeRangeFitting(timerange);
        self->_scale = scale;
        self->_overgop = YES;
        self->_packetQueue = [[HQObjectQueue alloc] init];
    }
    return self;
}

#pragma mark --- Mapping

HQGetoMap(id<HQDemuxerableDelegate>, delegate, self->_demuxer)
HQSet1Map(void, setDelegate, id<HQDemuxerableDelegate>, self->_demuxer)

HQGetoMap(HQDemuxerOptions *, options, self->_demuxer)
HQSet1Map(void, setOptions, HQDemuxerOptions *, self->_demuxer)

HQGetoMap(NSDictionary *, metadata, self->_demuxer)
HQGetoMap(NSError *, close, self->_demuxer)
HQGetoMap(NSError *, seekable, self->_demuxer)


- (id<HQDemuxable>)shareDemuxer{
    return [self->_demuxer shareDemuxer];
}

- (NSError *)open{
    NSError *error = [self->_demuxer open];
    if (error) {
        return error;
    }
    for (HQTrack *track in self->_demuxer.tracks) {
        if (track.index == self->_index) {
            self->_track = track;
            self->_tracks = @[track];
            break;
        }
    }
    CMTime start = self->_timeRange.start;
    if (!CMTIME_IS_NUMERIC(start)) {
        start = kCMTimeZero;
    }
    CMTime duration = self->_timeRange.duration;
    if (!CMTIME_IS_NUMERIC(duration)) {
        duration = CMTimeSubtract(self->_timeRange.duration, start);
    }
    self->_timeRange = CMTimeRangeMake(start, duration);
    self->_duration = HQCMTimeMultiply(self->_duration, self->_scale);
    self->_scaleLayout = [[HQTimeLayout alloc] initWithScale:self->_scale];
    self->_offsetLayout = [[HQTimeLayout alloc] initWithOffset:CMTimeMultiply(start, -1)];
    return nil;
}

- (NSError *)seekToTime:(CMTime)time{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}
- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter{
    if (!CMTIME_IS_NUMERIC(time)) {
        return HQCreateError(HQErrorCodeFormatNotSeekable, HQActionCodeFormatSeekFrame);
    }
    time = [self->_scaleLayout convertDuration:time];
    time = [self->_offsetLayout convertDuration:time];
    NSError *error = [self->_demuxer seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter];
    if (error) {
        return error;
    }
    [self->_packetQueue flush];
    self->_flags.finished = NO;
    self->_flags.inputing = YES;
    self->_flags.outputing = YES;
    self->_finishedTracks = nil;
    return nil;
}
- (NSError *)nextPacket:(HQPacket *__autoreleasing *)packet{
    if (self->_overgop) {
        return [self nextPacketIntervalOvergop:packet];
    }
    return [self nextPacketInterval:packet];
}
- (NSError *)nextPacketInterval:(HQPacket **)packet{
    NSError *error = nil;
      while (YES) {
          HQPacket *pkt = nil;
          error = [self->_demuxer nextPacket:&pkt];
          if (error) {
              break;
          }
          if (self->_index != pkt.track.index) {
              [pkt unlock];
              continue;
          }
          if (CMTimeCompare(pkt.timeStamp, self->_timeRange.start) < 0) {
              [pkt unlock];
              continue;
          }
          if (CMTimeCompare(pkt.timeStamp, CMTimeRangeGetEnd(self->_timeRange)) >= 0) {
              [pkt unlock];
              error = HQCreateError(HQErrorCodeDemuxerEndOfFile, HQActionCodeURLDemuxerFunnelNext);
              break;
          }
          [pkt.codecDescriptor appendingTimeLayput:self->_offsetLayout];
          [pkt.codecDescriptor appendingTimeLayput:self->_scaleLayout];
          [pkt.codecDescriptor appendTimeRange:self->_timeRange];
          [pkt fill];
          *packet = pkt;
          break;
      }
      if (error.code == HQErrorCodeDemuxerEndOfFile) {
          self->_finishedTracks = self->_tracks.copy;
      }
      return error;
}
- (NSError *)nextPacketIntervalOvergop:(HQPacket **)packet{
    NSError *error = nil;
    while (YES) {
        HQPacket *pkt = nil;
        if (self->_flags.outputing) {
            [self->_packetQueue getObjectAsync:&pkt];
            if (pkt) {
                [pkt.codecDescriptor appendingTimeLayput:self->_scaleLayout];
                [pkt.codecDescriptor appendingTimeLayput:self->_offsetLayout];
                [pkt.codecDescriptor appendTimeRange:self->_timeRange];
                [pkt fill];
                *packet = pkt;
                break;
            }
        }
        if (self->_flags.finished) {
            error = HQCreateError(HQErrorCodeDemuxerEndOfFile, HQActionCodeMutilDemuxerNext);
            break;
        }
        error = [self->_demuxer nextPacket:&pkt];
        if (error) {
            if (error.code == HQErrorImmediateExitRequested) {
                break;
            }
            self->_flags.finished = YES;
            continue;
        }
        
        if (self->_index != pkt.track.index) {
            [pkt unlock];
            continue;
        }
        /// packet 的当前时间不在 timeRange 范围之内
        if (CMTimeCompare(pkt.timeStamp, self->_timeRange.start)) {
            /// packet 是关键帧
            if (pkt.core->flags & AV_PKT_FLAG_KEY) {
                self->_flags.finished = YES;
            }else{
                [self->_packetQueue putObjectSync:pkt];
            }
            [pkt unlock];
            continue;
        }
        
        
        if (self->_flags.outputing && pkt.core->flags & AV_PKT_FLAG_KEY) {
            [self->_packetQueue flush];
        }
        self->_flags.outputing = YES;
        [self->_packetQueue putObjectSync:pkt];
        [pkt unlock];
    }
    if (error.code == HQErrorCodeDemuxerEndOfFile) {
        self->_finishedTracks = self->_tracks.copy;
    }
    return error;
}
@end
