//
//  HQAudioPlayer.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/20.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HQAudioPlayer.h"
#import "HQPLFTarget.h"

//@interface HQAudioPlayer (){
//
//    /// 音频管道
//    AUGraph _graph;
//    /// 混响节点 (调节音量 )
//    AUNode _mixNode;
//    /// 音调节点
//    AUNode _pitchNode;
//    /// 输出节点
//    AUNode _outputNode;
//
//    /// 混响unit
//    AudioUnit _mixUnit;
//    /// 音调unit
//    AudioUnit _pitchUnit;
//    /// 输出单元
//    AudioUnit _outputUnit;
//}
///// 是否需要音调节点
//@property (nonatomic, readonly) BOOL needsTimePitchNode;
//
//
//
//
//@end
//
//@implementation HQAudioPlayer
///// 混合节点描述
//+ (AudioComponentDescription )mixACD{
//    AudioComponentDescription acd;
//    acd.componentType = kAudioUnitType_Mixer;
//#if HQCPLATFORM_TARGET_OS_MAC
//    acd.componentSubType = kAudioUnitSubType_StereoMixer;
//#elif HQCPLATFORM_TARGET_OS_IPHONE_OR_TV
//    acd.componentSubType = kAudioUnitSubType_MultiChannelMixer;
//#endif
//    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
//    return acd;
//}
///// 输出节点描述
//+ (AudioComponentDescription)outputACD{
//    AudioComponentDescription acd;
//    acd.componentType = kAudioUnitType_Output;
//#if HQCPLATFORM_TARGET_OS_MAC
//    acd.componentSubType = kAudioUnitSubType_DefaultOutput;
//#elif HQCPLATFORM_TARGET_OS_IPHONE_OR_TV
//    acd.componentSubType = kAudioUnitSubType_RemoteIO;
//#endif
//    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
//    return acd;
//}
///// 音调描述
//+ (AudioComponentDescription)pitchACD{
//    AudioComponentDescription acd;
//    acd.componentType = kAudioUnitType_FormatConverter;
//    acd.componentSubType = kAudioUnitSubType_NewTimePitch;
//    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
//    return acd;
//}
/////声音格式描述
//+ (AudioStreamBasicDescription)commonASBD{
//    UInt32 byteSize = sizeof(float);
//    AudioStreamBasicDescription asbd;
//    /// 双声道
//    asbd.mChannelsPerFrame = 2;
//    ///2个声道 32位
//    asbd.mBitsPerChannel   = byteSize * 8;
//    /// 每个采样32位4个字节
//    asbd.mBytesPerFrame    = byteSize;
//    /// buffer 布局falag
//    asbd.mFormatFlags      = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
//    /// 音频格式
//    asbd.mFormatID         = kAudioFormatLinearPCM;
//    /// 每个包packet的帧
//    asbd.mFramesPerPacket  = 1;
//    /// 每个包的位数
//    asbd.mBytesPerPacket   = asbd.mFramesPerPacket * asbd.mBytesPerFrame;
//    /// 采样率
//    asbd.mSampleRate       = 44100.0f;
//    return asbd;
//}
//
//- (instancetype)init{
//    self = [super init];
//    if (self) {
//        [self setup];
//    }
//    return self;
//}
//- (void)dealloc{
//    [self destory];
//}
//
//- (void)setup{
//    AudioStreamBasicDescription asbd = [self.class commonASBD];
//    AudioComponentDescription mixeracd = [self.class mixACD];
//    AudioComponentDescription outputacd = [self.class outputACD];
//    AudioComponentDescription pitchacd = [self.class pitchACD];
//
//
//    /// 创建总线
//    NewAUGraph(&_graph);
//
//    /// 创建三个节点
//    AUGraphAddNode(_graph, &outputacd, &_outputNode);
//    AUGraphAddNode(_graph, &mixeracd, &_mixNode);
//    AUGraphAddNode(_graph, &pitchacd, &_pitchNode);
//
//
//    /// 打开总线
//    AUGraphOpen(_graph);
//
//    /// 获取node 对应的unit
//    AUGraphNodeInfo(_graph, _outputNode, &outputacd, &(_outputUnit));
//    AUGraphNodeInfo(_graph, _mixNode, &mixeracd, &_mixUnit);
//    AUGraphNodeInfo(_graph, _pitchNode, &pitchacd, &_outputUnit);
//
//
//    /// 设置读取数据的大小
//    UInt32 value = 4096; ///4kb
//    UInt32 size = sizeof(value);
//    AudioUnitScope scrop = kAudioUnitScope_Global;
//    AudioUnitPropertyID parm = kAudioUnitProperty_MaximumFramesPerSlice;
//    AudioUnitSetProperty(_mixUnit, parm, scrop, 0, &value, size);
//    AudioUnitSetProperty(_outputUnit, parm, scrop, 0, &value, size);
//    AudioUnitSetProperty(_pitchUnit, parm, scrop, 0, &value, size);
//
//    /// 设置输入输出回调
//    AURenderCallbackStruct renderInputCallBack;
//    renderInputCallBack.inputProcRefCon = (__bridge void *)self;
//    renderInputCallBack.inputProc = inputCallback;
//    AUGraphSetNodeInputCallback(_graph, _mixNode, 0, &renderInputCallBack);
//    AUGraphAddRenderNotify(_graph, outputCallback, (__bridge void *)self);
//
//    /// 获取功能参数
//    AudioUnitParameterID mixparm;
//    #if HQCPLATFORM_TARGET_OS_MAC
//        mixparm = kStereoMixerParam_Volume;
//    #elif HQCPLATFORM_TARGET_OS_IPHONE_OR_TV
//        mixparm = kMultiChannelMixerParam_Volume;
//    #endif
//
//    AudioUnitGetParameter(_mixUnit, mixparm, kAudioUnitScope_Output, 0, &_volume);
//    AudioUnitGetParameter(_outputUnit, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, &_rate);
//    AudioUnitGetParameter(_pitchUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, &_pitch);
//
//    [self setAsbd:asbd];
//    [self reconnectTimePitchNodeForce:NO];
//
//    AUGraphInitialize(_graph);
//}
//- (void)destory{
//    AUGraphStop(_graph);
//    AUGraphUninitialize(_graph);
//    AUGraphClose(_graph);
//    DisposeAUGraph(_graph);
//}
////// 断开两个节点关联
//- (void)disconnectNodeInput:(AUNode)sourceNode destNode:(AUNode)destNode{
//    UInt32 count = 8;
//    AUNodeInteraction interactions[8];
//    if (AUGraphGetNodeInteractions(_graph, destNode, &count, interactions) == noErr) {
//        for (UInt32 i = 0; i < MIN(count, 8); i++) {
//            AUNodeInteraction interaction = interactions[i];
//            if (interaction.nodeInteractionType == kAUNodeInteraction_Connection) {
//                AUNodeConnection connection = interaction.nodeInteraction.connection;
//                if (connection.sourceNode == sourceNode) {
//                    AUGraphDisconnectNodeInput(_graph, connection.destNode, connection.destInputNumber);
//                    break;
//                }
//            }
//        }
//    }
//}
///// 连接节点
//- (void)reconnectTimePitchNodeForce:(BOOL)force{
//    BOOL needsTimePitchNode = (_rate != 1.0) || (_pitch != 0.0);
//    if (_needsTimePitchNode != needsTimePitchNode || force) {
//        _needsTimePitchNode = needsTimePitchNode;
//        if (needsTimePitchNode) {
//            [self disconnectNodeInput:_mixNode destNode:_outputNode];
//            AUGraphConnectNodeInput(_graph, _mixNode, 0, _pitchNode, 0);
//            AUGraphConnectNodeInput(_graph, _pitchNode, 0, _outputNode, 0);
//        } else {
//            [self disconnectNodeInput:_mixNode destNode:_pitchNode];
//            [self disconnectNodeInput:_pitchNode destNode:_outputNode];
//            AUGraphConnectNodeInput(_graph, _mixNode, 0, _outputNode, 0);
//        }
//        AUGraphUpdate(_graph, NULL);
//    }
//}
//- (void)play{
//    if (self.isPlaying == NO) {
//        AUGraphOpen(_graph);
//    }
//}
//- (void)pause{
//    if (self.isPlaying) {
//        AUGraphStop(_graph);
//    }
//}
//- (void)flush{
//    AudioUnitReset(_mixUnit, kAudioUnitScope_Global, 0);
//    AudioUnitReset(_pitchUnit, kAudioUnitScope_Global, 0);
//    AudioUnitReset(_pitchUnit, kAudioUnitScope_Global, 0);
//}
//#pragma mark --- getter  setter
//- (BOOL)isPlaying{
//    Boolean ret = FALSE;
//    AUGraphIsRunning(_graph, &ret);
//    return ret == FALSE ? NO : YES;
//}
//- (void)setVolume:(float)volume{
//    if (_volume == volume) {
//        return;
//    }
//    AudioUnitParameterID param;
//#if HQCPLATFORM_TARGET_OS_MAC
//    param = kStereoMixerParam_Volume;
//#elif HQCPLATFORM_TARGET_OS_IPHONE_OR_TV
//    param = kMultiChannelMixerParam_Volume;
//#endif
//    if (AudioUnitSetParameter(_mixUnit, param, kAudioUnitScope_Input, 0, volume, 0) == noErr) {
//        _volume = volume;
//    }
//}
//- (void)setRate:(float)rate{
//    if (_rate == rate) {
//        return;
//    }
//    if (AudioUnitSetParameter(_outputUnit, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, rate, 0) == noErr) {
//        _rate = rate;
//        [self reconnectTimePitchNodeForce:NO];
//    }
//}
//- (void)setPitch:(float)pitch{
//    if (_pitch == pitch) {
//        return;
//    }
//    if (AudioUnitSetParameter(_pitchUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, pitch, 0) == noErr) {
//        _pitch = pitch;
//        [self reconnectTimePitchNodeForce:NO];
//    }
//}
//- (void)setAsbd:(AudioStreamBasicDescription)asbd{
//    uint32_t size = sizeof(AudioStreamBasicDescription);
//    AudioUnitPropertyID param = kAudioUnitProperty_StreamFormat;
//    if (AudioUnitSetProperty(_mixUnit, param, kAudioUnitScope_Input, 0, &asbd, size) == noErr &&
//        AudioUnitSetProperty(_mixUnit, param, kAudioUnitScope_Output, 0, &asbd, size) == noErr &&
//        AudioUnitSetProperty(_outputUnit, param, kAudioUnitScope_Input, 0, &asbd, size) == noErr &&
//        AudioUnitSetProperty(_pitchUnit, param, kAudioUnitScope_Input, 0, &asbd, size)  == noErr &&
//        AudioUnitSetProperty(_pitchUnit, param, kAudioUnitScope_Output, 0, &asbd, size)){
//        _asbd = asbd;
//    }else{
//        AudioUnitSetProperty(_mixUnit, param, kAudioUnitScope_Input, 0, &_asbd, size);
//        AudioUnitSetProperty(_mixUnit, param, kAudioUnitScope_Output, 0, &_asbd, size);
//        AudioUnitSetProperty(_outputUnit, param, kAudioUnitScope_Input, 0, &_asbd, size);
//        AudioUnitSetProperty(_pitchUnit, param, kAudioUnitScope_Input, 0, &_asbd, size);
//        AudioUnitSetProperty(_pitchUnit, param, kAudioUnitScope_Output, 0, &_asbd, size);
//    }
//}
//#pragma mark --- callBack
///// 输入回调
//static OSStatus inputCallback(void *inRefCon,
//                              AudioUnitRenderActionFlags *ioActionFlags,
//                              const AudioTimeStamp *inTimeStamp,
//                              UInt32 inBusNumber,
//                              UInt32 inNumberFrames,
//                              AudioBufferList *ioData){
//    @autoreleasepool {
//        HQAudioPlayer *player = (__bridge HQAudioPlayer *)inRefCon;
//        [player.delegate audioPlayer:player render:inTimeStamp data:ioData numberOfFrames:inNumberFrames];
//    }
//    return noErr;
//}
/////输出回调
//static OSStatus outputCallback(void *inRefCon,
//                               AudioUnitRenderActionFlags *ioActionFlags,
//                               const AudioTimeStamp *inTimeStamp,
//                               UInt32 inBusNumber,
//                               UInt32 inNumberFrames,
//                               AudioBufferList *ioData)
//{
//    @autoreleasepool {
//        HQAudioPlayer *player = (__bridge HQAudioPlayer *)inRefCon;
//        if ((*ioActionFlags) == kAudioUnitRenderAction_PreRender) {
//            if ([player.delegate respondsToSelector:@selector(audioPlayer:willRender:)]) {
//                [player.delegate audioPlayer:player willRender:inTimeStamp];
//            }
//        }else if ((*ioActionFlags) == kAudioUnitRenderAction_PostRender){
//            if ([player.delegate respondsToSelector:@selector(audioPlayer:didRender:)]){
//                [player.delegate audioPlayer:player didRender:inTimeStamp];
//            }
//        }
//    }
//    return noErr;
//}
//@end
//
//
//


@interface HQAudioPlayer ()

{
    AUGraph _graph;
    AUNode _mixerNode;
    AUNode _outputNode;
    AUNode _timePitchNode;
    AudioUnit _mixerUnit;
    AudioUnit _outputUnit;
    AudioUnit _timePitchUnit;
}

@property (nonatomic, readonly) BOOL needsTimePitchNode;

@end

@implementation HQAudioPlayer

+ (AudioComponentDescription)mixerACD
{
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Mixer;
#if HQCPLATFORM_TARGET_OS_MAC
    acd.componentSubType = kAudioUnitSubType_StereoMixer;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    acd.componentSubType = kAudioUnitSubType_MultiChannelMixer;
#endif
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    return acd;
}

+ (AudioComponentDescription)outputACD
{
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Output;
#if HQCPLATFORM_TARGET_OS_MAC
    acd.componentSubType = kAudioUnitSubType_DefaultOutput;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    acd.componentSubType = kAudioUnitSubType_RemoteIO;
#endif
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    return acd;
}

+ (AudioComponentDescription)timePitchACD
{
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_FormatConverter;
    acd.componentSubType = kAudioUnitSubType_NewTimePitch;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    return acd;
}

+ (AudioStreamBasicDescription)commonASBD
{
    UInt32 byteSize = sizeof(float);
    AudioStreamBasicDescription asbd;
    asbd.mBitsPerChannel   = byteSize * 8;
    asbd.mBytesPerFrame    = byteSize;
    asbd.mChannelsPerFrame = 2;
    asbd.mFormatFlags      = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFramesPerPacket  = 1;
    asbd.mBytesPerPacket   = asbd.mFramesPerPacket * asbd.mBytesPerFrame;
    asbd.mSampleRate       = 44100.0f;
    return asbd;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [self destroy];
}

#pragma mark - Setup/Destory

- (void)setup
{
    AudioStreamBasicDescription asbd = [self.class commonASBD];
    AudioComponentDescription mixerACD = [self.class mixerACD];
    AudioComponentDescription outputACD = [self.class outputACD];
    AudioComponentDescription timePitchACD = [self.class timePitchACD];
    
    NewAUGraph(&_graph);
    AUGraphAddNode(_graph, &mixerACD, &_mixerNode);
    AUGraphAddNode(_graph, &outputACD, &_outputNode);
    AUGraphAddNode(_graph, &timePitchACD, &_timePitchNode);
    
    AUGraphOpen(_graph);
    AUGraphNodeInfo(_graph, _mixerNode, &mixerACD, &_mixerUnit);
    AUGraphNodeInfo(_graph, _outputNode, &outputACD, &_outputUnit);
    AUGraphNodeInfo(_graph, _timePitchNode, &timePitchACD, &_timePitchUnit);
    
    UInt32 value = 4096;
    UInt32 size = sizeof(value);
    AudioUnitScope scope = kAudioUnitScope_Global;
    AudioUnitPropertyID param = kAudioUnitProperty_MaximumFramesPerSlice;
    AudioUnitSetProperty(_mixerUnit, param, scope, 0, &value, size);
    AudioUnitSetProperty(_outputUnit, param, scope, 0, &value, size);
    AudioUnitSetProperty(_timePitchUnit, param, scope, 0, &value, size);
    
    AURenderCallbackStruct inputCallbackStruct;
    inputCallbackStruct.inputProc = inputCallback;
    inputCallbackStruct.inputProcRefCon = (__bridge void *)self;
    AUGraphSetNodeInputCallback(_graph, _mixerNode, 0, &inputCallbackStruct);
    AudioUnitAddRenderNotify(_outputUnit, outputCallback, (__bridge void *)self);
    
    AudioUnitParameterID mixerParam;
#if HQCPLATFORM_TARGET_OS_MAC
    mixerParam = kStereoMixerParam_Volume;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    mixerParam = kMultiChannelMixerParam_Volume;
#endif
    AudioUnitGetParameter(_mixerUnit, mixerParam, kAudioUnitScope_Input, 0, &_volume);
    AudioUnitGetParameter(_timePitchUnit, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, &_rate);
    AudioUnitGetParameter(_timePitchUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, &_pitch);
    
    [self setAsbd:asbd];
    [self reconnectTimePitchNodeForce:YES];

    AUGraphInitialize(_graph);
}

- (void)destroy
{
    AUGraphStop(_graph);
    AUGraphUninitialize(_graph);
    AUGraphClose(_graph);
    DisposeAUGraph(_graph);
}

- (void)disconnectNodeInput:(AUNode)sourceNode destNode:(AUNode)destNode
{
    UInt32 count = 8;
    AUNodeInteraction interactions[8];
    if (AUGraphGetNodeInteractions(_graph, destNode, &count, interactions) == noErr) {
        for (UInt32 i = 0; i < MIN(count, 8); i++) {
            AUNodeInteraction interaction = interactions[i];
            if (interaction.nodeInteractionType == kAUNodeInteraction_Connection) {
                AUNodeConnection connection = interaction.nodeInteraction.connection;
                if (connection.sourceNode == sourceNode) {
                    AUGraphDisconnectNodeInput(_graph, connection.destNode, connection.destInputNumber);
                    break;
                }
            }
        }
    }
}

- (void)reconnectTimePitchNodeForce:(BOOL)force
{
    BOOL needsTimePitchNode = (_rate != 1.0) || (_pitch != 0.0);
    if (_needsTimePitchNode != needsTimePitchNode || force) {
        _needsTimePitchNode = needsTimePitchNode;
        if (needsTimePitchNode) {
            [self disconnectNodeInput:_mixerNode destNode:_outputNode];
            AUGraphConnectNodeInput(_graph, _mixerNode, 0, _timePitchNode, 0);
            AUGraphConnectNodeInput(_graph, _timePitchNode, 0, _outputNode, 0);
        } else {
            [self disconnectNodeInput:_mixerNode destNode:_timePitchNode];
            [self disconnectNodeInput:_timePitchNode destNode:_outputNode];
            AUGraphConnectNodeInput(_graph, _mixerNode, 0, _outputNode, 0);
        }
        AUGraphUpdate(_graph, NULL);
    }
}

#pragma mark - Interface

- (void)play
{
    if ([self isPlaying] == NO) {
        AUGraphStart(_graph);
    }
}

- (void)pause
{
    if ([self isPlaying] == YES) {
        AUGraphStop(_graph);
    }
}

- (void)flush
{
    AudioUnitReset(_mixerUnit, kAudioUnitScope_Global, 0);
    AudioUnitReset(_outputUnit, kAudioUnitScope_Global, 0);
    AudioUnitReset(_timePitchUnit, kAudioUnitScope_Global, 0);
}

#pragma mark - Setter & Getter

- (BOOL)isPlaying
{
    Boolean ret = FALSE;
    AUGraphIsRunning(_graph, &ret);
    return ret == TRUE ? YES : NO;
}

- (void)setVolume:(float)volume
{
    if (_volume == volume) {
        return;
    }
    AudioUnitParameterID param;
#if HQCPLATFORM_TARGET_OS_MAC
    param = kStereoMixerParam_Volume;
#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    param = kMultiChannelMixerParam_Volume;
#endif
    if (AudioUnitSetParameter(_mixerUnit, param, kAudioUnitScope_Input, 0, volume, 0) == noErr) {
        _volume = volume;
    }
}

- (void)setRate:(float)rate
{
    if (_rate == rate) {
        return;
    }
    if (AudioUnitSetParameter(_timePitchUnit, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, rate, 0) == noErr) {
        _rate = rate;
        [self reconnectTimePitchNodeForce:NO];
    }
}

- (void)setPitch:(float)pitch
{
    if (_pitch == pitch) {
        return;
    }
    if (AudioUnitSetParameter(_timePitchUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, pitch, 0) == noErr) {
        _pitch = pitch;
        [self reconnectTimePitchNodeForce:NO];
    }
}

- (void)setAsbd:(AudioStreamBasicDescription)asbd
{
    UInt32 size = sizeof(AudioStreamBasicDescription);
    AudioUnitPropertyID param = kAudioUnitProperty_StreamFormat;
    if (AudioUnitSetProperty(_mixerUnit, param, kAudioUnitScope_Input, 0, &asbd, size) == noErr &&
        AudioUnitSetProperty(_mixerUnit, param, kAudioUnitScope_Output, 0, &asbd, size) == noErr &&
        AudioUnitSetProperty(_outputUnit, param, kAudioUnitScope_Input, 0, &asbd, size) == noErr &&
        AudioUnitSetProperty(_timePitchUnit, param, kAudioUnitScope_Input, 0, &asbd, size) == noErr &&
        AudioUnitSetProperty(_timePitchUnit, param, kAudioUnitScope_Output, 0, &asbd, size) == noErr) {
        _asbd = asbd;
    } else {
        AudioUnitSetProperty(_mixerUnit, param, kAudioUnitScope_Input, 0, &_asbd, size);
        AudioUnitSetProperty(_mixerUnit, param, kAudioUnitScope_Output, 0, &_asbd, size);
        AudioUnitSetProperty(_outputUnit, param, kAudioUnitScope_Input, 0, &_asbd, size);
        AudioUnitSetProperty(_timePitchUnit, param, kAudioUnitScope_Input, 0, &_asbd, size);
        AudioUnitSetProperty(_timePitchUnit, param, kAudioUnitScope_Output, 0, &_asbd, size);
    }
}

#pragma mark - Callback

static OSStatus inputCallback(void *inRefCon,
                              AudioUnitRenderActionFlags *ioActionFlags,
                              const AudioTimeStamp *inTimeStamp,
                              UInt32 inBusNumber,
                              UInt32 inNumberFrames,
                              AudioBufferList *ioData)
{
    @autoreleasepool {
        HQAudioPlayer *self = (__bridge HQAudioPlayer *)inRefCon;
        [self.delegate audioPlayer:self render:inTimeStamp data:ioData numberOfFrames:inNumberFrames];
    }
    return noErr;
}

static OSStatus outputCallback(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList *ioData)
{
    @autoreleasepool {
        HQAudioPlayer *self = (__bridge HQAudioPlayer *)inRefCon;
        if ((*ioActionFlags) & kAudioUnitRenderAction_PreRender) {
            if ([self.delegate respondsToSelector:@selector(audioPlayer:willRender:)]) {
                [self.delegate audioPlayer:self willRender:inTimeStamp];
            }
        } else if ((*ioActionFlags) & kAudioUnitRenderAction_PostRender) {
            if ([self.delegate respondsToSelector:@selector(audioPlayer:didRender:)]) {
                [self.delegate audioPlayer:self didRender:inTimeStamp];
            }
        }
    }
    return noErr;
}

@end
