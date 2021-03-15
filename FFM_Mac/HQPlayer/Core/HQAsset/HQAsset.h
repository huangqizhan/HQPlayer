//
//  HQAsset.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>

/// 抽象类 (媒体资源)
@interface HQAsset : NSObject <NSCopying> 

+ (instancetype)assetWithUrl:(NSURL *)url;

@end




