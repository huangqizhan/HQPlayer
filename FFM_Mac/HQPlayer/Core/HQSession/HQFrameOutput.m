//
//  HQFrameOutput.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/30.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQFrameOutput.h"
#import "HQVideoDecoder.h"
#import "HQAudioDecoder.h"
#import "HQPacketOutput.h"
#import "HQDecodeLoop.h"
#import "HQOptions.h"
#import "HQMacro.h"
#import "HQLock.h"

#define BUFFERSIZE 15 * 1024 * 1024

@interface HQFrameOutput ()<HQPacketOutputDelegate,HQDecodeLoopDelegate>{
    struct {
        NSError *error;
        HQFrameOutputState state;
    } _flags;
    
    BOOL _capacityFlags[8];
    HQCapacity _capacitys[8];
}
@property (nonatomic,strong,readonly) NSLock *lock;
@property (nonatomic,strong,readonly) HQDecodeLoop *videoDecoder;
@property (nonatomic,strong,readonly) HQDecodeLoop *audioDecoder;
@property (nonatomic,strong,readonly) HQPacketOutput *packetOutput;
@property (nonatomic,strong,readonly) NSArray <HQTrack *> *finishedTracks;

@end

@implementation HQFrameOutput

@synthesize finishedTracks = _finishedTracks;
@synthesize selectedTracks = _selectedTracks;

- (instancetype)initWithAsset:(HQAsset *)asset{
    self = [super init];
    if (self) {
        self->_lock = [[NSLock alloc] init];
        self->_audioDecoder = [[HQDecodeLoop alloc] initWithDecoderClass:[HQAudioDecoder class]];
        self->_audioDecoder.delegate = self;
        self->_videoDecoder = [[HQDecodeLoop alloc] initWithDecoderClass:[HQVideoDecoder class]];
        self->_videoDecoder.delegate = self;
        self->_packetOutput = [[HQPacketOutput alloc] initWithAsset:asset];
        self->_packetOutput.delegate = self;
        for (int i = 0; i < 8; i++) {
            _capacityFlags[i] = NO;
            _capacitys[i] = HQCapacityCreate();
        }
        [self setDecodeOptions:[[HQOptions shareOptions].decoder.options copy]];
    }
    return self;
}

- (void)dealloc{
    HQLockCondEXE00(self->_lock, ^BOOL{
        return self->_flags.state != HQFrameOutputStateClosed;
    }, ^{
        [self setState:HQFrameOutputStateClosed];
        [self->_packetOutput close];
        [self->_videoDecoder close];
        [self->_audioDecoder close];
    });
}

HQGetoMap(CMTime, duration, self->_packetOutput)
HQGetoMap(NSDictionary *, metadata, self->_packetOutput)
HQGetoMap(NSArray<HQTrack *> *, tracks, self->_packetOutput)
HQGet00Map(HQDemuxerOptions *, demuxerOptions, options, self->_packetOutput)
HQGet00Map(HQDecoderOptions *, decodeOptions, options, self->_audioDecoder)
HQSet11Map(void, setDemuxerOptions, setOptions, HQDemuxerOptions *, self->_packetOutput)


#pragma mark --- Setter  Getter

- (void)setDecodeOptions:(HQDecoderOptions *)decodeOptions{
    self->_audioDecoder.options = decodeOptions;
    self->_videoDecoder.options = decodeOptions;
}
- (HQBlock)setState:(HQFrameOutputState)state{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self->_delegate frameOutput:self didChangeState:state];
    };
}
- (HQFrameOutputState)state{
    __block HQFrameOutputState state;
    HQLockEXE00(self->_lock, ^{
        state = self->_flags.state;
    });
    return state;
}
- (NSError *)error{
    __block NSError *error;
    HQLockEXE00(self->_lock, ^{
        error = self->_flags.error;
    });
    return error;
}
- (BOOL)selectTracks:(NSArray <HQTrack *> *)tracks{
    return HQLockCondEXE10(self->_lock, ^BOOL{
        return ![self->_selectedTracks isEqualToArray:tracks];
    }, ^HQBlock{
        return ^{
            self->_selectedTracks = tracks;
        };
    });
}
- (NSArray <HQTrack *> *)selectedTracks{
    __block NSArray <HQTrack *> *tracks = nil;
    HQLockEXE00(self->_lock, ^{
        tracks = [self->_selectedTracks copy];
    });
    return tracks;
}
- (HQCapacity)capacityWithType:(HQMediaType)type{
    __block HQCapacity capavity;
    HQLockEXE00(self->_lock, ^{
        capavity = self->_capacitys[type];
    });
    return capavity;
}
- (HQBlock)setFinishedTracks:(NSArray <HQTrack *> *)tracks{
    if (tracks.count == 0) {
        self->_finishedTracks = nil;
        return ^{};
    }
    HQBlock b1 = ^{}, b2 = ^{};
    if (![self->_selectedTracks isEqualToArray:tracks]) {
        NSMutableArray <HQTrack *> *videoTracks = [NSMutableArray new];
        NSMutableArray <HQTrack *> *audioTracks = [NSMutableArray new];
        for (HQTrack *track in tracks) {
            if ([self->_selectedTracks containsObject:track] && ![self->_finishedTracks containsObject:track]) {
                if (track.type == HQMediaTypeAudio) {
                    [audioTracks addObject:track];
                }else{
                    [videoTracks addObject:track];
                }
            }
        }
        self->_finishedTracks = tracks;
        if (audioTracks.count) {
            HQDecodeLoop *audioDecodeLoop = self->_audioDecoder;
            b1 = ^{
                [audioDecodeLoop finish:audioTracks];
            };
        }
        
        if (videoTracks.count) {
            HQDecodeLoop *videoLoop = self->_videoDecoder;
            b2 = ^{
                [videoLoop finish:videoTracks];
            };
        }
    }
    return ^{
        b1();b2();
    };
}
#pragma mark --- Controll
- (BOOL)open{
    return HQLockCondEXE11(self->_lock, ^BOOL{
        return self->_flags.state == HQFrameOutputStateNone;
    }, ^HQBlock{
        return [self setState:HQFrameOutputStateOpening];
    }, ^BOOL(HQBlock block) {
        block();
        return [self->_packetOutput open];
    });
}
- (BOOL)start{
    return HQLockCondEXE11(self->_lock, ^BOOL{
        return self->_flags.state == HQFrameOutputStateOpened;
    }, ^HQBlock{
        return [self setState:HQFrameOutputStateReading];
    }, ^BOOL(HQBlock block) {
        block();
        return  [self->_packetOutput resume];
    });
}
- (BOOL)close{
    return HQLockCondEXE11(self->_lock, ^BOOL{
        return self->_flags.state != HQFrameOutputStateClosed;
    }, ^HQBlock{
        return [self setState:HQFrameOutputStateClosed];
    }, ^BOOL(HQBlock block) {
        block();
        [self->_packetOutput close];
        [self->_audioDecoder close];
        [self->_videoDecoder close];
        return YES;
    });
}

- (BOOL)pause:(HQMediaType)type{
    return HQLockEXE00(self->_lock, ^{
        if (type == HQMediaTypeAudio) {
            [self->_audioDecoder pause];
        }else{
            [self->_videoDecoder pause];
        }
    });
}
- (BOOL)resume:(HQMediaType)type{
    return HQLockEXE00(self->_lock, ^{
        if (type == HQMediaTypeAudio) {
            [self->_audioDecoder resume];
        }else{
            [self->_videoDecoder resume];
        }
    });
}
- (BOOL)seekable{
    return self->_packetOutput.seekable;
}
- (BOOL)seekToTime:(CMTime)time{
    return [self seekToTime:time result:nil];
}
- (BOOL)seekToTime:(CMTime)time result:(HQSeekResult)result{
    return  [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid result:result];
}
- (BOOL)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter result:(HQSeekResult)result{
    HQWeakify(self)
   return [self->_packetOutput seekToTime:time toleranceBefore:toleranceBefor toleranceAfter:toleranceAfter result:^(CMTime time, NSError *error) {
        HQStrongify(self);
        if (!error) {
            [self->_audioDecoder flush];
            [self->_videoDecoder flush];
        }
        if (result) {
            result(time,error);
        }
    }];
}
#pragma mark --- HQPacketOutputDelegate
- (void)packetOutput:(HQPacketOutput *)packetOutput didChangeState:(HQPacketOutputState)state{
    HQLockEXE10(self->_lock, ^HQBlock{
        HQBlock b1 = ^{} ;
//        b2 = ^{},b3 = ^{};
        switch (state) {
            case HQFrameOutputStateOpened:{
                b1 = [self setState:HQFrameOutputStateOpened];
                int nb_v = 0, nb_a = 0;
                NSMutableArray *tracks = [NSMutableArray array];
                for (HQTrack *track in packetOutput.tracks) {
                    if (track.type == HQMediaTypeAudio && nb_a == 0) {
                        [tracks addObject:track];
                        nb_a += 1;
                    }else if (track.type == HQMediaTypeVideo && nb_v == 0) {
                        [tracks addObject:track];
                        nb_v += 1;
                    }
                    if (nb_a && nb_v ) {
                        break;
                    }
                }
                self->_selectedTracks = tracks;
                if (nb_a) {
                    [self->_audioDecoder open];
                }
                if (nb_v) {
                    [self->_videoDecoder open];
                }
            }
                break;
            case HQFrameOutputStateReading:
                b1 = [self setState:HQFrameOutputStateReading];
                break;
            case HQFrameOutputStateSeeking:{
                b1 = [self setState:HQFrameOutputStateSeeking];
            }
                break;
            case HQFrameOutputStateFinished:{
                b1 = [self setState:HQFrameOutputStateFinished];
            }
                break;
            case HQFrameOutputStateFailed:
                b1 = [self setState:HQFrameOutputStateFailed];
                break;
            default:
                break;
        }
        return ^{
            b1();
//            b2();b3();
        };
    });
}
- (void)packetOutput:(HQPacketOutput *)packetOutput didOutputPacket:(HQPacket *)packet{
    HQLockEXE10(self->_lock, ^HQBlock{
        HQBlock b1 = ^{}, b2 = ^{};
        b1 = [self setState:HQFrameOutputStateReading];
        if ([self->_selectedTracks containsObject:packet.track]) {
            HQDecodeLoop *decodeloop = nil;
            if (packet.track.type == HQMediaTypeVideo) {
                decodeloop = self->_videoDecoder;
            }else if (packet.track.type == HQMediaTypeAudio){
                decodeloop = self->_audioDecoder;
            }
            b2 = ^{
                [decodeloop putPacket:packet];
            };
        }
        return ^{ b1(); b2();};
    });
}

#pragma mark --- HQDecoderLoopDelegate
- (void)decodeLoop:(HQDecodeLoop *)decodeLoop didChangeState:(HQDecodeLoopState)state{
    
}
- (void)decodeLoop:(HQDecodeLoop *)decodeLoop didChangeCapacity:(HQCapacity)capacity{
    __block HQBlock finished = ^{};
    __block HQMediaType type = HQMediaTypeUnknown;
    HQLockCondEXE11(self->_lock, ^BOOL{
        if (decodeLoop == self->_audioDecoder) {
            type = HQMediaTypeAudio;
        }else if (decodeLoop == self->_videoDecoder){
            type = HQMediaTypeVideo;
        }
        return !HQCapacityIsEqual(self->_capacitys[type], capacity);
    }, ^HQBlock{
        self->_capacityFlags[type] = YES;
        self->_capacitys[type] = capacity;
        HQCapacity ac = self->_capacitys[HQMediaTypeAudio];
        HQCapacity vc = self->_capacitys[HQMediaTypeVideo];
        int size = ac.size + vc.size;
        BOOL enough = NO;
        BOOL acap = self->_capacityFlags[HQMediaTypeAudio];
        BOOL audioE = HQCapacityIsEnough(ac);
        BOOL videop = self->_capacityFlags[HQMediaTypeVideo];
        BOOL videoE = HQCapacityIsEnough(vc);
        if ((!acap || audioE) && (!videop || videoE)) {
            enough = YES;
        }
        if ((!self->_capacityFlags[HQMediaTypeAudio] || HQCapacityIsEmpty(ac)) && (!self->_capacityFlags[HQMediaTypeVideo] || HQCapacityIsEmpty(vc)) && self->_packetOutput.state == HQPacketOutputStateFinished) {
            finished = [self setState:HQFrameOutputStateFinished];
        }
        return ^{
            if (enough || size > BUFFERSIZE) {
                [self->_packetOutput pause];
            }else{
                [self->_packetOutput resume];
            }
        };
    }, ^BOOL(HQBlock block) {
        block();
        [self->_delegate frameOutput:self didChangeCapacity:capacity type:type];
        finished();
        return YES;
    });
    
}
- (void)decodeLoop:(HQDecodeLoop *)decodeLoop didOutputFrames:(NSArray<__kindof HQFrame *> *)frames needsDrop:(BOOL (^)(void))needsDrop{
    [self->_delegate
     frameOutput:self didOutputFrames:frames needsDrop:needsDrop];
}

@end
