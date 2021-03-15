//
//  HQPLFTarget.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/9.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#ifndef HQPLFTarget_h
#define HQPLFTarget_h


// 各个平台的类型定义
#import <TargetConditionals.h>

#define HQCPLATFORM_TARGET_OS_MAC    TARGET_OS_MAC
#define HQCPLATFORM_TARGET_OS_IPHONE TARGET_OS_IOS
#define HQCPLATFORM_TARGET_OS_TV     TARGET_OS_TV

#define HQCPLATFORM_TARGET_OS_MAC_OR_TV (HQCPLATFORM_TARGET_OS_MAC || HQCPLATFORM_TARGET_OS_TV)
#define HQCPLATFORM_TARGET_OS_MAC_OR_IPHONE (HQCPLATFORM_TARGET_OS_MAC || HQCPLATFORM_TARGET_OS_IPHONE)
#define HQCPLATFORM_TARGET_OS_IPHONE_OR_TV (HQCPLATFORM_TARGET_OS_IPHONE || HQCPLATFORM_TARGET_OS_TV)



#endif /* HQPLFTarget_h */
