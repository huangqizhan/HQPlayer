//
//  HQError.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/27.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQError.h"
#import "HQFFmpeg.h"

static NSString * const HQErrorUserInfoKeyOperation = @"HQErrorUserInfoKeyOperation";


NSError * HQGetFFError(int result, HQActionCode operation){
    if (result >= 0) {
          return nil;
      }
      char *data = malloc(256);
      av_strerror(result, data, 256);
      NSString *domain = [NSString stringWithFormat:@"HQPlayer-Error-FFmpeg code : %d, msg : %s", result, data];
      free(data);
      if (result == AVERROR_EXIT) {
          result = HQErrorImmediateExitRequested;
      } else if (result == AVERROR_EOF) {
          result = HQErrorCodeDemuxerEndOfFile;
      }
      return [NSError errorWithDomain:domain code:result userInfo:@{HQErrorUserInfoKeyOperation : @(operation)}];
}
NSError * HQCreateError(NSUInteger code, HQActionCode operation){
    return [NSError errorWithDomain:@"HQPlayer-Error-SGErrorCode" code:(NSInteger)code userInfo:@{HQErrorUserInfoKeyOperation : @(operation)}];
}
