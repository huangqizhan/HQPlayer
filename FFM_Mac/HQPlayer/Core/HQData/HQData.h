//
//  Header.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/24.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

#warning ====== 
typedef NS_ENUM(NSUInteger , HQDataFlags) {
    HQDataFlagPadding = 1 << 0,
};



@protocol HQData <NSObject>

/**
*
*/
@property (nonatomic) HQDataFlags flags;
/**
 *
*/
@property (nonatomic,copy) NSString *reuseName;

/**
 *
*/
- (void)lock;
/**
*/
- (void)unlock;

/**
 *
 */
- (void)clear;

/**
 *
 */
- (CMTime)duration;

/**
 *
 */
- (CMTime)timeStamp;

/**
 *
 */
- (int)size;


@end

