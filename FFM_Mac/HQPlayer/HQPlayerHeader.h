//
//  HQPlayerHeader.h
//  FFM_Mac
//
//  Created by 黄麒展. on 2020/5/18.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#ifndef HQPlayerHeader_h
#define HQPlayerHeader_h

#if __has_include(<HQPlayer/HQPlayer.h>)

#else
#import "HQTime.h"
#import "HQError.h"
#import "HQDefine.h"

#import "HQOptions.h"
#import "HQDemuxerOptions.h"
#import "HQDecoderOptions.h"
#import "HQProcessorOptions.h"

#import "HQAudioDescriptor.h"
#import "HQVideoDescriptor.h"

#import "HQAsset.h"
#import "HQUrlAsset.h"
#import "HQMutableAsset.h"

#import "HQTrack.h"
#import "HQMutableTrack.h"
#import "HQTrackSelection.h"

#import "HQSegment.h"
#import "HQURLSegment.h"
#import "HQPaddingSegment.h"

#import "HQDemuxable.h"
#import "HQURLDemuxer.h"

#import "HQPlayerItem.h"
//#import "HQFrameReader.h"
#import "HQFrameOutput.h"
#import "HQPacketOutput.h"

#import "HQLock.h"
//#import "SGVRViewport.h"
#import "HQAudioRender.h"
#import "HQVideoRender.h"

#import "HQData.h"
#import "HQFrame.h"
#import "HQCapacity.h"
#import "HQAudioFrame.h"
#import "HQVideoFrame.h"

#import "HQProcessor.h"
#import "HQAudioProcessor.h"
#import "HQVideoProcessor.h"

#import "HQSonic.h"
#import "HQSWScale.h"
#import "HQSWRESample.h"
#import "HQAudioMixer.h"
#import "HQAudioMixerUnit.h"
#import "HQAudioFormater.h"

#import "HQPLFView.h"
#import "HQPLFImage.h"
#import "HQPLFColor.h"
#import "HQPLFObject.h"
#import "HQPLFScreen.h"
#import "HQPLFTarget.h"


#endif




#endif /* HQPlayerHeader_h */
