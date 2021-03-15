//
//  HQError.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/27.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, HQErrorCode) {
    HQErrorCodeUnknown = 0,
    HQErrorImmediateExitRequested,
    HQErrorCodeNoValidFormat,
    HQErrorCodeFormatNotSeekable,
    HQErrorCodePacketOutputCancelSeek,
    HQErrorCodeDemuxerEndOfFile,
    HQErrorCodeInvlidTime,
};

typedef NS_ENUM(NSUInteger, HQActionCode) {
    HQActionCodeUnknown = 0,
    HQActionCodeFormatCreate,
    HQActionCodeFormatOpenInput,
    HQActionCodeFormatFindStreamInfo,
    HQActionCodeFormatSeekFrame,
    HQActionCodeFormatReadFrame,
    HQActionCodeFormatGetSeekable,
    HQActionCodeCodecSetParametersToContext,
    HQActionCodeCodecOpen2,
    HQActionCodePacketOutputSeek,
    HQActionCodeURLDemuxerFunnelNext,
    HQActionCodeMutilDemuxerNext,
    HQActionCodeSegmentDemuxerNext,
    HQActionCodeNextFrame,
};

NSError * HQGetFFError(int result, HQActionCode operation);
NSError * HQCreateError(NSUInteger code, HQActionCode operation);
