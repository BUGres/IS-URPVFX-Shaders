Shader "VFX/vfx_shader_inkwash"
{
    Properties
    {
        [MainTexture][NoScaleOffset] _MainTex ("MainTexture", 2D) = "white" {}
        [MainColor][HDR] _MainCol ("MainColor", Color) = (1, 1, 1, 1)
        
        [NoScaleOffset] _Noise ("Noise", 2D) = "white" {}
        _NDVPow("NDV指数", Range(0, 16)) = 1
        _NDVMul("NDV乘数", Range(0, 16)) = 1
        _MainTexUVScale("主贴图UV缩放", Range(0, 8)) = 1
        _NoiseUVScale("辅助图UV缩放", Range(0, 16)) = 1
        _NoiseAlphaPow("辅助图Alpha指数", Range(0, 16)) = 1
        
        [Toggle] _NDVFlashToggle("NDV是否闪光", Float) = 0
        [HDR] _NDVFlashCol("NDV闪光色", Color) = (1,1,1,1)
        _NDV2Pow("NDV闪光选区", Range(0, 16)) = 1
        _NDV2Step("NDV闪光选区2", Range(0, 1)) = 0
        _NDVFlash("NDV闪光进度", Range(0, 1)) = 0
        
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
            #pragma geometry geom
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            sampler2D _MainTex;
            sampler2D _Noise;
            float4 _MainCol;

            float _NDVPow;
            float _NDVMul;

            float _MainTexUVScale;
            float _NoiseUVScale;
            float _NoiseAlphaPow;

            float _NDVFlash;
            float4 _NDVFlashCol;
            float _NDV2Pow;
            float _NDV2Step;
            float _NDVFlashToggle;

            struct appdata
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                // float4 tangent      : TANGENT;
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
            };

            struct v2g
            {
                float4 positionHCS  : SV_POSITION;
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
            };

            struct g2f
            {
                float4 positionHCS  : SV_POSITION;
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
            };

            v2g vert(appdata v)
            {
                v2g o;
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.color = v.color;
                o.uv = v.uv;
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                for (int i = 0; i < 3; i++)
                {
                    v2g vertex = input[i];
                    g2f g;
                    g.positionHCS = vertex.positionHCS;
                    g.color = vertex.color;
                    g.uv = vertex.uv;
                    g.normalWS = vertex.normalWS;
                    g.positionWS = vertex.positionWS;
                    triStream.Append(g);
                }
            }

            float4 frag(g2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv * _NoiseUVScale) * _MainCol;
                float4 noise = tex2D(_Noise, i.uv * _NoiseUVScale);
                float noisea = noise.x;
                
                float3 viewDirWS = normalize(GetWorldSpaceNormalizeViewDir(i.positionWS));
                float NDV = saturate(dot(i.normalWS, viewDirWS));
                float NDV2 = pow(NDV, _NDV2Pow);
                NDV2 = (1 - NDV2) > _NDV2Step ? (1 - NDV2) : 0;
                NDV = pow(NDV, _NDVPow);
                NDV *= _NDVMul;
                NDV += noisea / 4;
                NDV = saturate(NDV);
                col *= float4(NDV, NDV, NDV, 1);
                // return float4(NDV, NDV, NDV, 1);
                col.a *= pow(max(1 - NDV, 1 - noisea), _NoiseAlphaPow);
                return col + NDV2 * _NDVFlashToggle * _NDVFlash * _NDVFlashCol;
            }
            ENDHLSL
        }
    }

    CustomEditor "vfx_shader_inkwash"
}
