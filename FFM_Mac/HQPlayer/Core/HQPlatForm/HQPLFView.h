//
//  HQPLFView.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//


#import "HQPLFObject.h"
#import "HQPLFColor.h"
#import "HQPLFImage.h"

#if HQCPLATFORM_TARGET_OS_MAC

typedef NSView  HQPLFView;

#elif HQCPLATFORM_TARGET_OS_IPHONE_OR_TV

typedef UIScreen HQPLFView;

#endif



void HQPLFViewSetBackgroundColor(HQPLFView *view, HQPLFColor *color);
void HQPLFViewInsertSubview(HQPLFView *superView, HQPLFView *subView, NSInteger index);

HQPLFImage * HQPLFViewGetCurrentSnapshot(HQPLFView *view);


