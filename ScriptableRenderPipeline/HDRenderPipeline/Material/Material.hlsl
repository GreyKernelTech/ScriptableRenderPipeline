#ifndef UNITY_MATERIAL_INCLUDED
#define UNITY_MATERIAL_INCLUDED

#include "../../Core/ShaderLibrary/Color.hlsl"
#include "../../Core/ShaderLibrary/Packing.hlsl"
#include "../../Core/ShaderLibrary/BSDF.hlsl"
#include "../../Core/ShaderLibrary/Debug.hlsl"
#include "../../Core/ShaderLibrary/GeometricTools.hlsl"
#include "../../Core/ShaderLibrary/CommonMaterial.hlsl"
#include "../../Core/ShaderLibrary/EntityLighting.hlsl"
#include "../../Core/ShaderLibrary/ImageBasedLighting.hlsl"

//-----------------------------------------------------------------------------
// Blending
//-----------------------------------------------------------------------------
// This should match the possible blending modes in any material .shader file (lit/layeredlit/unlit etc)
#if defined(_BLENDMODE_LERP) || defined(_BLENDMODE_ADD) || defined(_BLENDMODE_SOFT_ADD) || defined(_BLENDMODE_MULTIPLY) || defined(_BLENDMODE_PRE_MULTIPLY)
#   define SURFACE_TYPE_TRANSPARENT
#else
#   define SURFACE_TYPE_OPAQUE
#endif

//-----------------------------------------------------------------------------
// BuiltinData
//-----------------------------------------------------------------------------

#include "Builtin/BuiltinData.hlsl"

//-----------------------------------------------------------------------------
// Material definition
//-----------------------------------------------------------------------------

// Here we include all the different lighting model supported by the renderloop based on define done in .shader
// Only one deferred layout is allowed for a HDRenderPipeline, this will be detect by the redefinition of GBUFFERMATERIAL_COUNT
// If GBUFFERMATERIAL_COUNT is define two time, the shaders will not compile
#ifdef UNITY_MATERIAL_LIT
#include "Lit/Lit.hlsl"
#elif defined(UNITY_MATERIAL_UNLIT)
#include "Unlit/Unlit.hlsl"
#elif defined(UNITY_MATERIAL_IRIDESCENCE)
//#include "Iridescence/Iridescence.hlsl"
#endif

//-----------------------------------------------------------------------------
// Define for GBuffer management
//-----------------------------------------------------------------------------

#ifdef GBUFFERMATERIAL_COUNT

#if GBUFFERMATERIAL_COUNT == 2

#define OUTPUT_GBUFFER(NAME)                            \
        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1

#define DECLARE_GBUFFER_TEXTURE(NAME)   \
        TEXTURE2D(MERGE_NAME(NAME, 0));  \
        TEXTURE2D(MERGE_NAME(NAME, 1));

#define FETCH_GBUFFER(NAME, TEX, unCoord2)                                        \
        GBufferType0 MERGE_NAME(NAME, 0) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 0), unCoord2); \
        GBufferType1 MERGE_NAME(NAME, 1) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 1), unCoord2);

#define ENCODE_INTO_GBUFFER(SURFACE_DATA, BAKE_DIFFUSE_LIGHTING, NAME) EncodeIntoGBuffer(SURFACE_DATA, BAKE_DIFFUSE_LIGHTING, MERGE_NAME(NAME,0), MERGE_NAME(NAME,1))
#define DECODE_FROM_GBUFFER(NAME, FEATURE_FLAGS, BSDF_DATA, BAKE_DIFFUSE_LIGHTING) DecodeFromGBuffer(MERGE_NAME(NAME,0), MERGE_NAME(NAME,1), FEATURE_FLAGS, BSDF_DATA, BAKE_DIFFUSE_LIGHTING)
#define MATERIAL_FEATURE_FLAGS_FROM_GBUFFER(NAME) MaterialFeatureFlagsFromGBuffer(MERGE_NAME(NAME,0), MERGE_NAME(NAME,1))

#if SHADEROPTIONS_BAKED_SHADOW_MASK_ENABLE
    #define OUTPUT_GBUFFER_SHADOWMASK(NAME) ,out float4 NAME : SV_Target2
    #if SHADEROPTIONS_VELOCITY_IN_GBUFFER
    #define OUTPUT_GBUFFER_VELOCITY(NAME) ,out float4 NAME : SV_Target3
    #endif
#else
    #if SHADEROPTIONS_VELOCITY_IN_GBUFFER
    #define OUTPUT_GBUFFER_VELOCITY(NAME) ,out float4 NAME : SV_Target2
    #endif
#endif

#elif GBUFFERMATERIAL_COUNT == 3

#define OUTPUT_GBUFFER(NAME)                            \
        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1,    \
        out GBufferType2 MERGE_NAME(NAME, 2) : SV_Target2

#define DECLARE_GBUFFER_TEXTURE(NAME)   \
        TEXTURE2D(MERGE_NAME(NAME, 0));  \
        TEXTURE2D(MERGE_NAME(NAME, 1));  \
        TEXTURE2D(MERGE_NAME(NAME, 2));

#define FETCH_GBUFFER(NAME, TEX, unCoord2)                                        \
        GBufferType0 MERGE_NAME(NAME, 0) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 0), unCoord2); \
        GBufferType1 MERGE_NAME(NAME, 1) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 1), unCoord2); \
        GBufferType2 MERGE_NAME(NAME, 2) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 2), unCoord2);

#define ENCODE_INTO_GBUFFER(SURFACE_DATA, BAKE_DIFFUSE_LIGHTING, NAME) EncodeIntoGBuffer(SURFACE_DATA, BAKE_DIFFUSE_LIGHTING, MERGE_NAME(NAME,0), MERGE_NAME(NAME,1), MERGE_NAME(NAME,2))
#define DECODE_FROM_GBUFFER(NAME, FEATURE_FLAGS, BSDF_DATA, BAKE_DIFFUSE_LIGHTING) DecodeFromGBuffer(MERGE_NAME(NAME,0), MERGE_NAME(NAME,1), MERGE_NAME(NAME,2), FEATURE_FLAGS, BSDF_DATA, BAKE_DIFFUSE_LIGHTING)
#define MATERIAL_FEATURE_FLAGS_FROM_GBUFFER(NAME) MaterialFeatureFlagsFromGBuffer(MERGE_NAME(NAME,0), MERGE_NAME(NAME,1), MERGE_NAME(NAME,2))

#if SHADEROPTIONS_BAKED_SHADOW_MASK_ENABLE
    #define OUTPUT_GBUFFER_SHADOWMASK(NAME) ,out float4 NAME : SV_Target3
    #if SHADEROPTIONS_VELOCITY_IN_GBUFFER
    #define OUTPUT_GBUFFER_VELOCITY(NAME) ,out float4 NAME : SV_Target4
    #endif
#else
    #if SHADEROPTIONS_VELOCITY_IN_GBUFFER
    #define OUTPUT_GBUFFER_VELOCITY(NAME) ,out float4 NAME : SV_Target3
    #endif
#endif

#elif GBUFFERMATERIAL_COUNT == 4

#define OUTPUT_GBUFFER(NAME)                            \
        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1,    \
        out GBufferType2 MERGE_NAME(NAME, 2) : SV_Target2,    \
        out GBufferType3 MERGE_NAME(NAME, 3) : SV_Target3

#define DECLARE_GBUFFER_TEXTURE(NAME)   \
        TEXTURE2D(MERGE_NAME(NAME, 0));  \
        TEXTURE2D(MERGE_NAME(NAME, 1));  \
        TEXTURE2D(MERGE_NAME(NAME, 2));  \
        TEXTURE2D(MERGE_NAME(NAME, 3));

#define FETCH_GBUFFER(NAME, TEX, unCoord2)                                        \
        GBufferType0 MERGE_NAME(NAME, 0) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 0), unCoord2); \
        GBufferType1 MERGE_NAME(NAME, 1) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 1), unCoord2); \
        GBufferType2 MERGE_NAME(NAME, 2) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 2), unCoord2); \
        GBufferType3 MERGE_NAME(NAME, 3) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 3), unCoord2);

#define ENCODE_INTO_GBUFFER(SURFACE_DATA, BAKE_DIFFUSE_LIGHTING, NAME) EncodeIntoGBuffer(SURFACE_DATA, BAKE_DIFFUSE_LIGHTING, MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3))
#define DECODE_FROM_GBUFFER(NAME, FEATURE_FLAGS, BSDF_DATA, BAKE_DIFFUSE_LIGHTING) DecodeFromGBuffer(MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3), FEATURE_FLAGS, BSDF_DATA, BAKE_DIFFUSE_LIGHTING)
#define MATERIAL_FEATURE_FLAGS_FROM_GBUFFER(NAME) MaterialFeatureFlagsFromGBuffer(MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3))

#if SHADEROPTIONS_BAKED_SHADOW_MASK_ENABLE
    #define OUTPUT_GBUFFER_SHADOWMASK(NAME) ,out float4 NAME : SV_Target4
    #if SHADEROPTIONS_VELOCITY_IN_GBUFFER
    #define OUTPUT_GBUFFER_VELOCITY(NAME) ,out float4 NAME : SV_Target5
    #endif
#else
    #if SHADEROPTIONS_VELOCITY_IN_GBUFFER
    #define OUTPUT_GBUFFER_VELOCITY(NAME) ,out float4 NAME : SV_Target4
    #endif
#endif

#elif GBUFFERMATERIAL_COUNT == 5

#define OUTPUT_GBUFFER(NAME)                            \
        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1,    \
        out GBufferType2 MERGE_NAME(NAME, 2) : SV_Target2,    \
        out GBufferType3 MERGE_NAME(NAME, 3) : SV_Target3,    \
        out GBufferType4 MERGE_NAME(NAME, 4) : SV_Target4

#define DECLARE_GBUFFER_TEXTURE(NAME)   \
        TEXTURE2D(MERGE_NAME(NAME, 0));  \
        TEXTURE2D(MERGE_NAME(NAME, 1));  \
        TEXTURE2D(MERGE_NAME(NAME, 2));  \
        TEXTURE2D(MERGE_NAME(NAME, 3));  \
        TEXTURE2D(MERGE_NAME(NAME, 4));

#define FETCH_GBUFFER(NAME, TEX, unCoord2)                                        \
        GBufferType0 MERGE_NAME(NAME, 0) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 0), unCoord2); \
        GBufferType1 MERGE_NAME(NAME, 1) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 1), unCoord2); \
        GBufferType2 MERGE_NAME(NAME, 2) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 2), unCoord2); \
        GBufferType3 MERGE_NAME(NAME, 3) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 3), unCoord2); \
        GBufferType4 MERGE_NAME(NAME, 4) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 4), unCoord2);

#define ENCODE_INTO_GBUFFER(SURFACE_DATA, BAKE_DIFFUSE_LIGHTING, NAME) EncodeIntoGBuffer(SURFACE_DATA, BAKE_DIFFUSE_LIGHTING, MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3), MERGE_NAME(NAME, 4))
#define DECODE_FROM_GBUFFER(NAME, FEATURE_FLAGS, BSDF_DATA, BAKE_DIFFUSE_LIGHTING) DecodeFromGBuffer(MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3), MERGE_NAME(NAME, 4), FEATURE_FLAGS, BSDF_DATA, BAKE_DIFFUSE_LIGHTING)
#define MATERIAL_FEATURE_FLAGS_FROM_GBUFFER(NAME) MaterialFeatureFlagsFromGBuffer(MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3), MERGE_NAME(NAME, 4))

#if SHADEROPTIONS_BAKED_SHADOW_MASK_ENABLE
    #define OUTPUT_GBUFFER_SHADOWMASK(NAME) ,out float4 NAME : SV_Target5
    #if SHADEROPTIONS_VELOCITY_IN_GBUFFER
    #define OUTPUT_GBUFFER_VELOCITY(NAME) ,out float4 NAME : SV_Target6
    #endif
#else
    #if SHADEROPTIONS_VELOCITY_IN_GBUFFER
    #define OUTPUT_GBUFFER_VELOCITY(NAME) ,out float4 NAME : SV_Target5
    #endif
#endif

#elif GBUFFERMATERIAL_COUNT == 6

#define OUTPUT_GBUFFER(NAME)                            \
        out GBufferType0 MERGE_NAME(NAME, 0) : SV_Target0,    \
        out GBufferType1 MERGE_NAME(NAME, 1) : SV_Target1,    \
        out GBufferType2 MERGE_NAME(NAME, 2) : SV_Target2,    \
        out GBufferType3 MERGE_NAME(NAME, 3) : SV_Target3,    \
        out GBufferType4 MERGE_NAME(NAME, 4) : SV_Target4,    \
        out GBufferType5 MERGE_NAME(NAME, 5) : SV_Target5

#define DECLARE_GBUFFER_TEXTURE(NAME)   \
        TEXTURE2D(MERGE_NAME(NAME, 0));  \
        TEXTURE2D(MERGE_NAME(NAME, 1));  \
        TEXTURE2D(MERGE_NAME(NAME, 2));  \
        TEXTURE2D(MERGE_NAME(NAME, 3));  \
        TEXTURE2D(MERGE_NAME(NAME, 4));  \
        TEXTURE2D(MERGE_NAME(NAME, 5));

#define FETCH_GBUFFER(NAME, TEX, unCoord2)                                        \
        GBufferType0 MERGE_NAME(NAME, 0) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 0), unCoord2); \
        GBufferType1 MERGE_NAME(NAME, 1) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 1), unCoord2); \
        GBufferType2 MERGE_NAME(NAME, 2) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 2), unCoord2); \
        GBufferType3 MERGE_NAME(NAME, 3) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 3), unCoord2); \
        GBufferType4 MERGE_NAME(NAME, 4) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 4), unCoord2); \
        GBufferType5 MERGE_NAME(NAME, 5) = LOAD_TEXTURE2D(MERGE_NAME(TEX, 5), unCoord2);

#define ENCODE_INTO_GBUFFER(SURFACE_DATA, BAKE_DIFFUSE_LIGHTING, NAME) EncodeIntoGBuffer(SURFACE_DATA, BAKE_DIFFUSE_LIGHTING, MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3), MERGE_NAME(NAME, 4), MERGE_NAME(NAME, 5))
#define DECODE_FROM_GBUFFER(NAME, FEATURE_FLAGS, BSDF_DATA, BAKE_DIFFUSE_LIGHTING) DecodeFromGBuffer(MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3), MERGE_NAME(NAME, 4), MERGE_NAME(NAME, 5), FEATURE_FLAGS, BSDF_DATA, BAKE_DIFFUSE_LIGHTING)
#define MATERIAL_FEATURE_FLAGS_FROM_GBUFFER(NAME) MaterialFeatureFlagsFromGBuffer(MERGE_NAME(NAME, 0), MERGE_NAME(NAME, 1), MERGE_NAME(NAME, 2), MERGE_NAME(NAME, 3), MERGE_NAME(NAME, 4), MERGE_NAME(NAME, 5))

#if SHADEROPTIONS_BAKED_SHADOW_MASK_ENABLE
    #define OUTPUT_GBUFFER_SHADOWMASK(NAME) ,out float4 NAME : SV_Target6
    #if SHADEROPTIONS_VELOCITY_IN_GBUFFER
    #define OUTPUT_GBUFFER_VELOCITY(NAME) ,out float4 NAME : SV_Target7
    #endif
#else
    #if SHADEROPTIONS_VELOCITY_IN_GBUFFER
    #define OUTPUT_GBUFFER_VELOCITY(NAME) ,out float4 NAME : SV_Target6
    #endif
#endif

#endif

#if SHADEROPTIONS_BAKED_SHADOW_MASK_ENABLE
#define ENCODE_SHADOWMASK_INTO_GBUFFER(SHADOWMASK, NAME) EncodeShadowMask(SHADOWMASK, NAME)
#else
#define OUTPUT_GBUFFER_SHADOWMASK(NAME)
#define ENCODE_SHADOWMASK_INTO_GBUFFER(SHADOWMASK, NAME)
#endif

#if SHADEROPTIONS_VELOCITY_IN_GBUFFER
#define ENCODE_VELOCITY_INTO_GBUFFER(VELOCITY, NAME) EncodeVelocity(VELOCITY, NAME)
#else
#define OUTPUT_GBUFFER_VELOCITY(NAME)
#define ENCODE_VELOCITY_INTO_GBUFFER(VELOCITY, NAME)
#endif

#endif // #ifdef GBUFFERMATERIAL_COUNT

#endif // UNITY_MATERIAL_INCLUDED
