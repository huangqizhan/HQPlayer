//
//  HQPLFView.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQPLFView.h"
#import "HQPLFScreen.h"


#if HQCPLATFORM_TARGET_OS_MAC
void HQPLFViewSetBackgroundColor(HQPLFView *view, HQPLFColor *color){
    view.wantsLayer = YES;
    view.layer.backgroundColor = color.CGColor;
}
void HQPLFViewInsertSubview(HQPLFView *superView, HQPLFView *subView, NSInteger index){
    if (superView.subviews.count > index) {
        NSView *obj = [superView.subviews objectAtIndex:index];
        [superView addSubview:subView positioned:NSWindowBelow relativeTo:obj];
    } else {
        [superView addSubview:subView];
    }
}

HQPLFImage * HQPLFViewGetCurrentSnapshot(HQPLFView *view){
    CGSize size = CGSizeMake(view.bounds.size.width * HQPLFScreenGetScale(),
                             view.bounds.size.height * HQPLFScreenGetScale());
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nil,
                                                 size.width,
                                                 size.height,
                                                 8,
                                                 size.width * 4,
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    [view.layer renderInContext:context];
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:size];
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CGImageRelease(imageRef);
    return image;

}
#elif HQCPLATFORM_TARGET_OS_IPHONE_OR_TV
void HQPLFViewSetBackgroundColor(HQPLFView *view, HQPLFColor *color){
     view.backgroundColor = color;
}
void HQPLFViewInsertSubview(HQPLFView *superView, HQPLFView *subView, NSInteger index){
    [superView insertSubview:subView atIndex:index];
}

HQPLFImage * HQPLFViewGetCurrentSnapshot(HQPLFView *view){
    CGSize size = CGSizeMake(view.bounds.size.width * SGPLFScreenGetScale(),
                             view.bounds.size.height * SGPLFScreenGetScale());
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [view drawViewHierarchyInRect:rect afterScreenUpdates:YES];
    SGPLFImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;

}

#endif


