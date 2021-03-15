//
//  HQSonic.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/17.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HQAudioDescriptor.h"

@interface HQSonic : NSObject



/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDescriptor:(HQAudioDescriptor *)descriptor;

/**
 *
 */
@property (nonatomic, copy, readonly) HQAudioDescriptor *descriptor;

/**
 *
 */
@property (nonatomic) float speed;

/**
 *
 */
@property (nonatomic) float pitch;

/**
 *
 */
@property (nonatomic) float rate;

/**
 *
 */
@property (nonatomic) float volume;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (int)flush;

/**
 *
 */
- (int)samplesInput;

/**
 *
 */
- (int)samplesAvailable;

/**
 *
 */
- (int)write:(uint8_t **)data nb_samples:(int)nb_samples;

/**
 *
 */
- (int)read:(uint8_t **)data nb_samples:(int)nb_samples;


@end
