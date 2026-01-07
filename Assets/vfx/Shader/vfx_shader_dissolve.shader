Shader "VFX/vfx_shader_dissolve"
{
    Properties
    {
        [Header(MainTexture)][MainTexture][NoScaleOffset] _MainTex ("MainTexture", 2D) = "white" {}
        [Toggle] _MainTexToMask("主贴图作为Noise使用", Float) = 0
        _MainTexScale("主贴图UV缩放(xy)和时间移动(zw)", Vector) = (1, 1, 0, 0)
        
        [Header(MainColor)][MainColor][HDR] _MainCol ("MainColor", Color) = (1, 1, 1, 1)
        
        [Header(Noise)][NoScaleOffset] _Noise ("Noise", 2D) = "white" {}
        _DissolveScale("噪声贴图UV缩放(xy)和时间移动(zw)", Vector) = (1, 1, 0, 0)
        [Header(NoiseMask)][NoScaleOffset] _NoiseMask ("NoiseMask(不受下面UV缩放和时间移动影响)", 2D) = "white" {}
        _NoiseMaskWeight("NoiseMask强度", Range(1, 10)) = 1
        
        [Header(Dissolve)][Toggle] _DissolveType("软硬溶解（勾选此项为软溶解）", Range(0, 1)) = 0
        _Dissolve("溶解进度", Range(0, 1)) = 0
        
        [Header(Edge)][Toggle] _Edge("启用溶解边缘", Float) = 0
        [HDR] _EdgeColor("NDVColor边缘颜色", Color) = (1, 1, 1, 1)
        _EdgeLen("溶解边缘长度", Range(0, 1)) = 0
        
        [Header(NDV)][Toggle] _NDVUse("NDV功能是否启用(正交相机无效，正交时不要启用)", Float) = 0
        [HDR] _NDVColor("NDVColor边缘颜色", Color) = (1, 1, 1, 1)
        _NDVPow("NDV选取Pow运算，用于更改提取部分，此值分布不均匀(default = 1)", Range(0, 16)) = 1
        
        [Header(Flow)][Toggle] _FlowUse("UV流动功能", Float) = 0
        _FlowScale("流动噪声UV缩放(xy)和时间移动(zw)", Vector) = (1, 1, 0, 0)
        _FlowMul("流动强度", Range(0, 1)) = 0
        
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
            #include "StandardNoise.hlsl"

            sampler2D _MainTex;
            float _MainTexToMask;
            float4 _MainTexScale;
            sampler2D _Noise;
            float _Cutoff;
            float4 _MainCol;

            float _AlphaToMask;

            sampler2D _NoiseMask;
            float _NoiseMaskWeight;

            float _DissolveType;
            float _Dissolve;
            float4 _DissolveScale;

            float _Edge;
            float4 _EdgeColor;
            float _EdgeLen;
            
            float _NDVUse;
            float4 _NDVColor;
            float _NDVPow;

            float _FlowUse;
            float4 _FlowScale;
            float _FlowMul;

            struct appdata
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                // float4 tangent      : TANGENT;
                float4 color        : COLOR;
                float4 uv           : TEXCOORD0;
                float4 custom       : TEXCOORD1;
            };

            struct v2g
            {
                float4 positionHCS  : SV_POSITION;
                float4 color        : COLOR;
                float4 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
                float4 custom       : TEXCOORD3;
            };

            struct g2f
            {
                float4 positionHCS  : SV_POSITION;
                float4 color        : COLOR;
                float4 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
                float4 custom       : TEXCOORD3;
            };

            v2g vert(appdata v)
            {
                v2g o;
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.color = v.color;
                o.uv = v.uv;
                o.custom = v.custom;
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
                    g.custom = vertex.custom;
                    triStream.Append(g);
                }
            }
            
            float4 frag(g2f i) : SV_Target
            {
                float4 noisemask = tex2D(_NoiseMask, i.uv).x;
                i.uv.x = (i.uv.x + i.uv.w) % 1;
                
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float NDV = pow(saturate(1 - dot(viewDirWS, i.normalWS)), _NDVPow) * _NDVUse;
                // return float4(NDV, NDV, NDV, 1);
                
                float perlin = PerlinNoise(i.uv * _FlowScale.xy + _Time * _FlowScale.zw) * 2 - 1;
                float perlin2 = PerlinNoise(-i.uv * _FlowScale.xy + _Time * _FlowScale.zw) * 2 - 1;
                
                float4 col;
                if (_MainTexToMask != 0)
                {
                    float mttmColorAlpha = tex2D(_MainTex, i.uv * _MainTexScale.xy + _Time * _MainTexScale.zw +
                        _FlowUse * _FlowMul * float2(perlin, perlin2)).x;
                    col = float4(1, 1, 1, mttmColorAlpha) * _MainCol * i.color;
                }
                else
                {
                    col = tex2D(_MainTex, i.uv * _MainTexScale.xy + _Time * _MainTexScale.zw +
                    _FlowUse * _FlowMul * float2(perlin, perlin2)) * _MainCol * i.color;
                }
                
                float4 noise = tex2D(_Noise, i.uv * _DissolveScale.xy +
                    _Time * _DissolveScale.zw +
                    _FlowUse * _FlowMul * float2(perlin, perlin2));
                

                if (_DissolveType == 0)
                {
                    col.w *= ((noise.x) > (_Dissolve + i.uv.z)) ? 1 : 0;
                    col.w = saturate(col.w);
                    col += _Edge * float4(_EdgeColor.x, _EdgeColor.y, _EdgeColor.z, 1) *
                        (((noise.x) > (-_EdgeLen * (1 -(_Dissolve + i.uv.z)) + _Dissolve + i.uv.z)) &&
                          ((noise.x) < (_Dissolve + i.uv.z))  ? 1 : 0);
                }
                else
                {
                    col.w = (col.w * noise.x + 1 - 2 * (_Dissolve + i.uv.z));
                    float colorsave = col.w;
                    col.w = saturate(col.w);

                    
                    // col += _Edge * float4(_EdgeColor.x, _EdgeColor.y, _EdgeColor.z, 0) * (((colorsave > 0) && (colorsave < _EdgeLen)) ? 1 : 0);
                }
                
                if (_NDVUse == 1)
                {
                    float ndv = 1 - saturate(dot(viewDirWS, i.normalWS));
                    ndv = pow(ndv, _NDVPow);
                    col += float4(ndv * _NDVColor.xyz, 0);
                }

                // return noisemask;
                // col.a = max(col.a, noisemask);
                col *= noisemask;
                if (_DissolveType == 0)
                {
                    col.a *= pow(10, _NoiseMaskWeight - 1);
                }
                else
                {
                    col.a *= pow(10, _NoiseMaskWeight - 1);
                    if (_Edge == 1)
                    {
                        float tmp_a = saturate(_EdgeLen * (col.a - 1));
                        col.a = saturate(col.a) - tmp_a;
                    }
                }
                
                if (_AlphaToMask == 1) col.w += _Cutoff;
                
                return col;
            }
            ENDHLSL
        }
    }

    CustomEditor "vfx_shader_dissolve"
}
