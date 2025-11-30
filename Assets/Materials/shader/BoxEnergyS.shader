Shader "Custom/BoxEnergyS"
{
    Properties
    {
        _Color      ("Energy Color", Color) = (0.2, 0.8, 1, 1)
        _MainTex    ("Albedo (RGB)", 2D)    = "white" {}

        _GlowColor  ("Edge Glow Color", Color) = (0.5, 1, 1, 1)
        _GlowIntensity ("Glow Intensity", Range(0,5)) = 2.0
        _GlowPower  ("Glow Sharpness", Range(1,8)) = 3.0

        _Glossiness ("Smoothness", Range(0,1)) = 0.8
        _Metallic   ("Metallic", Range(0,1))   = 0.0

        _NoiseTex   ("Edge Noise", 2D)         = "white" {}
        _NoiseTiling("Noise Tiling", Vector)   = (4, 4, 0, 0)
        _NoiseAmount("Noise Amount", Range(0,1)) = 0.3
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        CGPROGRAM
        #pragma surface surf Standard
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _NoiseTex;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed4 _GlowColor;
        half _GlowIntensity;
        half _GlowPower;
        float4 _NoiseTiling;
        half _NoiseAmount;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        // Simple hash-based pseudo-random
        float hash21(float2 p)
        {
            p = frac(p * float2(123.34, 456.21));
            p += dot(p, p + 45.32);
            return frac(p.x * p.y);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Base albedo from texture tinted by energy color
            fixed4 baseTex = tex2D(_MainTex, IN.uv_MainTex);
            fixed3 baseCol = baseTex.rgb * _Color.rgb;

            // Common values
            float t = _Time.y;

            // UV-based border mask (controls width)
            float2 uv = IN.uv_MainTex;
            float edgeDist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
            float edgeScale = 10.0;               // larger = thinner border
            float edgeBase = pow(saturate(1.0 - edgeDist * edgeScale), _GlowPower);

            // Base scrolling UV for noise texture with tiling
            float2 noiseUV = IN.uv_MainTex * _NoiseTiling.xy + t;

            // Small pseudo-random UV offset (~1.5% of texture space)
            float2 offsetSeed = IN.worldPos.xz * 3.0 + t * 0.5;
            float2 offsetNoise = float2(hash21(offsetSeed), hash21(offsetSeed + 17.13));
            float2 uvOffset = (offsetNoise * 2.0 - 1.0) * 0.015;

            noiseUV += uvOffset;

            // Texture-driven jitter
            float noiseTex = tex2D(_NoiseTex, noiseUV).r;   // 0..1
            float jitterTex = (noiseTex * 2.0 - 1.0);       // -1..1
            float shimmerAmountTex = 1.5;
            float edgeTex = edgeBase * saturate(1.0 + jitterTex * shimmerAmountTex);

            // Hash-based fuzz (coarser random variation)
            float noiseHash = hash21(IN.worldPos.xz * 5.0 + t * 0.8);  // 0..1
            float jitterHash = (noiseHash * 2.0 - 1.0);
            float shimmerAmountHash = 1.7;
            float edgeHash = edgeBase * saturate(1.0 + jitterHash * shimmerAmountHash);

            // Blend them
            float edge = lerp(edgeTex, edgeHash, 0.7);

            // Optional extra sharpening so center stays dark
            edge = pow(edge, 1.2);

            // Final glow
            fixed3 glow = _GlowColor.rgb * edge * _GlowIntensity;

            o.Albedo = baseCol;
            o.Emission = glow;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}