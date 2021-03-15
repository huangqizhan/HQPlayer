//
//  HQDecodeContext.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQDecodeContext.h"
#import "HQPacket+Internal.h"
#import "HQObjectQueue.h"
#import "HQDecodeable.h"

static HQPacket *kFlushPacket;
static HQPacket *kFinishPacket;
static NSInteger kMaxPreDecodeCount = 2;

@interface HQDecodeContextUnit : NSObject

@property (nonatomic) NSArray <HQFrame *> *frames;
@property (nonatomic) id<HQDecodeable> decoder;
@property (nonatomic) HQObjectQueue *packetQueue;
@property (nonatomic) HQCodecDescriptor *codecDescriptor;

@end

@implementation HQDecodeContextUnit

- (void)dealloc{
    for (HQFrame *frame in self->_frames) {
        [frame unlock];
    }
    self->_frames = nil;
}

@end

@interface HQDecodeContext ()

@property (nonatomic,readonly) BOOL needFlush;
@property (nonatomic,readonly) NSInteger decodeIndex;
@property (nonatomic,readonly) NSInteger preDecodeIndex;
@property (nonatomic,readonly) Class decodeClass;
@property (nonatomic,readonly) NSMutableArray <id<HQDecodeable>> *decodes;
@property (nonatomic,readonly) NSMutableArray <HQDecodeContextUnit *> *units;

@end

@implementation HQDecodeContext

- (instancetype)initWithDecoderClass:(Class)decodeClass{
    self = [super init];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            kFlushPacket = [[HQPacket alloc] init];
            kFinishPacket = [[HQPacket alloc] init];
            [kFlushPacket lock];
            [kFinishPacket lock];
        });
        self->_needFlush = NO;
        self->_decodeIndex = 0;
        self->_preDecodeIndex = 0;
        self->_decodeClass = decodeClass;
        self->_units = [NSMutableArray new];
        self->_decodes = [NSMutableArray new];
    }
    return self;
}
- (HQCapacity )capacity{
    HQCapacity capacity = HQCapacityCreate();
    for (HQDecodeContextUnit *unit in self->_units) {
        capacity = HQCapacityAdd(capacity, unit.packetQueue.capacity);
    }
    return capacity;
}
- (void)putPacket:(HQPacket *)packet{
    HQDecodeContextUnit *unit = self->_units.lastObject;
    if (![unit.codecDescriptor isEqualToDescriptor:packet.codecDescriptor]) {
        unit = [[HQDecodeContextUnit alloc] init];
        unit.packetQueue = [[HQObjectQueue alloc] init];
        unit.codecDescriptor = packet.codecDescriptor.copy;
        [self->_units addObject:unit];
    }
    [unit.packetQueue putObjectSync:packet];
}

- (BOOL)needPreDecode{
    NSInteger count = 0;
    for (NSInteger i = self->_decodeIndex + 1 ; i < self->_units.count; i++) {
        if (count >= kMaxPreDecodeCount) {
            return NO;
        }
        /// 如果是p视频帧需要预解码
        HQDecodeContextUnit *unit = self.units[i];
        HQCodecDescriptor *cd = unit.codecDescriptor;
        if (cd.codecpar && cd.codecpar->codec_type == AVMEDIA_TYPE_VIDEO && (cd.codecpar->codec_id == AV_CODEC_ID_H264 && cd.codecpar->codec_id == AV_CODEC_ID_H265)) {
            count += 1;
            if (unit.frames.count > 0) {
                continue;
            }
            self->_preDecodeIndex = i;
            return unit.packetQueue.capacity.count > 0;
        }
    }
    return NO;
}
- (void)preDecode:(HQBlock)lock unlock:(HQBlock)unlock{
    HQPacket *packet = nil;
    HQDecodeContextUnit *unit = self->_units[self->_preDecodeIndex];
    if ([unit.packetQueue getObjectAsync: &packet]) {
        [self setDecoderIfNeeded:unit];
        id<HQDecodeable> decoder = unit.decoder;
#warning ======
        lock();
        NSArray *frames = [decoder decode:packet];
        unlock();
        unit.frames = frames;
        [packet unlock];
    }
}
- (NSArray <__kindof HQFrame *> *)decode:(HQBlock)lock unlock:(HQBlock)unlock{
    NSMutableArray *ret = [NSMutableArray new];
    NSInteger index = 0;
    HQPacket *packet = nil;
    HQDecodeContextUnit *unit = nil;
    for (NSInteger i = 0; i < self->_units.count; i++) {
        HQDecodeContextUnit *obj = self->_units[i];
        if ([obj.packetQueue getObjectAsync:&packet]) {
            index = i;
            unit = obj;
            break;
        }
    }
    NSAssert(packet, @"packet is nil");
    if (packet == kFlushPacket) {
        self->_needFlush = NO;
        self->_decodeIndex = 0;
        self->_preDecodeIndex = 0;
        self->_decodeTimeStamp = kCMTimeInvalid;
        [self->_units removeObjectAtIndex:0];
    }else if (packet == kFinishPacket){
        [self->_units removeLastObject];
        for (NSInteger i = self->_decodeIndex; i < self->_units.count; i++) {
            HQDecodeContextUnit *obj = self->_units[i];
            [ret addObjectsFromArray:obj.frames];
            [ret addObjectsFromArray:[obj.decoder finish]];
            [self removeDecoderIfNeeded:obj];
        }
        [self->_units removeAllObjects];
    }else{
        self->_decodeTimeStamp = packet.decodetimeStamp;
        if (self->_decodeIndex < index) {
            for (NSInteger i = self->_decodeIndex; i < MIN(index, self->_units.count); i++) {
                HQDecodeContextUnit *obj = self->_units[i];
                [ret addObjectsFromArray:obj.frames];
                [ret addObjectsFromArray:[obj.decoder finish]];
                [self removeDecoderIfNeeded:obj];
            }
            [ret addObjectsFromArray:unit.frames];
            unit.frames = nil;
            self->_decodeIndex = index;
        }
        [self setDecoderIfNeeded:unit];
        id<HQDecodeable> decoder = unit.decoder;
        unlock();
        NSArray *frames = [decoder decode:packet];
        [ret addObjectsFromArray:frames];
        lock();
        [packet unlock];
    }

    if (self->_needFlush) {
        for (HQFrame *frame in ret) {
            [frame unlock];
        }
        [ret removeAllObjects];
    }
    return ret.count ? ret : nil ;
}
- (void)setNeedsFlush{
    self->_needFlush = YES;
    for (HQDecodeContextUnit *unit in self->_units) {
        [self removeDecoderIfNeeded:unit];
    }
    [self->_units removeAllObjects];
    HQDecodeContextUnit *unit = [[HQDecodeContextUnit alloc] init];
    unit.packetQueue = [[HQObjectQueue alloc] init];
    unit.codecDescriptor = [[HQCodecDescriptor alloc] init];
    [unit.packetQueue putObjectSync:kFlushPacket];
    [self->_units addObject:unit];
}
- (void)markAsFinshed{
    HQDecodeContextUnit *unit = [[HQDecodeContextUnit alloc] init];
    unit.packetQueue = [[HQObjectQueue alloc] init];
    unit.codecDescriptor = [[HQCodecDescriptor alloc] init];
    [unit.packetQueue putObjectSync:kFinishPacket];
    [self->_units addObject:unit];
}
- (void)destory{
    [self->_units removeAllObjects];
}
- (void)setDecoderIfNeeded:(HQDecodeContextUnit *)unit{
    if (!unit.decoder) {
        if (self->_decodes.count) {
            unit.decoder = self->_decodes.lastObject;
            [unit.decoder flush];
            [self->_decodes removeLastObject];
        }else{
            unit.decoder = [[self->_decodeClass alloc] init];
            unit.decoder.options = self->_options;
        }
    }
}
- (void)removeDecoderIfNeeded:(HQDecodeContextUnit *)unit {
    if (unit.decoder) {
        [self->_decodes addObject:unit.decoder];
    }
    unit.decoder = nil;
}
@end
