Shader "VFX/vfx_shader_2d"
{
    Properties
    {
        [MainTexture][NoScaleOffset] _MainTex ("MainTexture", 2D) = "white" {}
        [MainColor][HDR] _MainCol ("MainColor", Color) = (1, 1, 1, 1)
        
        [NoScaleOffset] _Noise ("Noise", 2D) = "white" {}
        
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0
        [HideInInspector] _AlphaToMask("AlphaToMask", Int) = 1
        [HideInInspector] _SRGB("source factor RGB", Int) = 1
        [HideInInspector] _DRGB("destination factor RGB", Int) = 0
        [HideInInspector] _SA("source factor alpha", Int) = 0
        [HideInInspector] _DA("destination factor alpha", Int) = 0
        [HideInInspector] _ColorMask("ColorMask", Int) = 15
        [HideInInspector] _Conservative("Conservative", Int) = 0
        [HideInInspector] _Cull("Cull", Int) = 2
        [HideInInspector] _OffsetFactor("OffsetFactor", Range(-1, 1)) = 0
        [HideInInspector] _OffsetUnits("OffsetUnits", Range(-1, 1)) = 0
        [HideInInspector] _ZClip("ZClip", Int) = 1
        [HideInInspector] _ZWrite("ZWrite", Int) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        AlphaToMask [_AlphaToMask]
        ColorMask [_ColorMask]
        Conservative [_Conservative]
        Cull [_Cull]
        Offset [_OffsetFactor], [_OffsetUnits]
        ZClip [_ZClip]
        ZWrite [_ZWrite]
        Blend [_SRGB] [_DRGB], [_SA] [_DA]

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            // #pragma geometry geom
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            sampler2D _MainTex;
            sampler2D _Noise;
            float4 _MainCol;
            float _Cutoff;
            float _AlphaToMask;

            struct appdata
            {
                float4 positionOS   : POSITION;
                // float3 normalOS     : NORMAL;
                // float4 tangent      : TANGENT;
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionHCS  : SV_POSITION;
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
                // float3 normalWS     : TEXCOORD1;
                // float3 positionWS   : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                // o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                // o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.color = v.color;
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv) * _MainCol * i.color;
                float4 noise = tex2D(_Noise, i.uv);
                col *= noise.x;
                if (_AlphaToMask == 1) col.w += _Cutoff;
                return col;
            }
            ENDHLSL
        }
    }

    CustomEditor "vfx_shader_2d"
}
