//
//  HQPLFScreen.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/23.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPLFScreen.h"

#if HQCPLATFORM_TARGET_OS_MAC

CGFloat HQPLFScreenGetScale(void){
    return [NSScreen mainScreen].backingScaleFactor;
}
#elif HQCPLATFORM_TARGET_OS_IPHONE_OR_TV

CGFloat HQPLFScreenGetScale(void){
    return [UIScreen mainScreen].scale;
}
#endif


