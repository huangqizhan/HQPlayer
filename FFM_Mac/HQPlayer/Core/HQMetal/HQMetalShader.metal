//
//  HQMetal.metal
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/5/14.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#include <metal_stdlib>
#import "HQMetalTypes.h"

using namespace metal;

///  顶点着色器输出数据
typedef struct {
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

/// 顶点着色器
vertex ColorInOut vertexShader(uint vertexID [[ vertex_id ]],
                               constant HQMetalVertex * in [[ buffer(0) ]],
                               constant HQMetalMatrix & uniforms [[ buffer(1) ]]) {
    ColorInOut out;
    out.position = uniforms.mvp * in[vertexID].position;
    out.texCoord = in[vertexID].texCoord;
    return out;
}

/// 片段着色器
fragment float4 fragmentShaderBGRA(ColorInOut in [[ stage_in ]],
                                   texture2d<half> texture [[ texture(0) ]]) {
    /// 创建着色器
    constexpr sampler linearSampler(mip_filter::nearest,
                                    mag_filter::linear,
                                    min_filter::linear);
    /// 对纹理采样
    return float4(texture.sample(linearSampler, in.texCoord));
}

/// 片段着色器
fragment float4 fragmentShaderNV12(ColorInOut      in        [[ stage_in ]],
                                   texture2d<half> textureY  [[ texture(0) ]],
                                   texture2d<half> textureUV [[ texture(1) ]]){
    /// 创建着色器
    constexpr sampler linearSampler(mip_filter::nearest,
                                    mag_filter::linear,
                                    min_filter::linear);
    /// 对纹理采样
    float y = textureY .sample(linearSampler, in.texCoord).r;
    float u = textureUV.sample(linearSampler, in.texCoord).r - 0.5;
    float v = textureUV.sample(linearSampler, in.texCoord).g - 0.5;
    /// yuv 转 rgb 
    float r = y +             1.402 * v;
    float g = y - 0.344 * u - 0.714 * v;
    float b = y + 1.772 * u;
    return float4(r, g, b, 1.0);
}
/// 片段着色器
fragment float4 fragmentShaderYUV(ColorInOut      in       [[ stage_in ]],
                                  texture2d<half> textureY [[ texture(0) ]],
                                  texture2d<half> textureU [[ texture(1) ]],
                                  texture2d<half> textureV [[ texture(2) ]]){
    /// 创建着色器
    constexpr sampler linearSampler(mip_filter::nearest,
                                    mag_filter::linear,
                                    min_filter::linear);
    /// 对纹理采样
    float y = textureY.sample(linearSampler, in.texCoord).r;
    float u = textureU.sample(linearSampler, in.texCoord).r - 0.5;
    float v = textureV.sample(linearSampler, in.texCoord).r - 0.5;
    /// yuv 转 rgb
    float r = y +             1.402 * v;
    float g = y - 0.344 * u - 0.714 * v;
    float b = y + 1.772 * u;
    return float4(r, g, b, 1.0);
}
