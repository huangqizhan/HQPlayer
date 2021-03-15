//
//  HQPLFScreen.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/23.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPLFObject.h"

#if HQCPLATFORM_TARGET_OS_MAC

typedef NSScreen  HQScreen;

#elif HQCPLATFORM_TARGET_OS_IPHONE_OR_TV

typedef UIScreen HQScreen;

#endif


CGFloat HQPLFScreenGetScale(void);
