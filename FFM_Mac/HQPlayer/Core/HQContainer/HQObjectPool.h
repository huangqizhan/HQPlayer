//
//  HQObjectPool.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQData.h"

@interface HQObjectPool : NSObject

+ (instancetype)sharedPool;

/// <#Description#>
/// @param cls <#cls description#>
/// @param reuseName <#reuseName description#>
- (__kindof id<HQData>)objectWithClass:(Class)cls reuseName:(NSString *)reuseName;

- (void)comeBack:(id<HQData>)object;

- (void)flush;

@end

