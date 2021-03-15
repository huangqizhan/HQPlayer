//
//  HQPlayerItem.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/7/1.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPlayerItem.h"
#import "HQPlayerItem+Internal.h"
#import "HQAudioProcessor.h"
#import "HQVideoProcessor.h"
#import "HQObjectQueue.h"
#import "HQFrameOutput.h"
#import "HQMacro.h"
#import "HQLock.h"





@interface HQPlayerItem () <HQFrameOutPutDelegate>

{
    struct {
        NSError *error;
        HQPlayerItemState state;
        BOOL audioFinished;
        BOOL videoFinished;
    } _flags;
    BOOL _capacityFlags[8];
    HQCapacity _capacities[8];
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) HQObjectQueue *audioQueue;
@property (nonatomic, strong, readonly) HQObjectQueue *videoQueue;
@property (nonatomic, strong, readonly) HQFrameOutput *frameOutput;
@property (nonatomic, strong, readonly) HQAudioProcessor *audioProcessor;
@property (nonatomic, strong, readonly) HQVideoProcessor *videoProcessor;

@end

@implementation HQPlayerItem

- (instancetype)initWithAsset:(HQAsset *)asset
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_frameOutput = [[HQFrameOutput alloc] initWithAsset:asset];
        self->_frameOutput.delegate = self;
        self->_audioQueue = [[HQObjectQueue alloc] init];
        self->_videoQueue = [[HQObjectQueue alloc] init];
        for (int i = 0; i < 8; i++) {
            self->_capacityFlags[i] = NO;
            self->_capacities[i] = HQCapacityCreate();
        }
    }
    return self;
}

- (void)dealloc
{
    HQLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != HQPlayerItemStateClosed;
    }, ^HQBlock {
        [self setState:HQPlayerItemStateClosed];
        [self->_frameOutput close];
        HQLockEXE00(self->_lock, ^{
            [self->_audioProcessor close];
            [self->_videoProcessor close];
            [self->_audioQueue destroy];
            [self->_videoQueue destroy];
        });
        return nil;
    });
}

#pragma mark - Mapping

HQGetoMap(CMTime, duration, self->_frameOutput)
HQGetoMap(NSDictionary *, metaData, self->_frameOutput)
HQGetoMap(HQDemuxerOptions *, demuxerOptions,self->_frameOutput)
HQGetoMap(HQDecoderOptions *, decodeOptions, self->_frameOutput)
HQGetoMap(NSArray <HQTrack *> *, tracks, self->_frameOutput)
HQSet1Map(void, setDemuxerOptions, HQDemuxerOptions *, self->_frameOutput)
HQSet1Map(void, setDecodeOptions, HQDecoderOptions *, self->_frameOutput)

#pragma mark - Setter & Getter

- (HQBlock)setState:(HQPlayerItemState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self->_delegate playerItem:self didChangeState:state];
    };
}

- (HQPlayerItemState)state
{
    __block HQPlayerItemState ret = HQPlayerItemStateNone;
    HQLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (NSError *)error
{
    __block NSError *ret = nil;
    HQLockEXE00(self->_lock, ^{
        ret = [self->_flags.error copy];
    });
    return ret;
}

- (HQCapacity)capacityWithType:(HQMediaType)type
{
    __block HQCapacity ret;
    HQLockEXE00(self->_lock, ^{
         ret = self->_capacities[type];
    });
    return ret;
}

- (BOOL)isAvailable:(HQMediaType)type
{
    __block BOOL ret = NO;
    HQLockEXE00(self->_lock, ^{
        if (type == HQMediaTypeAudio) {
            ret = self->_audioSelection.tracks.count > 0;
        } else if (type == HQMediaTypeVideo) {
            ret = self->_videoSelection.tracks.count > 0;
        }
    });
    return ret;
}

- (BOOL)isFinished:(HQMediaType)type
{
    __block BOOL ret = NO;
    HQLockEXE00(self->_lock, ^{
        if (type == HQMediaTypeAudio) {
            ret = self->_flags.audioFinished;
        } else if (type == HQMediaTypeVideo) {
            ret = self->_flags.videoFinished;
        }
    });
    return ret;
}

- (void)setAudioSelection:(HQTrackSelection *)audioSelection action:(HQTrackSelectionAction)action
{
    HQLockEXE10(self->_lock, ^HQBlock {
        self->_audioSelection = [audioSelection copy];
        if (action & HQTrackSelectionActionTracks) {
            NSMutableArray *m = [NSMutableArray array];
            [m addObjectsFromArray:self->_audioSelection.tracks];
            [m addObjectsFromArray:self->_videoSelection.tracks];
            [self->_frameOutput selectTracks:[m copy]];
        }
        if (action > 0) {
            [self->_audioProcessor setSelection:self->_audioSelection action:action];
        }
        return nil;
    });
}

- (void)setVideoSelection:(HQTrackSelection *)videoSelection action:(HQTrackSelectionAction)action
{
    HQLockEXE10(self->_lock, ^HQBlock {
        self->_videoSelection = [videoSelection copy];
        if (action & HQTrackSelectionActionTracks) {
            NSMutableArray *m = [NSMutableArray array];
            [m addObjectsFromArray:self->_audioSelection.tracks];
            [m addObjectsFromArray:self->_videoSelection.tracks];
            [self->_frameOutput selectTracks:[m copy]];
        }
        if (action > 0) {
            [self->_videoProcessor setSelection:self->_videoSelection action:action];
        }
        return nil;
    });
}

#pragma mark - Control

- (BOOL)open
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == HQPlayerItemStateNone;
    }, ^HQBlock {
        return [self setState:HQPlayerItemStateOpening];
    }, ^BOOL(HQBlock block) {
        block();
        return [self->_frameOutput open];
    });
}

- (BOOL)start
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == HQPlayerItemStateOpened;
    }, ^HQBlock {
        return [self setState:HQPlayerItemStateReading];;
    }, ^BOOL(HQBlock block) {
        block();
        return [self->_frameOutput start];
    });
}

- (BOOL)close
{
    return HQLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state != HQPlayerItemStateClosed;
    }, ^HQBlock {
        return [self setState:HQPlayerItemStateClosed];
    }, ^BOOL(HQBlock block) {
        block();
        [self->_frameOutput close];
        HQLockEXE00(self->_lock, ^{
            [self->_audioProcessor close];
            [self->_videoProcessor close];
            [self->_audioQueue destroy];
            [self->_videoQueue destroy];
        });
        return YES;
    });
}

- (BOOL)seekable
{
    return self->_frameOutput.seekable;
}

- (BOOL)seekToTime:(CMTime)time
{
    return [self seekToTime:time result:nil];
}

- (BOOL)seekToTime:(CMTime)time result:(HQSeekResult)result
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid result:result];
}

- (BOOL)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter result:(HQSeekResult)result
{
    HQWeakify(self)
    return ![self->_frameOutput seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter result:^(CMTime time, NSError *error) {
        HQStrongify(self)
        if (!error) {
            HQLockEXE10(self->_lock, ^HQBlock {
                [self->_audioProcessor flush];
                [self->_videoProcessor flush];
                [self->_audioQueue flush];
                [self->_videoQueue flush];
                HQBlock b1 = [self setFrameQueueCapacity:HQMediaTypeAudio];
                HQBlock b2 = [self setFrameQueueCapacity:HQMediaTypeVideo];
                return ^{b1(); b2();};
            });
        }
        if (result) {
            result(time, error);
        }
    }];
}

- (HQFrame *)copyAudioFrame:(HQTimeReader)timeReader
{
    __block HQFrame *ret = nil;
    HQLockEXE10(self->_lock, ^HQBlock {
        uint64_t discarded = 0;
        BOOL success = [self->_audioQueue getObjectAsync:&ret timeReader:timeReader discareded:&discarded];
        if (success || discarded) {
            return [self setFrameQueueCapacity:HQMediaTypeAudio];
        };
        return nil;
    });
//    if (ret) {
//        NSLog(@"audioFrame.timestamp = %f",CMTimeGetSeconds(ret.timeStamp));
//    }
    return ret;
}

- (HQFrame *)copyVideoFrame:(HQTimeReader)timeReader
{
    __block HQFrame *ret = nil;
    HQLockEXE10(self->_lock, ^HQBlock {
        uint64_t discarded = 0;
        BOOL success = [self->_videoQueue getObjectAsync:&ret timeReader:timeReader discareded:&discarded];
        if (success || discarded) {
            return [self setFrameQueueCapacity:HQMediaTypeVideo];
        };
        return nil;
    });
//    if (ret) {
//        NSLog(@"videoFrame.timestamp = %f",CMTimeGetSeconds(ret.timeStamp));
//    }
    return ret;
}

#pragma mark - SGFrameOutputDelegate

- (void)frameOutput:(HQFrameOutput *)frameOutput didChangeState:(HQFrameOutputState)state
{
    switch (state) {
        case HQFrameOutputStateOpened: {
            HQLockEXE10(self->_lock, ^HQBlock {
                NSMutableArray *video = [NSMutableArray array];
                NSMutableArray *audio = [NSMutableArray array];
                for (HQTrack *obj in frameOutput.selectedTracks) {
                    if (obj.type == HQMediaTypeAudio) {
                        [audio addObject:obj];
                    } else if (obj.type == HQMediaTypeVideo) {
                        [video addObject:obj];
                    }
                }
                if (audio.count > 0) {
                    HQTrackSelectionAction action = 0;
                    action |= HQTrackSelectionActionTracks;
                    action |= HQTrackSelectionActionWeights;
                    self->_audioSelection = [[HQTrackSelection alloc] init];
                    self->_audioSelection.tracks = @[audio.firstObject];
                    self->_audioSelection.weights = @[@(1.0)];
                    self->_audioProcessor = [[self->_processOptions.audioClass alloc] init];
                    [self->_audioProcessor setSelection:self->_audioSelection action:action];
                }
                if (video.count > 0) {
                    HQTrackSelectionAction action = 0;
                    action |= HQTrackSelectionActionTracks;
                    action |= HQTrackSelectionActionWeights;
                    self->_videoSelection = [[HQTrackSelection alloc] init];
                    self->_videoSelection.tracks = @[video.firstObject];
                    self->_videoSelection.weights = @[@(1.0)];
                    self->_videoProcessor = [[self->_processOptions.videoClass alloc] init];
                    [self->_videoProcessor setSelection:self->_videoSelection action:action];
                }
                return [self setState:HQPlayerItemStateOpened];
            });
        }
            break;
        case HQFrameOutputStateReading: {
            HQLockEXE10(self->_lock, ^HQBlock {
                return [self setState:HQPlayerItemStateReading];
            });
        }
            break;
        case HQFrameOutputStateSeeking: {
            HQLockEXE10(self->_lock, ^HQBlock {
                return [self setState:HQPlayerItemStateSeeking];
            });
        }
            break;
        case HQFrameOutputStateFinished: {
            HQLockEXE10(self->_lock, ^HQBlock {
                HQFrame *aobj = [self->_audioProcessor finish];
                if (aobj) {
                    [self->_audioQueue putObjectSync:aobj];
                    [aobj unlock];
                }
                HQFrame *vobj = [self->_videoProcessor finish];
                if (vobj) {
                    [self->_videoQueue putObjectSync:vobj];
                    [vobj unlock];
                }
                HQBlock b1 = [self setFrameQueueCapacity:HQMediaTypeAudio];
                HQBlock b2 = [self setFrameQueueCapacity:HQMediaTypeVideo];
                HQBlock b3 = [self setFinishedIfNeeded];
                return ^{b1(); b2(); b3();};
            });
        }
            break;
        case HQFrameOutputStateFailed: {
            HQLockEXE10(self->_lock, ^HQBlock {
                self->_flags.error = [frameOutput.error copy];
                return [self setState:HQPlayerItemStateFailed];
            });
        }
            break;
        default:
            break;
    }
}

- (void)frameOutput:(HQFrameOutput *)frameOutput didChangeCapacity:(HQCapacity)capacity type:(HQMediaType)type
{
    HQLockEXE10(self->_lock, ^HQBlock {
        HQCapacity additional = [self frameQueueCapacity:type];
        return [self setCapacity:HQCapacityAdd(capacity, additional) type:type];
    });
}

- (void)frameOutput:(HQFrameOutput *)frameOutput didOutputFrames:(NSArray<__kindof HQFrame *> *)frames needsDrop:(BOOL (^)(void))needsDrop
{
    HQLockEXE10(self->_lock, ^HQBlock {
        if (needsDrop && needsDrop()) {
            return nil;
        }
        BOOL hasAudio = NO, hasVideo = NO;
        NSArray<__kindof HQFrame *> *objs = frames;
        for (NSInteger i = 0; i < objs.count; i++) {
            __kindof HQFrame *obj = objs[i];
            [obj lock];
            HQMediaType type = obj.track.type;
            if (type == HQMediaTypeAudio) {
                obj = [self->_audioProcessor putFrame:obj];
                if (obj) {
                    hasAudio = YES;
                    [self->_audioQueue putObjectSync:obj];
                }
            } else if (type == HQMediaTypeVideo) {
                obj = [self->_videoProcessor putFrame:obj];
                if (obj) {
                    hasVideo = YES;
                    [self->_videoQueue putObjectSync:obj];
                }
            }
            [obj unlock];
        }
        HQBlock b1 = ^{}, b2 = ^{};
        if (hasAudio) {
            b1 = [self setFrameQueueCapacity:HQMediaTypeAudio];
        }
        if (hasVideo) {
            b2 = [self setFrameQueueCapacity:HQMediaTypeVideo];
        }
        return ^{b1(); b2();};
    });
}

#pragma mark - Capacity

- (HQBlock)setFrameQueueCapacity:(HQMediaType)type
{
    BOOL paused = NO;
    if (type == HQMediaTypeAudio) {
        paused = _audioQueue.capacity.count > 5;
    } else if (type == HQMediaTypeVideo) {
        paused = _videoQueue.capacity.count > 3;
    }
    HQBlock b1 = ^{
        if (paused) {
            [self->_frameOutput pause:type];
        } else {
            [self->_frameOutput resume:type];
        }
    };
    HQCapacity capacity = [self frameQueueCapacity:type];
    HQCapacity additional = [self->_frameOutput capacityWithType:type];
    HQBlock b2 = [self setCapacity:HQCapacityAdd(capacity, additional) type:type];
    return ^{b1(); b2();};
}

- (HQCapacity)frameQueueCapacity:(HQMediaType)type
{
    HQCapacity capacity = HQCapacityCreate();
    if (type == HQMediaTypeAudio) {
        capacity = self->_audioQueue.capacity;
        if (self->_audioProcessor) {
            capacity = HQCapacityAdd(capacity, self->_audioProcessor.capatity);
        }
    } else if (type == HQMediaTypeVideo) {
        capacity = self->_videoQueue.capacity;
        if (self->_videoProcessor) {
            capacity = HQCapacityAdd(capacity, self->_videoProcessor.capatity);
        }
    }
    return capacity;
}

- (HQBlock)setCapacity:(HQCapacity)capacity type:(HQMediaType)type
{
    HQCapacity obj = self->_capacities[type];
    if (HQCapacityIsEqual(obj, capacity)) {
        return ^{};
    }
    self->_capacityFlags[type] = YES;
    self->_capacities[type] = capacity;
    HQBlock b1 = ^{
        [self->_delegate playerItem:self didChangeCapacity:capacity mediaType:type];
    };
    HQBlock b2 = [self setFinishedIfNeeded];
    return ^{b1(); b2();};
}

- (HQBlock)setFinishedIfNeeded
{
    BOOL nomore = self->_frameOutput.state == HQFrameOutputStateFinished;
    HQCapacity ac = self->_capacities[HQMediaTypeAudio];
    HQCapacity vc = self->_capacities[HQMediaTypeVideo];
    self->_flags.audioFinished = nomore && (!self->_capacityFlags[HQMediaTypeAudio] || HQCapacityIsEmpty(ac));
    self->_flags.videoFinished = nomore && (!self->_capacityFlags[HQMediaTypeVideo] || HQCapacityIsEmpty(vc));
    if (self->_flags.audioFinished && self->_flags.videoFinished) {
        return [self setState:HQPlayerItemStateFinished];
    }
    return ^{};
}

@end
