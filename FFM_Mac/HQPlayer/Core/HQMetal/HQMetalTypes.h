//
//  HQMetalTypes.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/7.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#ifndef HQMetalTypes_h
#define HQMetalTypes_h
#include <simd/simd.h>

typedef struct  {
    vector_float4 position;
    vector_float2 texCoord;
} HQMetalVertex;

typedef struct {
    matrix_float4x4 mvp;
} HQMetalMatrix;



#endif /* HQMetalTypes_h */
