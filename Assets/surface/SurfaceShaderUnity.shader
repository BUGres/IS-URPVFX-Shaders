Shader "Surface/SurfaceShaderUnity"
{
    Properties
    {
        [MainTexture][NoScaleOffset] _MainTex ("主贴图(固有色)", 2D) = "white" {}
        [MainColor] _MainCol("主颜色", Color) = (1,1,1,1)
        
        [Toggle] _PBR("PBR(def _PBR_ON)", Int) = 0
        _F0("F0", Range(0, 2)) = 0.97
        _F82("F82", Range(0, 2)) = 0.97
        _FakeIBL("IBL照度", Range(0, 5)) = 1
        [NoScaleOffset] _HDRTex("HDRTex", 2D) = "white" {}
        [NoScaleOffset] _RMOTex("RMOTex", 2D) = "white" {}
        [Toggle] _RMO("使用下面的RMO替代RMO贴图", Int) = 1
        _Roughness("Roughness", Range(0, 1)) = 0.5
        _Metallic("Metallic", Range(0, 1)) = 0.5
        _AO("AO", Range(0, 1)) = 0
        [NoScaleOffset] _NormalTex("NormalTex", 2D) = "white" {}
        [Toggle] _UseNormalTex("启用法线贴图", Float) = 0
        _RealShadow("主光源阴影Shadow", Range(0, 1)) = 1
        [Toggle] _PBR_AL("多光源PBR(def _PBR_AL_ON)", Int) = 0
        _PBR_AL_Diffuse("多光源PBR的漫反射部分", Range(0, 1)) = 0.1
        _PBR_AL_Specular("多光源PBR的高光部分", Range(0, 1)) = 0.2
        
        
        [Toggle] _NPR("NPR(def _NPR_ON)", Int) = 1
        
        [Header(KajiyaKay)][Toggle] _KK("Kajiya Kay(def _KK_ON)", Int) = 0
        [HDR] _KKCol("Kajiya Kay颜色", Color) = (1,1,1,1)
        _KKMul("Kajiya Kay强度", Range(0, 1)) = 0
        _KKPow("Kajiya Kay 指数(影响形状)", Range(0, 10)) = 0
        
        [Header(FresnelEffect)][Toggle] _FE("FresnelEffect(def _FE_ON)", Int) = 0
        [HDR] _FECol("FresnelEffect颜色", Color) = (1,1,1,1)
        _FEMul("FresnelEffect强度", Range(0, 1)) = 0
        _FEPow("FresnelEffect指数(影响形状)", Range(0, 10)) = 0
        
        
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
        Name "ForwardCostume"
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "LightMode" = "UniversalForward"
        }

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
            #pragma multi_compile __ _PBR_ON
            #pragma multi_compile __ _NPR_ON
            #pragma multi_compile __ _PBR_AL_ON
            #pragma multi_compile __ _KK_ON
            #pragma multi_compile __ _FE_ON

            #pragma multi_compile _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _SHADOWS_SOFT

            #pragma multi_compile _FORWARD_PLUS // 多光源必备宏
            // #pragma multi_compile _ADDITIONAL_LIGHTS
            // #pragma shader_feature _ADD_LIGHT_ON
            // #define USE_FORWARD_PLUS

            // pixelLightLoop
            #define M_LIGHT_LOOP_BEGIN(lightCount) { \
                uint lightIndex; \
                ClusterIterator _urp_internal_clusterIterator = ClusterInit(normalizedScreenSpaceUV, positionWS, 0); \
                [loop] while (ClusterNext(_urp_internal_clusterIterator, lightIndex)) { \
                    lightIndex += URP_FP_DIRECTIONAL_LIGHTS_COUNT; \
                    FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK
            #define M_LIGHT_LOOP_END } }
            
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "PBR.hlsl"

            CBUFFER_START(UnityPerMaterial)
            
            sampler2D _MainTex;
            float4 _MainCol;

            #ifdef _NPR_ON
            // 非真实渲染
            #endif
            
            #ifdef _PBR_ON
            // PBR
            float _F0;
            float _F82;
            float _FakeIBL;
            sampler2D _HDRTex;
            sampler2D _RMOTex;
            int _RMO;
            float _Roughness;
            float _Metallic;
            float _AO;
            sampler2D _NormalTex;
            float _UseNormalTex;
            float _RealShadow;
            #ifdef _PBR_AL_ON
            float _PBR_AL_Diffuse;
            float _PBR_AL_Specular;
            #endif
            #endif

            #ifdef _KK_ON
            // kajiya kay
            float4 _KKCol;
            float _KKMul;
            float _KKPow;
            #endif

            #ifdef _FE_ON
            // fresnel effect
            float4 _FECol;
            float _FEMul;
            float _FEPow;
            #endif

            CBUFFER_END

            struct appdata
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangent      : TANGENT;
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
                float3 tangentWS    : TEXCOORD3;
                float3 bitangentWS  : TEXCOORD4;
            };

            struct g2f
            {
                float4 positionHCS  : SV_POSITION;
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
                float3 tangentWS    : TEXCOORD3;
                float3 bitangentWS  : TEXCOORD4;
            };

            v2g vert(appdata v)
            {
                v2g o;
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.color = v.color;
                o.uv = v.uv;
                o.tangentWS = TransformObjectToWorldNormal(v.tangent.xyz);
                o.bitangentWS = cross(o.normalWS, o.tangentWS);
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
                    g.tangentWS = vertex.tangentWS;
                    g.bitangentWS = vertex.bitangentWS;
                    triStream.Append(g);
                }
            }

            float4 frag(g2f i) : SV_Target
            {
                // 获取阴影
                float4 SHADOW_COORDS = TransformWorldToShadowCoord(i.positionWS);
                Light lightData = GetMainLight(SHADOW_COORDS);
                float shadow = lightData.shadowAttenuation;
                
                float3 normalWS = normalize(i.normalWS);
                float3 tangentWS = normalize(i.tangentWS.xyz);
                float3 bitangentWS = normalize(i.bitangentWS.xyz);
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float3 lightDirWS = lightData.direction; // viewDirWS;
                float3 halfDirWS = normalize(lightDirWS + viewDirWS);
                float3 positionWS = i.positionWS;
                float4 posVS = TransformWorldToHClip(i.positionWS);
                float2 posSS = (float2(1, -1) * posVS.xy / posVS.w + float2(1, 1)) / 2;
                float2 normalizedScreenSpaceUV = posSS; // 以左上角为(0, 0)
                // return float4(posSS, 0, 1);

                float4 baseColor = tex2D(_MainTex, i.uv) * _MainCol; // _MainTex _MainCol
                
                #ifdef _NPR_ON
                
                #endif
                
                
                #ifdef _PBR_ON
                float3x3 TBN_WS = float3x3(tangentWS, bitangentWS, normalWS);
                float3 sampledNormal = tex2Dlod(_NormalTex, float4(i.uv, 0, 0)).xyz;
                sampledNormal = linearToGamma(sampledNormal, 2.2);
                sampledNormal = sampledNormal * 2 - float3(1, 1, 1);
                float3 sampledNormalWS = normalize(mul(normalize(sampledNormal), TBN_WS));
                normalWS = normalize(_UseNormalTex * sampledNormalWS + (1 - _UseNormalTex) * normalWS);
                
                float alpha = baseColor.w;
                float roughness;
                float metallic;
                float ao;
                if (_RMO == 0)
                {
                    float4 RMO = tex2D(_RMOTex, i.uv);
                    metallic = RMO.y;
                    roughness = RMO.x;
                    ao = RMO.z;
                }
                else
                {
                    metallic = _Metallic;
                    roughness = _Roughness;
                    ao = _AO;
                }

                // 从粗糙度和折射角度获取IBL，再转一次颜色空间
                float3 hdrReflectDiffuseAlbedo = tex2DHDR(_HDRTex, reflect(-viewDirWS, normalWS), 0, roughness);
                hdrReflectDiffuseAlbedo = gammaToLinear(hdrReflectDiffuseAlbedo, 2.2);

                // 此处计算的是lightDir的BRDF，如果要转为球面积分，可以在这里分多个光路叠加
                float cook = CookTorranceBRDF(normalWS, halfDirWS, viewDirWS, lightDirWS,
                    roughness,
                    _F0, 
                    _F82);

                float ks = fresnel_ortho(max(0.0, dot(viewDirWS, halfDirWS)), float3(_F0, _F0, _F0));
                // kd似乎不使用更好
                float kd = (1 - ks) * (1 - metallic);

                // 真实RealTime阴影
                float3 diffuseShading = baseColor * lerp(1, shadow, _RealShadow);

                // specular是高光，但是还要加上金属效果（就是下面的specularShading）
                float3 specular = float3(1, 1, 1) * ks * cook * max(0.0, dot(viewDirWS, halfDirWS));
                float3 specularShading = specular * (1 + metallic) * baseColor + 
                        hdrReflectDiffuseAlbedo * (1 + metallic) * baseColor * _FakeIBL * pow(max(0.75, dot(normalWS, viewDirWS)), 2);

                specularShading *= lerp(1, shadow, _RealShadow);

                #ifdef _PBR_AL_ON
                // 兰伯特多光源
                float3 additionLight_diffuceShading = float3(0, 0, 0);
                float3 additionLight_specularShading = float3(0, 0, 0);
                // uint additionLightCount = _AdditionalLightsCount.x; // GetAdditionalLightsCount();
                
                [loop] for (uint lightIndex = 0;
                    lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS);
                    lightIndex++)
                {
                    Light additionLightData = GetAdditionalLight(lightIndex, positionWS);
                    float3 tmp_lightDirWS = additionLightData.direction;
                    float tmp_shadow = additionLightData.shadowAttenuation;
                    float tmp_distanceAttenuation = additionLightData.distanceAttenuation;
                    additionLight_diffuceShading +=
                        tmp_shadow *
                        tmp_distanceAttenuation * 
                        saturate(dot(tmp_lightDirWS, normalWS)) *
                        additionLightData.color.xyz;

                    float cook = CookTorranceBRDF(normalWS, normalize(viewDirWS + tmp_lightDirWS),
                        viewDirWS, tmp_lightDirWS,
                        roughness,
                        _F0, 
                        _F82);

                    additionLight_specularShading += tmp_shadow *
                        tmp_distanceAttenuation * cook * additionLightData.color;
                }
                
                M_LIGHT_LOOP_BEGIN(UnUsedIndex) // 这里不要括号也行，只是为了方便对照源码
                    Light additionLightData = GetAdditionalLight(lightIndex, positionWS);
                    float3 tmp_lightDirWS = additionLightData.direction;
                    float tmp_shadow = additionLightData.shadowAttenuation;
                    float tmp_distanceAttenuation = additionLightData.distanceAttenuation;
                    additionLight_diffuceShading +=
                        tmp_shadow *
                        tmp_distanceAttenuation * 
                        saturate(dot(tmp_lightDirWS, normalWS)) *
                        additionLightData.color.xyz;

                    float cook = CookTorranceBRDF(normalWS, normalize(viewDirWS + tmp_lightDirWS),
                        viewDirWS, tmp_lightDirWS,
                        roughness,
                        _F0, 
                        _F82);

                    additionLight_specularShading += tmp_shadow *
                        tmp_distanceAttenuation * cook * additionLightData.color;
                M_LIGHT_LOOP_END
                
                diffuseShading += _PBR_AL_Diffuse * additionLight_diffuceShading;
                specularShading += _PBR_AL_Specular * additionLight_specularShading;
                #endif
                
                
                // pbr混合
                float4 pbrMixedColor = float4(((1 - metallic) * diffuseShading + specularShading).rgb, alpha);
                baseColor = pbrMixedColor;
                #endif

                #ifdef _KK_ON
                float3 H = normalize(lightDirWS + viewDirWS);
                float dotTH = dot(normalize(i.bitangentWS), H); //  + float3(0, sin(150 * i.uv.x) * 0.1, 0)
                float sinTH = pow(sqrt(1 - dotTH * dotTH), pow(2, _KKPow));
                float4 kk = float4(sinTH, sinTH, sinTH, 0) * _KKCol;
                baseColor += kk * _KKMul;
                #endif
                
                #ifdef _FE_ON
                float ndv = 1 - saturate(dot(normalWS, viewDirWS));
                baseColor += _FECol * pow(ndv, _FEPow) * _FEMul;
                #endif

                return baseColor;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
            
            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma target 2.0
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            #pragma vertex DepthOnlyVertexS
            Varyings DepthOnlyVertexS(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                return output;
            }
            #pragma fragment DepthOnlyFragmentS
            half DepthOnlyFragmentS(Varyings input) : SV_TARGET
            {
                return input.positionCS.z;
            }
            ENDHLSL
        }
    }

    CustomEditor "SurfaceShaderUnity"
}
