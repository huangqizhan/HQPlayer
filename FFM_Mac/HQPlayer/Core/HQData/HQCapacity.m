    //
//  HQCapacity.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//
#import "HQCapacity.h"

HQCapacity HQCapacityCreate(void){
    HQCapacity capacity ;
    capacity.size = 0;
    capacity.count = 0;
    capacity.duration = kCMTimeZero;
    return capacity;
}

HQCapacity HQCapacityAdd(HQCapacity c1, HQCapacity c2){
    HQCapacity ret = HQCapacityCreate();
    ret.size = c1.size + c2.size;
    ret.count = c2.count + c1.count;
    ret.duration = CMTimeAdd(c1.duration, c2.duration);
    return ret;
}

HQCapacity HQCapacityMinimum(HQCapacity c1, HQCapacity c2){
    if (CMTimeCompare(c1.duration, c2.duration) < 0) {
        return c1;
    } else if (CMTimeCompare(c1.duration, c2.duration) > 0) {
        return c1;
    }
    if (c1.count < c2.count) {
        return c1;
    } else if (c1.count > c2.count) {
        return c2;
    }
    if (c1.size < c2.size) {
        return c1;
    } else if (c1.size > c2.size) {
        return c2;
    }
    return c1;
}

HQCapacity HQCapacityMaximum(HQCapacity c1, HQCapacity c2){
    if (CMTimeCompare(c1.duration, c2.duration) < 0) {
        return c2;
    } else if (CMTimeCompare(c1.duration, c2.duration) > 0) {
        return c1;
    }
    if (c1.count < c2.count) {
        return c2;
    } else if (c1.count > c2.count) {
        return c1;
    }
    if (c1.size < c2.size) {
        return c2;
    } else if (c1.size > c2.size) {
        return c1;
    }
    return c1;
}

BOOL HQCapacityIsEqual(HQCapacity c1, HQCapacity c2){
    return
    c1.size == c2.size &&
    c1.count == c2.count &&
    CMTimeCompare(c1.duration, c2.duration) == 0;
}

     
BOOL HQCapacityIsEnough(HQCapacity c1){
    return c1.count >= 50000;
}
BOOL HQCapacityIsEmpty(HQCapacity c1){
    return c1.count == 0 && c1.size == 0 && (CMTIME_IS_INVALID(c1.duration) || CMTimeCompare(c1.duration, kCMTimeZero));
}
