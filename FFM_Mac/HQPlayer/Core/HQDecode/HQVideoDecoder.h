//
//  HQVideoDecoder.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/25.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQDecodeable.h"

/// 视频解码
@interface HQVideoDecoder : NSObject <HQDecodeable>

@property (nonatomic,assign) BOOL outputFromKeyFrom;


@end
