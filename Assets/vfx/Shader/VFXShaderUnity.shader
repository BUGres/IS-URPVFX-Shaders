Shader "VFX/VFX大一统Shader"
{
    Properties
    {
        [MainTexture] _MainTexture ("主贴图(固有色)", 2D) = "white" {}
        
        _TextureI ("贴图I", 2D) = "white" {}
        [Toggle] _EnableTextureIAlpha("贴图I是否使用Alpha通道", Int) = 0
        _TextureIFlow("uv流动速度", Vector) = (0,0,0,0)
        _TextureIFit("贴图I颜色强度修正", Range(-1, 1)) = 0
        
        _BlendI_II("贴图I和贴图II的叠加方式", Int) = 0
        
        _TextureII ("贴图II", 2D) = "white" {}
        [Toggle] _EnableTextureIIAlpha("贴图II是否使用Alpha通道", Int) = 0
        _TextureIIFlow("uv流动速度", Vector) = (0,0,0,0)
        _TextureIIFit("贴图II颜色强度修正", Range(-1, 1)) = 0
        
        _TextureIII ("贴图III(这里贴遮罩)", 2D) = "white" {}
        [Toggle] _EnableTextureIIIAlpha("贴图III是否使用Alpha通道", Int) = 0
        
        [MainColor][HDR] _MainCol ("叠加HDR颜色", Color) = (1, 1, 1, 1)
        [Toggle] _EnableVertexColor("叠加顶点颜色(也是粒子系统给出的颜色)", Int) = 1
        
        [Toggle] _MixedColorAsAlpha("混合颜色结果作为Alpha", Int) = 1
        
        [Toggle] _Dissolve("溶解功能(影响性能)", Int) = 0
        _DissolveState("溶解进度", Range(0, 1)) = 0
        _DissolveType("溶解类型", Int) = 0
        
        [Toggle] _UVNoise("UV噪声(影响性能)", Int) = 0
        _UVNoiseScale("UV噪声缩放", Range(0, 1)) = 0
        _UVNoiseWeight("UV噪声强度", Range(0, 1)) = 0
        _UVNoiseTimeScale("UV噪声流动速度", Range(0, 10)) = 0
        
        [Toggle] _NDV("菲涅尔效果(影响性能)", Int) = 0
        _NDVMul("菲涅尔强度", Range(0, 1)) = 0
        _NDVPow("边缘情况", Range(0, 1)) = 0
        [HDR] _NDVCol("菲涅尔发光颜色", Color) = (1,1,1,1)
        
        [HideInInspector] _RenderType("", Int) = 0
        
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _AlphaToMask("AlphaToMask", Int) = 0
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
            // KeyWards
            // #pragma multi_compile
            #pragma multi_compile __ _DISSOLVE_ON
            #pragma multi_compile __ _UVNOISE_ON
            #pragma multi_compile __ _NDV_ON
            
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "StandardNoise.hlsl"

            CBUFFER_START(UnityPerMaterial)
            
            TEXTURE2D(_MainTexture);
            SAMPLER(sampler_MainTexture);
            float4 _MainTexture_ST;
            
            TEXTURE2D(_TextureI);
            SAMPLER(sampler_TextureI);
            TEXTURE2D(_TextureII);
            SAMPLER(sampler_TextureII);
            TEXTURE2D(_TextureIII);
            SAMPLER(sampler_TextureIII);
            float4 _TextureI_ST;
            float4 _TextureII_ST;
            float4 _TextureIII_ST;
            float4 _TextureIFlow;
            float4 _TextureIIFlow;
            float _TextureIFit;
            float _TextureIIFit;
            int _BlendI_II;

            int _EnableTextureIAlpha;
            int _EnableTextureIIAlpha;
            int _EnableTextureIIIAlpha;
            
            float4 _MainCol;
            int _EnableVertexColor;
            int _MixedColorAsAlpha;

            float _DissolveState;
            int _DissolveType;

            float _UVNoiseScale;
            float _UVNoiseWeight;
            float _UVNoiseTimeScale;

            float _NDVPow;
            float4 _NDVCol;
            float _NDVMul;

            int _RenderType;

            CBUFFER_END

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
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                
                #ifdef _UVNOISE_ON
                float2 fakeuv = float2((PerlinNoise((i.uv + 5 * _UVNoiseTimeScale * float2(-_Time.x, _Time.x)) * (_UVNoiseScale * 10 + 1)) * 2 - 1) * _UVNoiseWeight + i.uv.x,
                    (PerlinNoise(-(i.uv + 5 * _UVNoiseTimeScale * float2(_Time.x, -_Time.x)) * (_UVNoiseScale * 10 + 1)) * 2 - 1) * _UVNoiseWeight + i.uv.y);
                #else
                float2 fakeuv = i.uv;
                #endif


                
                // 下面进行固有色确定
                float4 baseColor = float4(1, 1, 1, 1);
                if (_RenderType == 5)
                {
                    // 从_RenderType判定，主贴图输入是RT，RT不按照现有UV采样
                    // float3 viewDirWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                    float2 screenUV = i.positionHCS.xy / _ScaledScreenParams.xy;
                    float2 uvOffset = fakeuv - i.uv;
                    baseColor = _MainTexture.SampleBias(sampler_MainTexture, ((screenUV + uvOffset) * _MainTexture_ST.xy) + _MainTexture_ST.zw, 0);
                }
                else
                {
                    baseColor = _MainTexture.SampleBias(sampler_MainTexture, (fakeuv * _MainTexture_ST.xy) + _MainTexture_ST.zw, 0);
                }
                if (_EnableVertexColor == 1) // 是否启用顶点颜色
                {
                    baseColor *= i.color * _MainCol;
                }
                else
                {
                    baseColor *= _MainCol;
                }
                #ifdef _NDV_ON
                baseColor += _NDVCol * pow(1 - saturate(dot(i.normalWS, viewDirWS)),
                    _NDVPow * 8 // pow指数，需要特殊计算
                    ) * _NDVMul;
                return baseColor;
                #endif
                

                
                // 采样贴图I 贴图II 贴图III
                float4 f4 = _TextureI.SampleBias(sampler_TextureI, (fakeuv * _TextureI_ST.xy) + _TextureI_ST.zw + _TextureIFlow.xy * _Time, 0);
                float3 texI = f4.xyz * ((_EnableTextureIAlpha == 1) ? f4.w : 1);
                if (_TextureIFit > 0)
                {
                    texI = pow(texI, _TextureIFit * 7 + 1);
                }
                else
                {
                    texI = pow(texI, 1 / (-_TextureIFit * 7 + 1));
                }
                
                f4 = _TextureII.SampleBias(sampler_TextureII, (fakeuv * _TextureII_ST.xy) + _TextureII_ST.zw + _TextureIIFlow.xy * _Time, 0);
                float3 texII = f4.xyz * ((_EnableTextureIIAlpha == 1) ? f4.w : 1);
                if (_TextureIIFit > 0)
                {
                    texII = pow(texII, _TextureIIFit * 7 + 1);
                }
                else
                {
                    texII = pow(texII, 1 / (-_TextureIIFit * 7 + 1));
                }
                
                f4 = _TextureIII.SampleBias(sampler_TextureIII, (i.uv * _TextureIII_ST.xy) + _TextureIII_ST.zw, 0);
                float3 texIII = f4.xyz * ((_EnableTextureIIIAlpha == 1) ? f4.w : 1);

                float3 tex = texI.xyz;

                // 叠加贴图I和贴图II
                switch (_BlendI_II)
                {
                    case 0:
                        tex *= texII.xyz;
                        break;
                    case 1:
                        tex += texII.xyz;
                        break;
                    case 2:
                        tex = max(texI.xyz, texII.xyz);
                        break;
                    case 3:
                        tex = min(texI.xyz, texII.xyz);
                        break;
                    default:
                        break;
                }

                // 叠加贴图III
                tex *= texIII.xyz;

                #ifdef _DISSOLVE_ON
                switch (_DissolveType)
                {
                    case 0:
                        tex = tex + float3(1, 1, 1) - 2 * _DissolveState * float3(1, 1, 1);
                        break;
                    case 1:
                        tex = saturate(tex);
                        tex.x = tex.x >= _DissolveState ? 1 : 0;
                        tex.y = tex.y >= _DissolveState ? 1 : 0;
                        tex.z = tex.z >= _DissolveState ? 1 : 0;
                        break;
                    case 2:
                        tex -= _DissolveState;
                        tex = saturate(tex) * (1 - _DissolveState);
                        break;
                    case 3:

                        break;
                    default:
                        break;
                }
                
                #endif

                float4 mixedColor = float4(1, 1, 1, 1);
                if (_MixedColorAsAlpha == 1)
                {
                    // 颜色作为Alpha输出
                    mixedColor = saturate(float4(1, 1, 1, (tex.r + tex.g + tex.b) / 3));
                }

                float4 result = mixedColor * baseColor;
                
                return result;
            }
            ENDHLSL
        }
    }

    CustomEditor "VFXShaderUnity"
}
