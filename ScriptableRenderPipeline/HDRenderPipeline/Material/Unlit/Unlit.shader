Shader "HDRenderPipeline/Unlit"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _ColorMap("ColorMap", 2D) = "white" {}

        _DistortionVectorMap("DistortionVectorMap", 2D) = "black" {}

        _EmissiveColor("EmissiveColor", Color) = (0, 0, 0)
        _EmissiveColorMap("EmissiveColorMap", 2D) = "white" {}
        _EmissiveIntensity("EmissiveIntensity", Float) = 0

        [ToggleOff] _DistortionEnable("Enable Distortion", Float) = 0.0
        [ToggleOff] _DistortionOnly("Distortion Only", Float) = 0.0
        [ToggleOff] _DistortionDepthTest("Distortion Depth Test Enable", Float) = 0.0
        [Enum(Add, 0, Multiply, 1)] _DistortionBlendMode("Distortion Blend Mode", Int) = 0
        [HideInInspector] _DistortionSrcBlend("Distortion Blend Src", Int) = 0
        [HideInInspector] _DistortionDstBlend("Distortion Blend Dst", Int) = 0
        [HideInInspector] _DistortionBlurSrcBlend("Distortion Blur Blend Src", Int) = 0
        [HideInInspector] _DistortionBlurDstBlend("Distortion Blur Blend Dst", Int) = 0
        [HideInInspector] _DistortionBlurBlendMode("Distortion Blur Blend Mode", Int) = 0
        _DistortionScale("Distortion Scale", Float) = 1
        _DistortionBlurScale("Distortion Blur Scale", Float) = 1
        _DistortionBlurRemapMin("DistortionBlurRemapMin", Float) = 0.0
        _DistortionBlurRemapMax("DistortionBlurRemapMax", Float) = 1.0

        [ToggleOff]  _AlphaCutoffEnable("Alpha Cutoff Enable", Float) = 0.0
        _AlphaCutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        // Blending state
        [HideInInspector] _SurfaceType("__surfacetype", Float) = 0.0
        [HideInInspector] _BlendMode("__blendmode", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _CullMode("__cullmode", Float) = 2.0
        [HideInInspector] _ZTestMode("_ZTestMode", Int) = 8

        [ToggleOff] _DoubleSidedEnable("Double sided enable", Float) = 0.0

        // Caution: C# code in BaseLitUI.cs call LightmapEmissionFlagsProperty() which assume that there is an existing "_EmissionColor"
        // value that exist to identify if the GI emission need to be enabled.
        // In our case we don't use such a mechanism but need to keep the code quiet. We declare the value and always enable it.
        // TODO: Fix the code in legacy unity so we can customize the beahvior for GI
        _EmissionColor("Color", Color) = (1, 1, 1)
    }

    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 ps4 metal  // TEMP: until we go further in dev
    // #pragma enable_d3d11_debug_symbols

    //-------------------------------------------------------------------------------------
    // Variant
    //-------------------------------------------------------------------------------------

    #pragma shader_feature _ALPHATEST_ON
    // #pragma shader_feature _DOUBLESIDED_ON - We have no lighting, so no need to have this combination for shader, the option will just disable backface culling

    #pragma shader_feature _EMISSIVE_COLOR_MAP

    #pragma shader_feature _ _BLENDMODE_LERP _BLENDMODE_ADD _BLENDMODE_SOFT_ADD _BLENDMODE_MULTIPLY _BLENDMODE_PRE_MULTIPLY

    //-------------------------------------------------------------------------------------
    // Define
    //-------------------------------------------------------------------------------------

    #define UNITY_MATERIAL_UNLIT // Need to be define before including Material.hlsl

    //-------------------------------------------------------------------------------------
    // Include
    //-------------------------------------------------------------------------------------

    #include "../../../Core/ShaderLibrary/common.hlsl"
    #include "../../ShaderVariables.hlsl"
    #include "../../ShaderPass/FragInputs.hlsl"
    #include "../../ShaderPass/ShaderPass.cs.hlsl"

    //-------------------------------------------------------------------------------------
    // variable declaration
    //-------------------------------------------------------------------------------------

    #include "../../Material/Unlit/UnlitProperties.hlsl"

    // All our shaders use same name for entry point
    #pragma vertex Vert
    #pragma fragment Frag

    ENDHLSL

    SubShader
    {
        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags{ "LightMode" = "Meta" }

            Cull Off

            HLSLPROGRAM

            // Lightmap memo
            // DYNAMICLIGHTMAP_ON is used when we have an "enlighten lightmap" ie a lightmap updated at runtime by enlighten.This lightmap contain indirect lighting from realtime lights and realtime emissive material.Offline baked lighting(from baked material / light,
            // both direct and indirect lighting) will hand up in the "regular" lightmap->LIGHTMAP_ON.

            #define SHADERPASS SHADERPASS_LIGHT_TRANSPORT
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/UnlitMetaPass.hlsl"
            #include "UnlitData.hlsl"
            #include "../../ShaderPass/ShaderPassLightTransport.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Distortion" // Name is not used
            Tags { "LightMode" = "DistortionVectors" } // This will be only for transparent object based on the RenderQueue index

            Blend [_DistortionSrcBlend] [_DistortionDstBlend], [_DistortionBlurSrcBlend] [_DistortionBlurDstBlend]
            BlendOp Add, [_DistortionBlurBlendOp]
            ZTest [_ZTestMode]
            ZWrite off
            Cull [_CullMode]

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_DISTORTION
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/UnlitDistortionPass.hlsl"
            #include "UnlitData.hlsl"
            #include "../../ShaderPass/ShaderPassDistortion.hlsl"

            ENDHLSL
        }

        // Unlit shader always render in forward
        Pass
        {
            Name ""
            Tags{ "LightMode" = "DepthForwardOnly" }

            Cull[_CullMode]

            ZWrite On

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_DEPTH_ONLY
            #include "../../ShaderVariables.hlsl"
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/UnlitDepthPass.hlsl"
            #include "UnlitData.hlsl"
            #include "../../ShaderPass/ShaderPassDepthOnly.hlsl"

            ENDHLSL
        }

        // Unlit shader always render in forward
        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "ForwardOnly" }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_CullMode]

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_FORWARD_UNLIT
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/UnlitSharePass.hlsl"
            #include "UnlitData.hlsl"
            #include "../../ShaderPass/ShaderPassForwardUnlit.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "ForwardDebugDisplay"
            Tags { "LightMode" = "ForwardOnlyDebugDisplay" }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_CullMode]

            HLSLPROGRAM

            #define DEBUG_DISPLAY
            #define SHADERPASS SHADERPASS_FORWARD_UNLIT
            #include "../../Debug/DebugDisplay.hlsl"
            #include "../../Material/Material.hlsl"
            #include "ShaderPass/UnlitSharePass.hlsl"
            #include "UnlitData.hlsl"
            #include "../../ShaderPass/ShaderPassForwardUnlit.hlsl"

            ENDHLSL
        }
    }

    CustomEditor "Experimental.Rendering.HDPipeline.UnlitGUI"
}
