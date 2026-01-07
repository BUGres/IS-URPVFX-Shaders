float2 hash22(float2 p)
{
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
}

float Perlin(float2 p)
{
    float2 pi = floor(p);//返回小于等于x的最大整数。
    float2 pf = frac(p);//返回输入值的小数部分。
    
    //float2 w = pf * pf * (3.0 - 2.0 * pf);
    float2 w = pf * pf * pf * (6 * pf * pf - 15 * pf + 10);
     
    return lerp(lerp(dot(hash22(pi + float2(0.0, 0.0)), pf - float2(0.0, 0.0)),
                    dot(hash22(pi + float2(1.0, 0.0)), pf - float2(1, 0.0)), w.x),
                lerp(dot(hash22(pi + float2(0.0, 1.0)), pf - float2(0.0, 1.0)),
                    dot(hash22(pi + float2(1.0, 1.0)), pf - float2(1.0, 1.0)), w.x), w.y);
}

// 实际上是一个叠加的柏林噪声，只保证归一化的输出
float PerlinNoise(float2 uv)
{
    // 实际上是一个叠加的柏林噪声
    float value = (Perlin(uv) + Perlin(2 * uv) / 2 + Perlin(4 * uv) / 4 + Perlin(8 * uv) / 8);
    return saturate(pow(lerp(0.35, 1, value), 2));
}

float2 hash21(float2 p)
{
    float h = dot(p, float2(127.1, 311.7));
    return -1.0 + 2.0 * frac(sin(h) * 43758.5453123);
}

float ValueNoise(float2 p)
{
    float2 pi = floor(p);
    float2 pf = frac(p);
    
    //float2 w = pf * pf * (3.0 - 2.0 * pf);
    float2 w = pf * pf * pf * (6 * pf * pf - 15 * pf + 10);
     
    return lerp(lerp(hash21(pi + float2(0.0, 0.0)),hash21(pi + float2(1.0, 0.0)), w.x),
                lerp(hash21(pi + float2(0.0, 1.0)), hash21(pi + float2(1.0, 1.0)), w.x),w.y);
}
