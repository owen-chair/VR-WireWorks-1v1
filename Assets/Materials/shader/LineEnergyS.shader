Shader "Custom/LineEnergyS"
{
    Properties
    {
        _Color         ("Energy Color", Color) = (0.2, 0.8, 1, 1)
        _GlowColor     ("Glow Color", Color)   = (0.5, 1, 1, 1)
        _GlowIntensity ("Glow Intensity", Range(0,5)) = 2.0

        _NoiseTex      ("Noise", 2D)           = "white" {}
        _NoiseTiling   ("Noise Tiling", Vector)= (4, 4, 0, 0)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100
        Cull Back
        ZWrite On
        ZTest LEqual
        Blend Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            fixed4 _GlowColor;
            half   _GlowIntensity;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos      : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            // Simple hash-based pseudo-random
            float hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv  = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float t = _Time.y;

                // Base random
                float2 seed = i.worldPos.xz * 3.0 + t * 0.5;
                float rnd = hash21(seed);   // 0..1

                // Horizontal-only falloff (U axis)
                float u = i.uv.x;

                // Distance from horizontal center: 0 at center, 0.5 at left/right edges
                float centerDist = abs(u - 0.5);

                // Normalize: 1 at center, 0 at edges
                float centerMask = 0.95 - saturate(centerDist * 2.5); // 0..1
                centerMask = centerMask * centerMask;                // smoother peak

                // Keep probability: 25% at center, 0% at left/right edges
                float keepProb = 0.59 * centerMask;

                if (rnd > keepProb)
                    discard;

                fixed3 glow = _GlowColor.rgb * _GlowIntensity;
                return fixed4(glow, 1.0);
            }
            ENDCG
        }
    }
}