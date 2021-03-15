//
//  HQMutiDemuxer.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQMutiDemuxer.h"
#import "HQTrack.h"
#import "HQError.h"

@interface HQMutiDemuxer ()

@property (nonatomic,readonly) NSArray <id<HQDemuxable>> *demuxers;
@property (nonatomic,readonly) NSMutableArray <HQTrack *> *finishTrackIntenals;
@property (nonatomic,readonly) NSMutableArray <id<HQDemuxable>> *finishDemuxers;
@property (nonatomic,readonly) NSMutableDictionary <NSString *, NSValue *> *timeStamps;

@end

@implementation HQMutiDemuxer

@synthesize tracks = _tracks;
@synthesize duration = _duration;
@synthesize metadata = _metadata;

- (instancetype)initWithDemuxers:(NSArray <id<HQDemuxable>> *)demuxers{
    self = [super init];
    if (self) {
        self->_demuxers = demuxers.copy;
        self->_finishDemuxers = [NSMutableArray new];
        self->_finishDemuxers = [NSMutableArray new];
    }
    return self;
}

#pragma mark -- setter getter
- (void)setDelegate:(id<HQDemuxerableDelegate>)delegate{
    for (id<HQDemuxable> demuxer in self->_demuxers) {
        demuxer.delegate = delegate;
    }
}
- (id<HQDemuxerableDelegate>)delegate{
    if (self->_demuxers.count) {
        return self->_demuxers.firstObject.delegate;
    }
    return nil;
}

- (void)setOptions:(HQDemuxerOptions *)options{
    for (id<HQDemuxable>demuxer in self->_demuxers) {
        demuxer.options = options;
    }
}
- (HQDemuxerOptions *)options{
    if (self->_demuxers.count) {
        return self->_demuxers.firstObject.options;
    }
    return nil;
}

- (NSArray <HQTrack *> *)finishedTracks{
    return self->_finishTrackIntenals.copy;
}

- (id<HQDemuxable>)shareDemuxer{
    return nil;
}
#pragma mark --- HQDemuxable

- (NSError *)open{
    for (id<HQDemuxable> demuxer in self->_demuxers) {
        NSError *error = [demuxer open];
        if (error) {
            return error;
        }
    }
    ///每一路中最大的duration
    CMTime duration = kCMTimeInvalid;
    NSMutableArray <HQTrack *> *tracks = [NSMutableArray new];
    for (id <HQDemuxable> demuxer in self->_demuxers) {
        NSAssert(CMTIME_IS_NUMERIC(demuxer.duration), @"invalid dutation ");
        duration = CMTimeMaximum(duration, demuxer.duration);
        [tracks addObjectsFromArray:demuxer.tracks];
    }
    self->_duration = duration;
    self->_tracks = tracks.copy;
    self->_timeStamps = [NSMutableDictionary dictionary];
    return nil;
}

- (NSError *)close{
    for (id <HQDemuxable> demuxer in self->_demuxers) {
        NSError *error = [demuxer close];
        if (error) {
            return error;
        }
    }
    return nil;
}
- (NSError *)seekable{
    for (id <HQDemuxable> demuxer in self->_demuxers) {
          NSError *error = [demuxer seekable];
          if (error) {
              return error;
          }
      }
      return nil;
}

- (NSError *)seekToTime:(CMTime)time{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}
- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter{
    if (!CMTIME_IS_NUMERIC(time)) {
        return HQCreateError(HQErrorCodeFormatNotSeekable, HQActionCodeFormatSeekFrame);
    }
    for (id <HQDemuxable> demuxer in self->_demuxers) {
         NSError *error = [demuxer seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter];
         if (error) {
             return error;
         }
    }
    [self->_timeStamps removeAllObjects];
    [self->_finishDemuxers removeAllObjects];
    [self->_finishTrackIntenals removeAllObjects];
    return nil;
}

- (NSError *)nextPacket:(HQPacket *__autoreleasing *)packet{
    NSError *error = nil;
    while (YES) {
        id <HQDemuxable> demuxer = nil;
        CMTime minum = kCMTimePositiveInfinity;
        /// 查找时间最靠后的demuxer
        for (id<HQDemuxable> dem in self->_demuxers) {
            if ([self->_finishDemuxers containsObject:dem]) {
                continue;
            }
            NSString *key = [NSString stringWithFormat:@"%p",dem];
            NSValue *value = [self->_timeStamps objectForKey:key];
            if (!value) {
                demuxer = dem;
                break;
            }
            CMTime time = kCMTimePositiveInfinity;
            [value getValue:&time];
            if (CMTimeCompare(time  , minum ) < 0) {
                minum = time;
                demuxer = dem;
            }
        }
        if (!demuxer) {
            return HQCreateError(HQErrorCodeDemuxerEndOfFile, HQActionCodeMutilDemuxerNext);
        }
        error = [demuxer nextPacket:packet];
        if (error) {
            if (error.code == HQErrorImmediateExitRequested) {
                break;
            }
            [self->_finishDemuxers addObject:demuxer];
            [self->_finishTrackIntenals addObjectsFromArray:demuxer.tracks];
            return error;
        }
        
        CMTime codeTimestamp = (* packet).decodetimeStamp;
        NSString *key = [NSString stringWithFormat:@"%p",demuxer];
        NSValue *value = [NSValue value:&codeTimestamp withObjCType:@encode(CMTime)];
        [self->_timeStamps setValue:value forKey:key];
        break;
    }
    return error;
}

@end
