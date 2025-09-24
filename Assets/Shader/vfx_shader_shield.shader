Shader "VFX/vfx_shader_shield"
{
    Properties
    {
        [MainTexture][NoScaleOffset] _MainTex ("MainTexture", 2D) = "white" {}
        [MainColor][HDR] _MainCol ("MainColor", Color) = (1, 1, 1, 1)
        
        [NoScaleOffset] _Noise ("Noise", 2D) = "white" {}
        _NoiseWeight("噪声强度", Range(0, 1)) = 0
        
        [Header(RT)][Toggle] _RtUse("是否将Rt用于MainTexture（用屏幕渲染结果作为渲染输入）", Float) = 0
        
        [Header(Flow)][Toggle] _FlowUse("UV流动功能（一般搭配RT使用）", Float) = 0
        _FlowScale("流动噪声UV缩放(xy)和时间移动(zw)", Vector) = (1, 1, 0, 0)
        _FlowMul("流动强度", Range(0, 1)) = 0
        
        [Header(NDV)][Toggle] _NDVUse("NDV功能是否启用(正交相机无效，正交时不要启用)", Float) = 0
        [HDR] _NDVColor("NDVColor边缘颜色", Color) = (1, 1, 1, 1)
        _NDVPow("NDV选取Pow运算，用于更改提取部分，此值分布不均匀(default = 1)", Range(0, 16)) = 1
        _NDVAddPerlin("NDV增加上面的柏林噪声（流动uv噪声）", Range(0, 1)) = 0
        
        [Header(Vertex)] _VertexFlowScale("顶点流动噪声UV缩放(xy)和时间移动(zw)", Vector) = (1, 1, 0, 0)
        _VertexFlowPow("顶点流动的修正Pow（用于修正默认球形顶部，但是影响到中心位置了）", Range(0, 2)) = 1
        _VertexFlowMul("顶点流动的修正Mul（用于修正默认球形顶部，但是影响到中心位置了）", Range(0, 4)) = 1
        
        [Header(BlinnPhong)][Toggle] _BlinnPhongUse("高光是否使用", Float) = 0
        _Gloss("BlinnPhong高光系数", Range(0, 2)) = 1
        _SpecularPow("高光Pow", Range(0, 64)) = 1
        [HDR] _SpecularCol("高光色（Alpha控制Mul强度）", Color) = (1,1,1,1)
        _WorldSpaceLightDir("世界主光朝向（固定值以调控特效，推荐默认值<0, -1, 0>）", Vector) = (0, -1, 0, 0)
        
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
            sampler2D _Noise;
            float _NoiseWeight;

            float _RtUse;

            float _FlowUse;
            float4 _FlowScale;
            float _FlowMul;

            float _NDVUse;
            float4 _NDVColor;
            float _NDVPow;
            float _NDVAddPerlin;

            float4 _VertexFlowScale;
            float _VertexFlowPow;
            float _VertexFlowMul;

            float _BlinnPhongUse;
            float _Gloss;
            float _SpecularPow;
            float4 _SpecularCol;

            float4 _WorldSpaceLightDir;
            
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

                float2 mirrorUV = v.uv;
                mirrorUV.x = mirrorUV.x > 0.5 ? mirrorUV.x : 1 - mirrorUV.x;
                
                float perlin = PerlinNoise(mirrorUV * _VertexFlowScale.xy + _Time * _VertexFlowScale.zw);
                perlin *= pow((0.5 - abs(v.positionOS.y)) * 2, _VertexFlowPow) * _VertexFlowMul;
                
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                float3 offsetPosition = o.positionWS + perlin * o.normalWS;
                o.positionHCS = TransformObjectToHClip(TransformWorldToObject(offsetPosition));
                
                // o.positionHCS = TransformObjectToHClip(v.positionOS);
                
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

                float2 uv = _RtUse * screenUV + (1 - _RtUse) * i.uv;
                
                float perlin = PerlinNoise(i.uv * _FlowScale.xy + _Time * _FlowScale.zw);
                float perlin2 = PerlinNoise(float2(1.2345, -3.4567) + i.uv * _FlowScale.xy + _Time * _FlowScale.zw);
                
                float4 col = tex2D(_MainTex, uv + _FlowUse * _FlowMul * float2(perlin, perlin2)) * _MainCol;
                float4 noiseColor = tex2D(_Noise, i.uv + _FlowUse * _FlowMul * float2(perlin, perlin2));
                
                col = col + _NoiseWeight * noiseColor; // _NoiseWeight * noiseColor + (1 - _NoiseWeight) * col;
                col.a = 1;

                float3 worldLightDir = normalize(_WorldSpaceLightDir.xyz);
                float3 halfDir = normalize(worldLightDir + viewDirWS);
                float specular = _SpecularCol.w * pow(_BlinnPhongUse * pow(max(0, dot(i.normalWS, halfDir)), _Gloss), _SpecularPow);
                col += float4(specular, specular, specular, 0) * _SpecularCol;
                
                float ndv = 1 - saturate(dot(viewDirWS, i.normalWS));
                ndv = pow(ndv, _NDVPow);
                // ndv *= perlin;
                ndv += perlin * _NDVAddPerlin;
                col += _NDVUse * float4(ndv * _NDVColor.xyz, 0);
                
                return col;
            }
            ENDHLSL
        }
    }

    CustomEditor "vfx_shader_shield"
}
