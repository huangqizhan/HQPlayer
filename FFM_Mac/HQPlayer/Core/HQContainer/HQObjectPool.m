//
//  HQObjectPool.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQObjectPool.h"

@interface HQObjectPool ()

@property (nonatomic,strong,readonly) NSLock *lock;
@property (nonatomic,strong,readonly) NSMutableDictionary <NSString *,NSMutableSet<id <HQData>> *> *pool;

@end


@implementation HQObjectPool

+ (instancetype)sharedPool{
    static HQObjectPool *pool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pool = [[HQObjectPool alloc] init];
    });
    return pool;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self->_lock = [[NSLock alloc] init];
        self->_pool = [NSMutableDictionary dictionary];
    }
    return self;
}

- (__kindof id<HQData>)objectWithClass:(Class)cls reuseName:(NSString *)reuseName{
    [self->_lock lock];
    NSMutableSet <id <HQData>> *set = [self->_pool objectForKey:reuseName];
    if (!set) {
        set = [NSMutableSet set];
        [self->_pool setObject:set forKey:reuseName];
    }
    id<HQData> object = set.anyObject;
    if (!object) {
        object = [[cls alloc] init];
    }else{
        [set removeObject:object];
    }
    [object lock];
    object.reuseName = reuseName;
    [self->_lock unlock];
    return object;
}


- (void)comeBack:(id<HQData>)object{
    [self->_lock lock];
    NSMutableSet <id<HQData>> *set = [self->_pool objectForKey:object.reuseName];
    if (![set containsObject:object]) {
        [set addObject:object];
        [object clear];
    }
    [self->_lock unlock];
}

- (void)flush{
    [self->_lock lock];
    [self->_pool removeAllObjects];
    [self->_lock unlock];
}

@end
