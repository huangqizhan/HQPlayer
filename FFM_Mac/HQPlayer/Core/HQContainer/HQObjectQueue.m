//
//  HQObjectQueue.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQObjectQueue.h"
#import "HQPacket+Internal.h"
#import "HQPacket.h"
@interface HQObjectQueue (){

    struct {
        int size;
        BOOL destoryed;
        CMTime duration;
        uint64_t maxCount;
    } _flags;
}

@property (nonatomic,strong,readonly) NSCondition *weakup;
@property (nonatomic,strong,readonly) id<HQData> puttingOnject;
@property (nonatomic,strong,readonly) NSMutableArray <id <HQData>> *objects;

@end


@implementation HQObjectQueue

- (instancetype)init{
    return [self initWithMaxCount:UINT64_MAX];
}
- (instancetype)initWithMaxCount:(uint64_t)count{
    self = [super init];
    if (self) {
        self->_flags.maxCount = count;
        self->_flags.duration = kCMTimeZero;
        self->_objects = [NSMutableArray new];
        self->_weakup = [[NSCondition alloc] init];
    }
    return self;
}

- (void)dealloc{
    [self destroy];
}

- (HQCapacity)capacity{
    [self.weakup lock];
    if (self->_flags.destoryed) {
        [self.weakup unlock];
        return HQCapacityCreate();
    }

    HQCapacity capacity = HQCapacityCreate();
    capacity.size = self->_flags.size;
    capacity.count = (int)self->_objects.count;
    capacity.duration = self->_flags.duration;
    [self->_weakup unlock];
    return capacity;
}

- (BOOL)putObjectSync:(id<HQData>)object{
    return [self putObjectSync:object before:nil after:nil];
}
- (BOOL)putObjectSync:(id<HQData>)object before:(HQBlock)before after:(HQBlock)after{
    [self->_weakup lock];
    if (self->_flags.destoryed) {
        [self->_weakup unlock];
        return NO;
    }
    while (self->_objects.count >= self->_flags.maxCount) {
        self->_puttingOnject = object;
        if (before) {
            before();
        }
        [self->_weakup wait];
        if (after) {
            after();
        }
        if (!self->_puttingOnject) {
            [self->_weakup unlock];
            return NO;
        }
        self->_puttingOnject = nil;
        if (self->_flags.destoryed) {
            [self->_weakup unlock];
            return NO;
        }
    }
    [self putObject:object];
    [self->_weakup signal];
    [self->_weakup unlock];
    return YES;
}
- (BOOL)putObjectAsync:(id<HQData>)object{
    [self->_weakup lock];
    if (self->_flags.destoryed || (self->_objects.count >= self->_flags.maxCount)) {
        [self->_weakup unlock];
        return NO;
    }
    [self putObject:object];
    [self->_weakup signal];
    [self->_weakup unlock];
    return YES;
}
- (void)putObject:(id<HQData>)object {
    [object lock];
    [self->_objects addObject:object];
    if (self->_shouldSortsObjects) {
        [self->_objects sortUsingComparator:^NSComparisonResult(id<HQData> obj1, id<HQData> obj2) {
            return CMTimeCompare(obj1.timeStamp, obj2.timeStamp) < 0 ? NSOrderedAscending : NSOrderedDescending;
        }];
    }
    NSAssert(CMTIME_IS_VALID(object.duration), @"Objcet duration is invalid.");
    self->_flags.duration = CMTimeAdd(self->_flags.duration, object.duration);
    self->_flags.size += object.size;
}
- (BOOL)getObjectSync:(id<HQData> *)object{
    return [self getObjectSync:object befoter:nil after:nil];
}
- (BOOL)getObjectSync:(id<HQData> *)object befoter:(HQBlock)before after:(HQBlock)after
{
    [self->_weakup lock];
    while (self->_objects.count <= 0) {
        if (before) {
            before();
        }
        [self->_weakup wait];
        if (after) {
            after();
        }
        if (self->_flags.destoryed) {
            [self->_weakup unlock];
            return NO;
        }
    }
    *object = [self getObject];
    [self->_weakup signal];
    [self->_weakup unlock];
    return YES;
}
- (BOOL)getObjectAsync:(id<HQData> *)object
{
    [self->_weakup lock];
    if (self->_flags.destoryed || self->_objects.count <= 0) {
        [self->_weakup unlock];
        return NO;
    }
    *object = [self getObject];
    [self->_weakup signal];
    [self->_weakup unlock];
    return YES;
}
- (BOOL)getObjectAsync:(__autoreleasing id<HQData> *)object timeReader:(HQTimeReader)timeReader discareded:(uint64_t *)discarded{
    [self->_weakup lock];
    if (self->_flags.destoryed || self->_objects.count <= 0) {
        [self->_weakup unlock];
        return NO;
    }
    *object = [self getObjectWithTimeReader:timeReader discarded:discarded];
    if (*object) {
        [self->_weakup signal];
    }
    [self->_weakup unlock];
    return *object != nil;
}
- (id<HQData>)getObjectWithTimeReader:(HQTimeReader)timeReader discarded:(uint64_t *)discarded
{
    CMTime desire = kCMTimeZero;
    BOOL drop = NO;
    if (!timeReader || !timeReader(&desire, &drop)) {
        return [self getObject];
    }
    *discarded = 0;
    id<HQData> object = nil;
    do {
        CMTime first = self->_objects.firstObject.timeStamp;
//        NSLog(@"value = %lld",desire.value);
        if (CMTimeCompare(first, desire) <= 0) {
            if (object) {
                *discarded += 1;
                [object unlock];
            }
            object = [self getObject];
            if (!object) {
                break;
            }
            continue;
        }
        break;
    } while (drop);
    return object;
}
- (id<HQData>)getObject
{
    if (!self->_objects.firstObject) {
        return nil;
    }
    id<HQData> object = self->_objects.firstObject;
    [self->_objects removeObjectAtIndex:0];
    self->_flags.duration = CMTimeSubtract(self->_flags.duration, object.duration);
    if (CMTimeCompare(self->_flags.duration, kCMTimeZero) < 0 || self->_objects.count <= 0) {
        self->_flags.duration = kCMTimeZero;
    }
    self->_flags.size -= object.size;
    if (self->_flags.size <= 0 || self->_objects.count <= 0) {
        self->_flags.size = 0;
    }
    return object;
}

- (BOOL)flush
{
    [self->_weakup lock];
    if (self->_flags.destoryed) {
        [self->_weakup unlock];
        return NO;
    }
    for (id<HQData> obj in self->_objects) {
        [obj unlock];
    }
    [self->_objects removeAllObjects];
    self->_flags.size = 0;
    self->_flags.duration = kCMTimeZero;
    self->_puttingOnject = nil;
    [self->_weakup broadcast];
    [self->_weakup unlock];
    return YES;
}

- (BOOL)destroy
{
    [self->_weakup lock];
    if (self->_flags.destoryed) {
        [self->_weakup unlock];
        return NO;
    }
    self->_flags.destoryed = YES;
    for (id<HQData> obj in self->_objects) {
        [obj unlock];
    }
    [self->_objects removeAllObjects];
    self->_flags.size = 0;
    self->_flags.duration = kCMTimeZero;
    self->_puttingOnject = nil;
    [self->_weakup broadcast];
    [self->_weakup unlock];
    return YES;
}
@end
