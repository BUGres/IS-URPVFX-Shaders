Shader "VFX/vfx_shader_knife"
{
    Properties
    {
        [MainTexture][NoScaleOffset] _MainTex ("MainTexture", 2D) = "white" {}
        [MainColor][HDR] _MainCol ("MainColor", Color) = (1, 1, 1, 1)
        
        [NoScaleOffset] _Noise ("Noise", 2D) = "white" {}
        _Tim("时间（或者是刀光转动的进度） as Texcoord0.z", Range(0, 1)) = 0
        
        [Header(Edge)] _NoiseMul("边缘（0.5>value>0）", Vector) = (0,0,0,0)
        _NoisePow("边缘形状", Range(0, 8)) = 1
        [Toggle] _NoiseView("预览边缘", Float) = 0
        
        [HDR] _NoiseColor3("噪声层1（高光外边层）", Color) = (1, 1, 1, 1)
        [HDR] _NoiseColor2("噪声层2（中层）", Color) = (1, 1, 1, 1)
        [HDR] _NoiseColor1("噪声层3（底层）", Color) = (1, 1, 1, 1)
        
        [Header(RT)][Toggle] _RtUse("是否将Rt用于MainTexture（用屏幕渲染结果作为渲染输入）", Float) = 0
        
        [Header(Flow)][Toggle] _FlowUse("UV流动功能（一般搭配RT使用）", Float) = 0
        _FlowScale("流动噪声UV缩放(xy)和时间移动(zw)", Vector) = (1, 1, 0, 0)
        _FlowMul("流动强度", Range(0, 1)) = 0
        
        [Header(Dissolve)][Toggle] _DissolveUse("溶解功能（配合下面的溶解贴图）", Float) = 0
        [NoScaleOffset] _DissolveTex("溶解贴图", 2D) = "white"{}
        _Dissolve("溶解进度 as Texcoord0.w", Range(0, 1)) = 0
        _DissolveScale("溶解进度UV缩放(xy)和时间移动(zw)", Vector) = (1, 1, 0, 0)
        
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
            float4 _MainCol;
            float4 _NoiseMul;
            float _NoisePow;
            float _NoiseView;
            sampler2D _Noise;
            float4 _NoiseColor1;
            float4 _NoiseColor2;
            float4 _NoiseColor3;

            float _RtUse;

            float _FlowUse;
            float4 _FlowScale;
            float _FlowMul;

            float _Tim;

            float _DissolveUse;
            sampler2D _DissolveTex;
            float _Dissolve;
            float4 _DissolveScale;
            
            struct appdata
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                // float4 tangent      : TANGENT;
                float4 color        : COLOR;
                float4 uv           : TEXCOORD0;
            };

            struct v2g
            {
                float4 positionHCS  : SV_POSITION;
                float4 color        : COLOR;
                float4 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
            };

            struct g2f
            {
                float4 positionHCS  : SV_POSITION;
                float4 color        : COLOR;
                float4 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
            };

            v2g vert(appdata v)
            {
                v2g o;
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionHCS = TransformObjectToHClip(v.positionOS);
                
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
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float2 screenUV = i.positionHCS.xy / _ScaledScreenParams.xy;

                i.uv.x = saturate(i.uv.x);
                i.uv.y = saturate(i.uv.y);
                
                float NoiseMul = ((i.uv.x < _NoiseMul.x) ? i.uv.x / _NoiseMul.x : 1) *
                    ((i.uv.x > (1 - _NoiseMul.y)) ? (1 - i.uv.x) / _NoiseMul.y : 1) *
                    ((i.uv.y < _NoiseMul.z) ? i.uv.y / _NoiseMul.z : 1) *
                    ((i.uv.y > (1 - _NoiseMul.w)) ? (1 - i.uv.y) / _NoiseMul.w : 1);
                NoiseMul = pow(NoiseMul, _NoisePow);
                if (_NoiseView == 1) return float4(NoiseMul, NoiseMul, NoiseMul, 1);
                
                float2 uv = _RtUse * screenUV + (1 - _RtUse) * i.uv;
                
                float perlin = PerlinNoise(i.uv * _FlowScale.xy + _Time * _FlowScale.zw);
                float perlin2 = PerlinNoise(float2(1.2345, -3.4567) + i.uv * _FlowScale.xy + _Time * _FlowScale.zw);

                float2 uvOffset = saturate(min(2 * (_Tim + i.uv.z), -2 * (_Tim + i.uv.z) + 2)) * NoiseMul * _FlowUse * _FlowMul * float2(perlin, perlin2);
                float4 col = tex2D(_MainTex, uv + uvOffset) * _MainCol;
                float4 noiseColor = tex2D(_Noise, i.uv + float2((_Tim + i.uv.z) * 2 - 1, 0) + uvOffset);
                float4 dissolveColor = tex2D(_DissolveTex, _DissolveScale.xy * i.uv) * _MainCol;
                
                float noiseLevel1 = noiseColor.x;
                float noiseLevel2 = noiseColor.y;
                float noiseLevel3 = noiseColor.z;

                float4 saveCol = col;
                
                col = noiseLevel1 * _NoiseColor1 + (1 - noiseLevel1) * col;
                col = noiseLevel2 * _NoiseColor2 + (1 - noiseLevel2) * col;
                col += noiseLevel3 * _NoiseColor3;
                // 刀光色融合四个边缘
                col = (1 - NoiseMul) * saveCol + (NoiseMul) * col;
                // float dissolve = (1 - (_Dissolve + i.uv.w) *
                //     saturate(1 - (_Dissolve + i.uv.w)) * (1 - dissolveColor.x));
                float dissolve = (1 - _Dissolve * (1 - dissolveColor.x)) * (1 - _Dissolve);
                col = _DissolveUse * ((1 - dissolve) * saveCol + dissolve * col) + (1 - _DissolveUse) * col;
                col.a = 1;
                
                return col;
            }
            ENDHLSL
        }
    }

    CustomEditor "vfx_shader_knife"
}
