Shader "VFX/vfx_shader_vertexFire"
{
    Properties
    {
        [MainTexture][NoScaleOffset] _MainTex ("MainTexture", 2D) = "white" {}
        _MainTex_TO("MainTexture_TrillingOffset", Vector) = (1, 1, 0, 0)
        [NoScaleOffset] _Mask ("Mask", 2D) = "white" {}
        [NoScaleOffset] _Noise ("VertexNormalNoise", 2D) = "black" {}
        _NoiseWeight("Noise强度", Range(0, 5)) = 0
        _NoiseScale("Noise缩放", Range(0, 5)) = 1
        [MainColor][HDR] _MainCol ("MainColor", Color) = (1, 1, 1, 1)
     
        [Header(Geometry)] _Len("FireLength(WS)", Range(0, 1)) = 1
        _UVScale("UVScale(归一化UV使用)", Float) = 1
        _TarPos("TarPos(OS)", Vector) = (1, 0, 0, 0)
        _TarPosPower("TarPosPower", Range(0, 1)) = 0
        
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
            Cull Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_Mask);
            SAMPLER(sampler_Mask);
            sampler2D _Noise;

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
                float3 normalWS     : NORMAL;
                // float3 normalWS     : TEXCOORD1;
                float3 positionWS   : TEXCOORD1;
                float2 sUV          : TEXCOORD2;
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

            float _Len;
            float4 _TarPos;
            float _TarPosPower;
            float _UVScale;
            float _NoiseWeight;
            float _NoiseScale;
            [maxvertexcount(6)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                // for (int i = 0; i < 3; i++)
                // {
                //     v2g vertex = input[i];
                //     g2f g;
                //     g.positionHCS = vertex.positionHCS;
                //     g.color = vertex.color;
                //     g.uv = vertex.uv;
                //     g.normalWS = vertex.normalWS;
                //     g.positionWS = vertex.positionWS;
                //     triStream.Append(g);
                // }

                v2g i0 = input[0];
                v2g i1 = input[1];
                // v2g i2 = input[2];
                g2f g0;
                g2f g1;
                g2f g2;
                g2f g3;

                // g3 - g2(uv 1, 0)
                // |  x  |
                // g0 - g1(uv 0, 0)
                // i0 - i1
                g0.sUV = half2(0, 1);
                g1.sUV = half2(0, 0);
                g2.sUV = half2(1, 0);
                g3.sUV = half2(1, 1);

                // 归一化UV（并不是1，使所有UV块在ViewSpace下具有相同的缩放）
                float distanceVS = distance(float3(0, 0, 0), TransformWorldToViewNormal(i0.positionWS - i1.positionWS));
                float uvScale = 1; // distanceVS * _UVScale;
                float3 posOS = TransformWorldToObject(i0.positionWS);
                float uvadd = (sin((abs(posOS.x) + abs(posOS.y) + abs(posOS.z)) * 100000) + 1) / 2;

                g0.positionWS = i0.positionWS;
                g0.positionHCS = i0.positionHCS;
                g0.color = i0.color;
                g0.uv = half2(uvadd, uvadd + uvScale);

                g1.positionWS = i1.positionWS;
                g1.positionHCS = i1.positionHCS;
                g1.color = i1.color;
                g1.uv = half2(uvadd, uvadd);

                g2.positionWS = lerp(i1.positionWS + i1.normalWS * _Len, TransformObjectToWorld(_TarPos.xyz), _TarPosPower);
                g2.positionWS += (2 * tex2Dgrad(_Noise, i1.uv * _NoiseScale, 0, 0) - float3(1, 1, 1)) / 2 * _NoiseWeight;
                g2.positionHCS = TransformWorldToHClip(g2.positionWS);
                g2.color = i1.color;
                g2.uv = half2(uvadd + uvScale, uvadd);

                g3.positionWS = lerp(i0.positionWS + i0.normalWS * _Len, TransformObjectToWorld(_TarPos.xyz), _TarPosPower);
                g3.positionWS += (2 * tex2Dgrad(_Noise, i0.uv * _NoiseScale, 0, 0) - float3(1, 1, 1)) / 2 * _NoiseWeight;
                g3.positionHCS = TransformWorldToHClip(g3.positionWS);
                g3.color = i0.color;
                g3.uv = half2(uvadd + uvScale, uvadd + uvScale);

                float3 normal = cross(normalize(i1.positionWS - i0.positionWS), normalize(i1.normalWS));
                g0.normalWS = normal;
                g1.normalWS = normal;
                g2.normalWS = normal;
                g3.normalWS = normal;
                
                triStream.Append(g0);
                triStream.Append(g1);
                triStream.Append(g2);

                triStream.Append(g0);
                triStream.Append(g2);
                triStream.Append(g3);
            }

            float4 _MainTex_TO;
            float4 _MainCol;
            float4 frag(g2f i) : SV_Target
            {
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float mask = _Mask.SampleBias(sampler_Mask, i.sUV, 0).x;
                // return mask;
                float4 col = _MainTex.SampleBias(sampler_MainTex, ((i.uv + _MainTex_TO.zw * _Time) * _MainTex_TO.xy), 0);
                col = pow(col, 2);
                col = col * _MainCol * mask * abs(dot(i.normalWS, viewDirWS));
                return col;
            }
            ENDHLSL
        }
    }

    CustomEditor "vfx_shader_vertexFire"
}
