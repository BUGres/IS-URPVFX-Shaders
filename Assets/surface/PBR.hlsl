#ifndef PI
#define PI 3.1415926
#endif

// 根据粗糙度采样IBL
float3 tex2DHDR(sampler2D hdr, float3 normalWS, float angle, float baseRoughness)
{
    float u = atan(normalWS.z / normalWS.x);
    u += normalWS.x < 0 ? PI : 0;
    u += (normalWS.z < 0 && normalWS.x > 0) ? 2 * PI : 0;
    u /= 2 * PI;
    
    float v = (asin(normalWS.y) * 2 / PI + 1) / 2;
    // return tex2D(hdr, float2(u + angle, v)).rgb;

    if(baseRoughness > 0.666666)
    {
        return lerp(tex2D(hdr, float2(u + angle, v / 4 + 0.75)).rgb, 
                    tex2D(hdr, float2(u + angle, v / 4 + 0.5)).rgb, 
                    1 - 3 * (baseRoughness - 0.666666));
    }
    else if (baseRoughness > 0.333333)
    {
        return lerp(tex2D(hdr, float2(u + angle, v / 4 + 0.5)).rgb, 
                    tex2D(hdr, float2(u + angle, v / 4 + 0.25)).rgb, 
                    1 - 3 * (baseRoughness - 0.333333));
    }
    else
    {
        return lerp(tex2D(hdr, float2(u + angle, v / 4 + 0.25)).rgb, 
                    tex2D(hdr, float2(u + angle, v / 4 + 0.00)).rgb, 
                    1 - 3 * (baseRoughness - 0.000000));
    }
}

// 带F82的菲涅尔
float3 gfresnel(
  float vdh,
  float3 F0,
  float3 F82)
{
    float3 b = (1.0 - F82) * (F0 * 9.48471792 + 8.16666665);
    float e = 1.0 - vdh;
    float e5 = e * e; e5 *= e5 * e;
    float3 offset = (1.0 - F0 - b * (vdh * e)) * e5;
    return clamp(F0 + offset, 0.0, 1.0);
}

// GGX 法线分布（DFG计算中）
float DistributionGGX(float3 n, float3 h, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float ndh = max(0, dot(n, h));
    float ndh2 = ndh * ndh;
    float num = a2;
    float denom = (ndh2 * (a2 - 1) + 1);
    denom = max(PI * denom * denom, 0.0000001); // 修正为0的情况，PBR中有很多类似的修正
    return num / denom;
}

// 色彩空间转换
float3 linearToGamma(float3 linearColor, float gamma)
{
    return pow(linearColor, 1.0 / gamma);
}

// 色彩空间转换
float3 gammaToLinear(float3 gammaColor, float gamma)
{
    return pow(gammaColor, gamma);
}

// ggx中使用
float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;
    k *= 2;
    
    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return num / denom;
}

// 几何分布Smith方法
float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

float fresnel_ortho(float vdh, float3 F0)
{
    return F0.r + (1.0 - F0.r) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0);
}

// 在某个光路（方向角/入射向量）上计算辐射率，Cook-Torrance公式
float CookTorranceBRDF(float3 n, float3 h, float3 v, float3 l, float roughness, float F0, float F82)
{
    float3 F03 = float3(F0, F0, F0);
    float3 F823 = float3(F82, F82, F82);
    
    float NDF = DistributionGGX(n, h, roughness);
    float G = GeometrySmith(n, v, l, roughness);
    // float F = fresnel_ortho(max(0, dot(v, h)), F03);
    float F = gfresnel(max(0, dot(v, l)), F03, F823).r;
    // G = max(0.2, G);
    // return F0;
    return NDF * G * F /
        (4 * max(0, dot(n, v)) * max(0, dot(n, l)) + 0.001);
}