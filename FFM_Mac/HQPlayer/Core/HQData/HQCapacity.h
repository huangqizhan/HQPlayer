//
//  HQCapacity.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQTime.h"

typedef struct  HQCapacity{
    int size;
    int count;
    CMTime duration;
} HQCapacity;

/// 初始化
HQCapacity HQCapacityCreate(void);

/// 添加
HQCapacity HQCapacityAdd(HQCapacity c1, HQCapacity c2);

/// 获取最小
HQCapacity HQCapacityMinimum(HQCapacity c1, HQCapacity c2);

///获取最大值
HQCapacity HQCapacityMaximum(HQCapacity c1, HQCapacity c2);

/// equal
BOOL HQCapacityIsEqual(HQCapacity c1, HQCapacity c2);

BOOL HQCapacityIsEnough(HQCapacity c1);

BOOL HQCapacityIsEmpty(HQCapacity c1);
