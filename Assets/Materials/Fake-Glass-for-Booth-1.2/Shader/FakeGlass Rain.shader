// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Silent/FakeGlass Rain"
{
	Properties
	{
		[Header(Glass Colour)]_Color("Diffuse Color", Color) = (1,1,1,0)
		_MainTex("Tint Texture", 2D) = "white" {}
		[HDR]_Glow("Glow Strength", Color) = (0,0,0,0)
		[Normal][Header(Material Properties)]_BumpMap("Normal Map", 2D) = "bump" {}
		_NormalScale("Normal Scale", Float) = 1
		_Smoothness("Smoothness", Range( 0 , 1)) = 1
		_Metallic("Metallic", Range( 0 , 1)) = 0
		[Toggle(BLOOM)] _UseColourShift("Use Colour Shift", Float) = 0
		_IOR("IOR", Range( 0 , 2)) = 1
		[Gamma]_Refraction("Refraction Power", Range( 0 , 1)) = 0.1
		_InteriorDiffuseStrength("Interior Diffuse Strength", Range( 0 , 1)) = 0.1
		[Header(Additional Properties)]_SurfaceMask("Surface Mask", 2D) = "black" {}
		_SurfaceSmoothness("Surface Smoothness ", Range( 0 , 1)) = 0
		_SurfaceLevelTweak("Surface Level Tweak", Range( -1 , 1)) = 0
		_SurfaceSmoothnessTweak("Surface Smoothness Tweak", Range( -1 , 1)) = 0
		_OcclusionMap("Occlusion Map", 2D) = "white" {}
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Int) = 0
		_ShadowTransparency("Shadow Transparency", Range( 0 , 1)) = 1
		[ToggleUI]_ZWrite("Z Write (for solid glass)", Float) = 0
		[Header(Rain Properties)]_RainPattern("Rain Pattern", 2D) = "gray" {}
		[NoScaleOffset][Normal]_RippleNormals("Ripple Normals", 2D) = "bump" {}
		[NoScaleOffset][Normal]_DropletNormals("Droplet Normals", 2D) = "bump" {}
		_RainSpeed("Rain Speed", Float) = 1
		_StreakTiling("Streak Tiling", Float) = 1
		_StreakLength("Streak Length", Float) = 1
		_RainFade("Rain Fade", Range( 0 , 1)) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent-6" "IsEmissive" = "true"  }
		Cull [_CullMode]
		ZWrite [_ZWrite]
		Blend One OneMinusSrcAlpha
		
		ColorMask RGB
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityStandardUtils.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma shader_feature BLOOM
		#if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
		#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex.Sample(samplerTex,coord)
		#define SAMPLE_TEXTURE2D_LOD(tex,samplerTex,coord,lod) tex.SampleLevel(samplerTex,coord, lod)
		#define SAMPLE_TEXTURE2D_BIAS(tex,samplerTex,coord,bias) tex.SampleBias(samplerTex,coord,bias)
		#define SAMPLE_TEXTURE2D_GRAD(tex,samplerTex,coord,ddx,ddy) tex.SampleGrad(samplerTex,coord,ddx,ddy)
		#else//ASE Sampling Macros
		#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex2D(tex,coord)
		#define SAMPLE_TEXTURE2D_LOD(tex,samplerTex,coord,lod) tex2Dlod(tex,float4(coord,0,lod))
		#define SAMPLE_TEXTURE2D_BIAS(tex,samplerTex,coord,bias) tex2Dbias(tex,float4(coord,0,bias))
		#define SAMPLE_TEXTURE2D_GRAD(tex,samplerTex,coord,ddx,ddy) tex2Dgrad(tex,coord,ddx,ddy)
		#endif//ASE Sampling Macros

		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 worldNormal;
			INTERNAL_DATA
			half ASEVFace : VFACE;
			float3 worldPos;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform int _CullMode;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_MainTex);
		uniform float4 _MainTex_ST;
		SamplerState sampler_MainTex;
		uniform float4 _Color;
		uniform float _Metallic;
		uniform float4 _Glow;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
		uniform float4 _BumpMap_ST;
		SamplerState sampler_BumpMap;
		uniform float _NormalScale;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_DropletNormals);
		uniform float _RainSpeed;
		uniform float _StreakTiling;
		uniform float _StreakLength;
		SamplerState sampler_DropletNormals;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_RainPattern);
		SamplerState sampler_RainPattern;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_RippleNormals);
		uniform float4 _RainPattern_ST;
		SamplerState sampler_RippleNormals;
		uniform float _RainFade;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_SurfaceMask);
		uniform float4 _SurfaceMask_ST;
		SamplerState sampler_SurfaceMask;
		uniform float _SurfaceLevelTweak;
		uniform float _Smoothness;
		uniform float _ShadowTransparency;
		uniform float _SurfaceSmoothnessTweak;
		uniform float _SurfaceSmoothness;
		uniform float _IOR;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
		uniform float4 _OcclusionMap_ST;
		SamplerState sampler_OcclusionMap;
		uniform float _Refraction;
		uniform float _InteriorDiffuseStrength;


		float3 FresnelLerp47( float3 specColor, float grazingTerm, float nv )
		{
			 return FresnelLerp (specColor, grazingTerm, nv);
		}


		float SmoothnesstoRoughness56( float smoothness )
		{
			return SmoothnessToRoughness(smoothness);
		}


		float surfaceReduction55( float roughness )
		{
			    half surfaceReduction;
			#   ifdef UNITY_COLORSPACE_GAMMA
			        surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
			#   else
			        surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
			#   endif
			    return surfaceReduction;
		}


		float InvFresnelPow5200( float x )
		{
			return 1-Pow5(1-x);
		}


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			float4 mainTex121 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, uv_MainTex );
			float4 temp_output_123_0 = ( mainTex121 * _Color );
			float4 mainTint174 = temp_output_123_0;
			float metallic177 = _Metallic;
			half3 specColor42 = (0).xxx;
			half oneMinusReflectivity42 = 0;
			half3 diffuseAndSpecularFromMetallic42 = DiffuseAndSpecularFromMetallic(mainTint174.rgb,metallic177,specColor42,oneMinusReflectivity42);
			float oneMinusReflectivity44 = oneMinusReflectivity42;
			float alpha37 = (temp_output_123_0).a;
			float temp_output_41_0 = ( ( 1.0 - oneMinusReflectivity44 ) + ( alpha37 * oneMinusReflectivity44 ) );
			float2 uv_SurfaceMask = i.uv_texcoord * _SurfaceMask_ST.xy + _SurfaceMask_ST.zw;
			float4 tex2DNode96 = SAMPLE_TEXTURE2D( _SurfaceMask, sampler_SurfaceMask, uv_SurfaceMask );
			float3 newWorldNormal2_g54 = (WorldNormalVector( i , float3(0,0,1) ));
			float noRainArea17_g54 = ( 1.0 - saturate( -newWorldNormal2_g54.y ) );
			float3 ase_worldPos = i.worldPos;
			float rainSpeed10_g54 = _RainSpeed;
			float rainSpeed45_g55 = rainSpeed10_g54;
			float streakTiling7_g54 = _StreakTiling;
			float streakTiling50_g55 = streakTiling7_g54;
			float3 break59_g55 = ( ( ase_worldPos + ( _Time.y * float3(0,0,0) * rainSpeed45_g55 ) ) / streakTiling50_g55 );
			float streakLength8_g54 = _StreakLength;
			float streakLength52_g55 = streakLength8_g54;
			float3 appendResult13_g55 = (float3(break59_g55.x , ( break59_g55.y / streakLength52_g55 ) , break59_g55.z));
			float2 temp_output_29_0_g55 = (appendResult13_g55).xy;
			float3 break24_g55 = appendResult13_g55;
			float2 appendResult28_g55 = (float2(break24_g55.z , break24_g55.y));
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float temp_output_30_0_g55 = saturate( abs( ase_worldNormal.x ) );
			float lerpResult36_g55 = lerp( SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, temp_output_29_0_g55 ).g , SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, appendResult28_g55 ).g , temp_output_30_0_g55);
			float3 temp_output_19_0_g55 = ( ( appendResult13_g55 * float3( 1,0.5,1 ) ) + ( _Time.y * float3(0,1,0) * rainSpeed45_g55 ) );
			float3 break20_g55 = temp_output_19_0_g55;
			float2 appendResult22_g55 = (float2(break20_g55.z , break20_g55.y));
			float lerpResult34_g55 = lerp( SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, (temp_output_19_0_g55).xy ).b , SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, appendResult22_g55 ).b , temp_output_30_0_g55);
			float temp_output_40_0_g55 = saturate( ( ( lerpResult36_g55 - pow( lerpResult34_g55 , 4.0 ) ) * 5.0 ) );
			float2 worldUVs114_g56 = (ase_worldPos).xz;
			float2 temp_output_20_0_g56 = (worldUVs114_g56*_RainPattern_ST.xy + ( _RainPattern_ST.zw + float2( 0,0 ) ));
			float rainSpeed60_g56 = rainSpeed10_g54;
			float temp_output_19_0_g56 = ( ( _Time.y + 0.0 ) * rainSpeed60_g56 );
			float temp_output_25_0_g56 = ( (SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, temp_output_20_0_g56 )).r - ( 1.0 - frac( temp_output_19_0_g56 ) ) );
			float smoothstepResult11_g56 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_25_0_g56 , 0.05 ) / max( 0.05 , saturate( fwidth( temp_output_25_0_g56 ) ) ) ));
			float rainTime29_g56 = temp_output_19_0_g56;
			float temp_output_12_0_g56 = abs( sin( ( rainTime29_g56 * UNITY_PI ) ) );
			float2 temp_output_41_0_g56 = (worldUVs114_g56*_RainPattern_ST.xy + ( _RainPattern_ST.zw + 0.1 ));
			float temp_output_40_0_g56 = ( ( _Time.y + 0.5 ) * rainSpeed60_g56 );
			float temp_output_45_0_g56 = ( (SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, temp_output_41_0_g56 )).r - ( 1.0 - frac( temp_output_40_0_g56 ) ) );
			float smoothstepResult65_g56 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_45_0_g56 , 0.05 ) / max( 0.05 , saturate( fwidth( temp_output_45_0_g56 ) ) ) ));
			float rainTime246_g56 = temp_output_40_0_g56;
			float rainAxis12_g54 = saturate( newWorldNormal2_g54.y );
			float lerpResult23_g54 = lerp( temp_output_40_0_g55 , ( ( ( 1.0 - smoothstepResult11_g56 ) * temp_output_12_0_g56 ) + ( ( 1.0 - smoothstepResult65_g56 ) * abs( sin( ( rainTime246_g56 * UNITY_PI ) ) ) ) ) , rainAxis12_g54);
			float rainMask26_g54 = ( noRainArea17_g54 * lerpResult23_g54 * _RainFade );
			float rainMask296 = rainMask26_g54;
			float surfaceLevel165 = saturate( ( tex2DNode96.r + _SurfaceLevelTweak + rainMask296 ) );
			float3 specColor47 = specColor42;
			float smoothness60 = _Smoothness;
			float grazingTerm51 = saturate( ( smoothness60 + ( 1.0 - oneMinusReflectivity44 ) ) );
			float grazingTerm47 = grazingTerm51;
			float2 uv_TexCoord30 = i.uv_texcoord * _BumpMap_ST.xy + _BumpMap_ST.zw;
			float3 switchResult137 = (((i.ASEVFace>0)?(float3( 1,1,1 )):(float3(1,1,-1))));
			float3 normalMap87 = ( UnpackScaleNormal( SAMPLE_TEXTURE2D( _BumpMap, sampler_BumpMap, uv_TexCoord30 ), _NormalScale ) * switchResult137 );
			float3 lerpResult57_g55 = lerp( UnpackNormal( SAMPLE_TEXTURE2D( _DropletNormals, sampler_DropletNormals, temp_output_29_0_g55 ) ) , UnpackNormal( SAMPLE_TEXTURE2D( _DropletNormals, sampler_DropletNormals, appendResult28_g55 ) ) , temp_output_30_0_g55);
			float3 lerpResult58_g55 = lerp( float3( 0,0,1 ) , lerpResult57_g55 , temp_output_40_0_g55);
			float3 rippleNormalsSample1101_g56 = UnpackNormal( SAMPLE_TEXTURE2D( _RippleNormals, sampler_RippleNormals, temp_output_20_0_g56 ) );
			float3 rippleNormalsSample2104_g56 = UnpackNormal( SAMPLE_TEXTURE2D( _RippleNormals, sampler_RippleNormals, temp_output_41_0_g56 ) );
			float3 lerpResult111_g56 = lerp( rippleNormalsSample1101_g56 , rippleNormalsSample2104_g56 , temp_output_12_0_g56);
			float3 lerpResult21_g54 = lerp( lerpResult58_g55 , lerpResult111_g56 , rainAxis12_g54);
			float3 rainNormals24_g54 = lerpResult21_g54;
			float3 rainNormals295 = rainNormals24_g54;
			float3 lerpResult302 = lerp( normalMap87 , BlendNormals( normalMap87 , rainNormals295 ) , rainMask296);
			float3 finalNormalMap303 = lerpResult302;
			float3 newWorldNormal26 = (WorldNormalVector( i , finalNormalMap303 ));
			float3 worldNormal206 = newWorldNormal26;
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float dotResult54 = dot( worldNormal206 , ase_worldViewDir );
			float NdotV181 = abs( dotResult54 );
			float nv47 = NdotV181;
			float3 localFresnelLerp47 = FresnelLerp47( specColor47 , grazingTerm47 , nv47 );
			float3 temp_cast_3 = (0.3333333).xxx;
			float dotResult279 = dot( localFresnelLerp47 , temp_cast_3 );
			float3 temp_cast_4 = (saturate( ( temp_output_41_0 + surfaceLevel165 + dotResult279 ) )).xxx;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = Unity_SafeNormalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult203 = dot( ase_worldlightDir , worldNormal206 );
			float temp_output_225_0 = ( 1.0 - _ShadowTransparency );
			float premultipliedAlpha212 = temp_output_41_0;
			float surfaceSmoothness166 = saturate( ( ( saturate( ( _SurfaceSmoothnessTweak + tex2DNode96.r ) ) * _SurfaceSmoothness ) + rainMask296 ) );
			float lerpResult209 = lerp( premultipliedAlpha212 , ( 1.0 - surfaceSmoothness166 ) , surfaceLevel165);
			float3 temp_cast_5 = ((lerpResult209 + (dotResult203 - -1.0) * (1.0 - lerpResult209) / (temp_output_225_0 - -1.0))).xxx;
			float temp_output_2_0_g52 = _ShadowTransparency;
			float temp_output_3_0_g52 = ( 1.0 - temp_output_2_0_g52 );
			float3 appendResult7_g52 = (float3(temp_output_3_0_g52 , temp_output_3_0_g52 , temp_output_3_0_g52));
			#ifdef UNITY_PASS_SHADOWCASTER
				float3 staticSwitch201 = ( ( ( temp_cast_5 * temp_output_2_0_g52 ) + appendResult7_g52 ) * ( 1.0 - saturate( temp_output_225_0 ) ) );
			#else
				float3 staticSwitch201 = temp_cast_4;
			#endif
			float3 finalOpacity215 = staticSwitch201;
			float temp_output_191_0 = ( _IOR - 1.0 );
			float3 indirectNormal266 = refract( ase_worldViewDir , worldNormal206 , temp_output_191_0 );
			float2 uv_TexCoord118 = i.uv_texcoord * _OcclusionMap_ST.xy + _OcclusionMap_ST.zw;
			float occlusion116 = SAMPLE_TEXTURE2D( _OcclusionMap, sampler_OcclusionMap, uv_TexCoord118 ).g;
			Unity_GlossyEnvironmentData g266 = UnityGlossyEnvironmentSetup( smoothness60, data.worldViewDir, indirectNormal266, float3(0,0,0));
			float3 indirectSpecular266 = UnityGI_IndirectSpecular( data, occlusion116, indirectNormal266, g266 );
			float temp_output_241_0 = ( _Refraction + 0.0 );
			float3 _WavelengthRatios = float3(1,0.8,0.7);
			float3 indirectNormal1 = refract( ase_worldViewDir , newWorldNormal26 , ( temp_output_191_0 + ( temp_output_241_0 * _WavelengthRatios.x ) ) );
			Unity_GlossyEnvironmentData g1 = UnityGlossyEnvironmentSetup( smoothness60, data.worldViewDir, indirectNormal1, float3(0,0,0));
			float3 indirectSpecular1 = UnityGI_IndirectSpecular( data, occlusion116, indirectNormal1, g1 );
			float3 indirectNormal5 = refract( ase_worldViewDir , newWorldNormal26 , ( temp_output_191_0 + ( temp_output_241_0 * _WavelengthRatios.y ) ) );
			Unity_GlossyEnvironmentData g5 = UnityGlossyEnvironmentSetup( smoothness60, data.worldViewDir, indirectNormal5, float3(0,0,0));
			float3 indirectSpecular5 = UnityGI_IndirectSpecular( data, occlusion116, indirectNormal5, g5 );
			float3 indirectNormal7 = refract( ase_worldViewDir , newWorldNormal26 , ( temp_output_191_0 + ( temp_output_241_0 * _WavelengthRatios.z ) ) );
			Unity_GlossyEnvironmentData g7 = UnityGlossyEnvironmentSetup( smoothness60, data.worldViewDir, indirectNormal7, float3(0,0,0));
			float3 indirectSpecular7 = UnityGI_IndirectSpecular( data, occlusion116, indirectNormal7, g7 );
			float3 appendResult4 = (float3((indirectSpecular1).x , (indirectSpecular5).y , (indirectSpecular7).z));
			#ifdef BLOOM
				float3 staticSwitch292 = appendResult4;
			#else
				float3 staticSwitch292 = indirectSpecular266;
			#endif
			float3 finalRefraction261 = staticSwitch292;
			float smoothness56 = smoothness60;
			float localSmoothnesstoRoughness56 = SmoothnesstoRoughness56( smoothness56 );
			float roughness55 = localSmoothnesstoRoughness56;
			float localsurfaceReduction55 = surfaceReduction55( roughness55 );
			float3 indirectNormal66 = WorldNormalVector( i , (WorldNormalVector( i , float3( (finalNormalMap303).xy ,  0.0 ) )) );
			Unity_GlossyEnvironmentData g66 = UnityGlossyEnvironmentSetup( surfaceSmoothness166, data.worldViewDir, indirectNormal66, float3(0,0,0));
			float3 indirectSpecular66 = UnityGI_IndirectSpecular( data, occlusion116, indirectNormal66, g66 );
			float temp_output_2_0_g53 = metallic177;
			float temp_output_3_0_g53 = ( 1.0 - temp_output_2_0_g53 );
			float3 appendResult7_g53 = (float3(temp_output_3_0_g53 , temp_output_3_0_g53 , temp_output_3_0_g53));
			float x200 = NdotV181;
			float localInvFresnelPow5200 = InvFresnelPow5200( x200 );
			UnityGI gi272 = gi;
			float3 diffNorm272 = worldNormal206;
			gi272 = UnityGI_Base( data, 1, diffNorm272 );
			float3 indirectDiffuse272 = gi272.indirect.diffuse + diffNorm272 * 0.0001;
			c.rgb = max( ( ( finalRefraction261 * localFresnelLerp47 * localsurfaceReduction55 ) + ( surfaceSmoothness166 * indirectSpecular66 * ( ( mainTint174.rgb * temp_output_2_0_g53 ) + appendResult7_g53 ) * localInvFresnelPow5200 ) + ( ( _InteriorDiffuseStrength * indirectDiffuse272 ) * dotResult279 ) ) , float3( 0,0,0 ) );
			c.a = finalOpacity215.x;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			float4 mainTex121 = SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, uv_MainTex );
			float4 temp_output_123_0 = ( mainTex121 * _Color );
			float4 mainTint174 = temp_output_123_0;
			float metallic177 = _Metallic;
			half3 specColor42 = (0).xxx;
			half oneMinusReflectivity42 = 0;
			half3 diffuseAndSpecularFromMetallic42 = DiffuseAndSpecularFromMetallic(mainTint174.rgb,metallic177,specColor42,oneMinusReflectivity42);
			float alpha37 = (temp_output_123_0).a;
			o.Albedo = ( diffuseAndSpecularFromMetallic42 * alpha37 );
			float2 uv_TexCoord30 = i.uv_texcoord * _BumpMap_ST.xy + _BumpMap_ST.zw;
			float3 switchResult137 = (((i.ASEVFace>0)?(float3( 1,1,1 )):(float3(1,1,-1))));
			float3 normalMap87 = ( UnpackScaleNormal( SAMPLE_TEXTURE2D( _BumpMap, sampler_BumpMap, uv_TexCoord30 ), _NormalScale ) * switchResult137 );
			float3 ase_worldPos = i.worldPos;
			float rainSpeed10_g54 = _RainSpeed;
			float rainSpeed45_g55 = rainSpeed10_g54;
			float streakTiling7_g54 = _StreakTiling;
			float streakTiling50_g55 = streakTiling7_g54;
			float3 break59_g55 = ( ( ase_worldPos + ( _Time.y * float3(0,0,0) * rainSpeed45_g55 ) ) / streakTiling50_g55 );
			float streakLength8_g54 = _StreakLength;
			float streakLength52_g55 = streakLength8_g54;
			float3 appendResult13_g55 = (float3(break59_g55.x , ( break59_g55.y / streakLength52_g55 ) , break59_g55.z));
			float2 temp_output_29_0_g55 = (appendResult13_g55).xy;
			float3 break24_g55 = appendResult13_g55;
			float2 appendResult28_g55 = (float2(break24_g55.z , break24_g55.y));
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float temp_output_30_0_g55 = saturate( abs( ase_worldNormal.x ) );
			float3 lerpResult57_g55 = lerp( UnpackNormal( SAMPLE_TEXTURE2D( _DropletNormals, sampler_DropletNormals, temp_output_29_0_g55 ) ) , UnpackNormal( SAMPLE_TEXTURE2D( _DropletNormals, sampler_DropletNormals, appendResult28_g55 ) ) , temp_output_30_0_g55);
			float lerpResult36_g55 = lerp( SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, temp_output_29_0_g55 ).g , SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, appendResult28_g55 ).g , temp_output_30_0_g55);
			float3 temp_output_19_0_g55 = ( ( appendResult13_g55 * float3( 1,0.5,1 ) ) + ( _Time.y * float3(0,1,0) * rainSpeed45_g55 ) );
			float3 break20_g55 = temp_output_19_0_g55;
			float2 appendResult22_g55 = (float2(break20_g55.z , break20_g55.y));
			float lerpResult34_g55 = lerp( SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, (temp_output_19_0_g55).xy ).b , SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, appendResult22_g55 ).b , temp_output_30_0_g55);
			float temp_output_40_0_g55 = saturate( ( ( lerpResult36_g55 - pow( lerpResult34_g55 , 4.0 ) ) * 5.0 ) );
			float3 lerpResult58_g55 = lerp( float3( 0,0,1 ) , lerpResult57_g55 , temp_output_40_0_g55);
			float2 worldUVs114_g56 = (ase_worldPos).xz;
			float2 temp_output_20_0_g56 = (worldUVs114_g56*_RainPattern_ST.xy + ( _RainPattern_ST.zw + float2( 0,0 ) ));
			float3 rippleNormalsSample1101_g56 = UnpackNormal( SAMPLE_TEXTURE2D( _RippleNormals, sampler_RippleNormals, temp_output_20_0_g56 ) );
			float2 temp_output_41_0_g56 = (worldUVs114_g56*_RainPattern_ST.xy + ( _RainPattern_ST.zw + 0.1 ));
			float3 rippleNormalsSample2104_g56 = UnpackNormal( SAMPLE_TEXTURE2D( _RippleNormals, sampler_RippleNormals, temp_output_41_0_g56 ) );
			float rainSpeed60_g56 = rainSpeed10_g54;
			float temp_output_19_0_g56 = ( ( _Time.y + 0.0 ) * rainSpeed60_g56 );
			float rainTime29_g56 = temp_output_19_0_g56;
			float temp_output_12_0_g56 = abs( sin( ( rainTime29_g56 * UNITY_PI ) ) );
			float3 lerpResult111_g56 = lerp( rippleNormalsSample1101_g56 , rippleNormalsSample2104_g56 , temp_output_12_0_g56);
			float3 newWorldNormal2_g54 = (WorldNormalVector( i , float3(0,0,1) ));
			float rainAxis12_g54 = saturate( newWorldNormal2_g54.y );
			float3 lerpResult21_g54 = lerp( lerpResult58_g55 , lerpResult111_g56 , rainAxis12_g54);
			float3 rainNormals24_g54 = lerpResult21_g54;
			float3 rainNormals295 = rainNormals24_g54;
			float noRainArea17_g54 = ( 1.0 - saturate( -newWorldNormal2_g54.y ) );
			float temp_output_25_0_g56 = ( (SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, temp_output_20_0_g56 )).r - ( 1.0 - frac( temp_output_19_0_g56 ) ) );
			float smoothstepResult11_g56 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_25_0_g56 , 0.05 ) / max( 0.05 , saturate( fwidth( temp_output_25_0_g56 ) ) ) ));
			float temp_output_40_0_g56 = ( ( _Time.y + 0.5 ) * rainSpeed60_g56 );
			float temp_output_45_0_g56 = ( (SAMPLE_TEXTURE2D( _RainPattern, sampler_RainPattern, temp_output_41_0_g56 )).r - ( 1.0 - frac( temp_output_40_0_g56 ) ) );
			float smoothstepResult65_g56 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_45_0_g56 , 0.05 ) / max( 0.05 , saturate( fwidth( temp_output_45_0_g56 ) ) ) ));
			float rainTime246_g56 = temp_output_40_0_g56;
			float lerpResult23_g54 = lerp( temp_output_40_0_g55 , ( ( ( 1.0 - smoothstepResult11_g56 ) * temp_output_12_0_g56 ) + ( ( 1.0 - smoothstepResult65_g56 ) * abs( sin( ( rainTime246_g56 * UNITY_PI ) ) ) ) ) , rainAxis12_g54);
			float rainMask26_g54 = ( noRainArea17_g54 * lerpResult23_g54 * _RainFade );
			float rainMask296 = rainMask26_g54;
			float3 lerpResult302 = lerp( normalMap87 , BlendNormals( normalMap87 , rainNormals295 ) , rainMask296);
			float3 finalNormalMap303 = lerpResult302;
			float3 newWorldNormal26 = (WorldNormalVector( i , finalNormalMap303 ));
			float3 worldNormal206 = newWorldNormal26;
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float dotResult54 = dot( worldNormal206 , ase_worldViewDir );
			float NdotV181 = abs( dotResult54 );
			o.Emission = ( _Glow * mainTex121 * NdotV181 ).rgb;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT( UnityGI, gi );
				o.Alpha = LightingStandardCustomLighting( o, worldViewDir, gi ).a;
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18800
2085;425;1599;1521;535.685;1120.182;1.356245;True;False
Node;AmplifyShaderEditor.CommentaryNode;103;-4649.072,-849.1859;Inherit;False;1086.169;452.8964;Normal Map;8;28;9;30;137;139;140;153;87;;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureTransformNode;28;-4599.072,-681.2628;Inherit;False;9;False;1;0;SAMPLER2D;;False;2;FLOAT2;0;FLOAT2;1
Node;AmplifyShaderEditor.RangedFloatNode;153;-4479.71,-803.6232;Inherit;False;Property;_NormalScale;Normal Scale;4;0;Create;True;0;0;0;False;0;False;1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;139;-4369,-555.0225;Inherit;False;Constant;_NormalFlip;NormalFlip;13;0;Create;True;0;0;0;False;0;False;1,1,-1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TextureCoordinatesNode;30;-4391.072,-697.2628;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;9;-4166.756,-721.2894;Inherit;True;Property;_BumpMap;Normal Map;3;1;[Normal];Create;False;0;0;0;False;1;Header(Material Properties);False;-1;None;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SwitchByFaceNode;137;-4057.001,-515.0225;Inherit;False;2;0;FLOAT3;1,1,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;140;-3867.001,-569.0225;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;314;581.5013,-720.9963;Inherit;False;RainMain;20;;54;5afea9810a4777e4aaf04a945a148144;0;0;2;FLOAT;0;FLOAT3;31
Node;AmplifyShaderEditor.CommentaryNode;297;531.5013,-797.3536;Inherit;False;489.7418;255.0002;Rain System;2;295;296;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;305;-3517.128,-852.3104;Inherit;False;995.9751;291.0001;Final Normal Map ;6;298;299;300;301;302;303;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;87;-3789.788,-750.9087;Float;False;normalMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;295;776.6833,-657.3535;Inherit;False;rainNormals;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;122;-1473.02,-307.8318;Inherit;True;Property;_MainTex;Tint Texture;1;0;Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;296;778.2431,-747.3536;Inherit;False;rainMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;299;-3467.128,-761.4422;Inherit;False;87;normalMap;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;298;-3466.392,-676.3103;Inherit;False;295;rainNormals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;34;-1185.428,-195.3818;Float;False;Property;_Color;Diffuse Color;0;0;Create;False;0;0;0;False;1;Header(Glass Colour);False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BlendNormalsNode;300;-3230.392,-722.3102;Inherit;False;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;121;-1127.235,-311.8233;Float;False;mainTex;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;301;-3184.392,-802.3104;Inherit;False;296;rainMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;257;-2010.106,1592.989;Inherit;False;1277.973;629.9999;Surface Mask;15;307;165;146;166;149;151;148;143;150;152;96;144;306;308;309;;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;302;-2926.537,-759.1658;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;123;-891.0203,-243.8318;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;43;-1282.262,78.10296;Float;False;Property;_Metallic;Metallic;7;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;303;-2776.153,-768.3614;Inherit;False;finalNormalMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;177;-940.2236,110.738;Inherit;False;metallic;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;269;-4645.663,-25.61247;Inherit;False;2643.855;894.5969;Refracted reflection;35;252;31;255;233;27;241;191;239;238;244;26;243;53;242;240;180;190;119;206;195;186;5;7;1;8;267;6;3;266;4;261;270;292;293;304;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;144;-1952.106,1857.989;Inherit;False;Property;_SurfaceSmoothnessTweak;Surface Smoothness Tweak;15;0;Create;True;0;0;0;False;0;False;0;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;174;-729.0396,-50.83344;Float;False;mainTint;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;96;-1968.106,2017.989;Inherit;True;Property;_SurfaceMask;Surface Mask;12;0;Create;True;0;0;0;False;1;Header(Additional Properties);False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;152;-1612.106,1883.989;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;114;-1680.726,-874.8558;Inherit;False;1190.7;493.9;Occlusion;4;115;117;118;116;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DiffuseAndSpecularFromMetallicNode;42;-482.5618,98.80298;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;3;FLOAT3;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;304;-4617.84,442.2211;Inherit;False;303;finalNormalMap;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;26;-4371.663,442.1873;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ComponentMaskNode;125;-705.0203,-253.8318;Inherit;False;False;False;False;True;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-4563.663,218.1876;Float;False;Property;_Refraction;Refraction Power;10;1;[Gamma];Create;False;0;0;0;False;0;False;0.1;0.137;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;150;-1472.99,1883.555;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;44;-80.24444,215.0795;Float;False;oneMinusReflectivity;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;148;-1952.106,1937.989;Inherit;False;Property;_SurfaceSmoothness;Surface Smoothness ;13;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureTransformNode;117;-1646.417,-627.4614;Inherit;False;115;False;1;0;SAMPLER2D;;False;2;FLOAT2;0;FLOAT2;1
Node;AmplifyShaderEditor.RegisterLocalVarNode;206;-3762.827,151.2283;Inherit;False;worldNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;33;-400.0161,662.6182;Inherit;False;610;309;Premultiplied Alpha;4;38;41;40;39;;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;118;-1412.417,-654.4614;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;307;-1392.165,1979.526;Inherit;False;296;rainMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;35;-1513.43,953.171;Float;False;Property;_Smoothness;Smoothness;6;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;260;-3033.101,1231.862;Inherit;False;737.8884;309;NdotV for fresnel;5;54;57;181;258;259;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;149;-1331.99,1886.555;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;241;-4106.664,220.1876;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;270;-4197.476,692.0044;Inherit;False;Constant;_WavelengthRatios;WavelengthRatios;18;0;Create;True;0;0;0;False;0;False;1,0.8,0.7;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;37;-404.01,19.59497;Float;False;alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;46;-1499.544,861.9796;Inherit;False;44;oneMinusReflectivity;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;27;-4560.663,308.1876;Float;False;Property;_IOR;IOR;9;0;Create;True;0;0;0;False;0;False;1;1;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;306;-1951.839,1670.985;Inherit;False;296;rainMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;63;-1179.828,798.398;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;38;-345.5984,718.595;Inherit;False;37;alpha;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;259;-2983.101,1281.862;Inherit;False;206;worldNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;239;-3918.664,519.1873;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.7;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;308;-1190.002,1963.256;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;238;-3921.664,408.1873;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.8;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;115;-1156.825,-683.7558;Inherit;True;Property;_OcclusionMap;Occlusion Map;16;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;258;-2964.101,1356.862;Float;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;60;-1214.296,948.883;Float;False;smoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;143;-1952.106,1777.989;Inherit;False;Property;_SurfaceLevelTweak;Surface Level Tweak;14;0;Create;True;0;0;0;False;0;False;0;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;191;-4275.664,298.1876;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;244;-3916.664,296.1876;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;242;-3636.939,594.7253;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;39;-345.5983,810.595;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;53;-4371.663,586.1875;Float;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-62.59837,831.595;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;309;-1044.002,1849.256;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;240;-3637.939,479.7252;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;243;-3630.938,350.7253;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;49;-939.5111,773.2219;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;151;-1611.106,1766.989;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;116;-823.0759,-637.6456;Float;False;occlusion;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;54;-2765.163,1331.882;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;146;-1474.99,1788.555;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RefractOpVec;190;-3484.865,545.7395;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;119;-3424.168,672.4438;Inherit;False;116;occlusion;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;48;-811.5111,782.2219;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;41;74.40163,763.595;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;57;-2644.666,1334.442;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;268;-14.57957,1552.712;Inherit;False;1323.339;645.322;;15;224;208;203;209;225;217;213;214;205;207;210;211;287;288;290;The lower surface smoothness is, the darker the shadow. The higher base opacity is, the darker the shadow.;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;166;-1009.133,2107.113;Inherit;False;surfaceSmoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;195;-3427.94,753.9844;Inherit;False;60;smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RefractOpVec;186;-3472.865,313.7394;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RefractOpVec;180;-3479.418,428.9757;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;51;-658.4658,757.0433;Float;False;grazingTerm;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectSpecularLight;5;-3105.607,475.3742;Inherit;False;World;3;0;FLOAT3;0,0,1;False;1;FLOAT;1;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;165;-970.7523,1639.47;Inherit;False;surfaceLevel;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;211;41.96495,2018.231;Inherit;False;166;surfaceSmoothness;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectSpecularLight;7;-3108.607,589.3744;Inherit;False;World;3;0;FLOAT3;0,0,1;False;1;FLOAT;1;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.IndirectSpecularLight;1;-3106.264,359.3875;Inherit;False;World;3;0;FLOAT3;0,0,1;False;1;FLOAT;1;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;212;250.2271,659.2321;Inherit;False;premultipliedAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;181;-2521.212,1326.905;Inherit;False;NdotV;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;6;-2795.291,500.3476;Inherit;False;False;True;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;217;19.29852,1846.283;Inherit;False;Property;_ShadowTransparency;Shadow Transparency;18;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;210;277.2499,2020.44;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;8;-2790.291,581.3478;Inherit;False;False;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;52;-343.966,549.6431;Inherit;False;51;grazingTerm;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;205;41.9798,1607.05;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;214;263.9944,2095.555;Inherit;False;165;surfaceLevel;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;207;72.59271,1753.017;Inherit;False;206;worldNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;213;41.96499,1938.698;Inherit;False;212;premultipliedAlpha;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RefractOpVec;267;-3480.094,128.9204;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;182;-334.6748,462.5696;Inherit;False;181;NdotV;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;3;-2799.948,427.3608;Inherit;False;True;False;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;280;253.5596,893.3448;Inherit;False;Constant;_Float1;Float 1;18;0;Create;True;0;0;0;False;0;False;0.3333333;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;225;485.3874,1727.378;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;4;-2569.948,443.3608;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;209;491.5468,1958.582;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectSpecularLight;266;-3099.447,122.2613;Inherit;False;World;3;0;FLOAT3;0,0,1;False;1;FLOAT;1;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;203;376.3474,1660.134;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;47;-108.5445,506.4797;Float;False; return FresnelLerp (specColor, grazingTerm, nv)@;3;False;3;True;specColor;FLOAT3;1,1,1;In;;Float;False;True;grazingTerm;FLOAT;1;In;;Float;False;True;nv;FLOAT;0;In;;Float;False;FresnelLerp;True;False;0;3;0;FLOAT3;1,1,1;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;91;-929.3141,1389.613;Inherit;False;303;finalNormalMap;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;279;568.9509,570.931;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0.3333333;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;168;548.9317,781.6509;Inherit;False;165;surfaceLevel;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;284;141.748,354.0918;Inherit;False;206;worldNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;164;-725.6722,1386.528;Inherit;False;True;True;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;208;713.5927,1672.017;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;0.5;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;287;725.098,1852.83;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;292;-2439.319,267.5704;Inherit;False;Property;_UseColourShift;Use Colour Shift;8;0;Create;True;0;0;0;False;0;False;0;0;0;True;BLOOM;Toggle;2;Key0;Key1;Create;False;False;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;199;-128.4541,1340.07;Inherit;False;181;NdotV;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectDiffuseLighting;272;356.9833,357.9115;Inherit;False;World;1;0;FLOAT3;0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;224;928.1288,1681.635;Inherit;False;Lerp White To;-1;;52;047d7c189c36a62438973bad9d37b1c2;0;2;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;290;906.098,1863.83;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;178;-602.2236,1051.738;Inherit;False;177;metallic;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;167;-477.0912,1230.584;Inherit;False;166;surfaceSmoothness;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;175;-601.2544,1126.483;Inherit;False;174;mainTint;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldNormalVector;157;-478.6218,1319.428;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;261;-2239.508,438.6044;Inherit;False;finalRefraction;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;120;-463.6904,1471.434;Inherit;False;116;occlusion;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;56;-959.6453,955.1857;Float;False;return SmoothnessToRoughness(smoothness)@$;1;False;1;True;smoothness;FLOAT;0;In;;Float;False;Smoothness to Roughness;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;313;324.8417,271.9823;Inherit;False;Property;_InteriorDiffuseStrength;Interior Diffuse Strength;11;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;99;911.86,868.205;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;200;38.5459,1347.07;Inherit;False;return 1-Pow5(1-x)@;1;False;1;True;x;FLOAT;0;In;;Inherit;False;InvFresnelPow5;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;310;607.0179,336.7751;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;262;-83.66589,423.0506;Inherit;False;261;finalRefraction;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;106;1130.973,899.6028;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;288;1126.098,1689.83;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.IndirectSpecularLight;66;-61.0536,1210.823;Inherit;False;Tangent;3;0;FLOAT3;0,0,1;False;1;FLOAT;1;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;55;-721.6453,958.1857;Float;False;    half surfaceReduction@$#   ifdef UNITY_COLORSPACE_GAMMA$        surfaceReduction = 1.0-0.28*roughness*perceptualRoughness@      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0@1]$#   else$        surfaceReduction = 1.0 / (roughness*roughness + 1.0)@           // fade \in [0.5@1]$#   endif$    return surfaceReduction@$;1;False;1;True;roughness;FLOAT;0;In;;Float;False;surfaceReduction;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;176;-351.2544,1035.483;Inherit;False;Lerp White To;-1;;53;047d7c189c36a62438973bad9d37b1c2;0;2;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;201;1330.75,1114.151;Inherit;False;Property;_Keyword0;Keyword 0;16;0;Create;True;0;0;0;False;0;False;0;0;0;False;UNITY_PASS_SHADOWCASTER;Toggle;2;Key0;Key1;Fetch;False;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;45;227.5556,461.4798;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;283;759.4806,571.7301;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;169;317.6324,1028.665;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;256;-3082.375,1589.917;Inherit;False;1049.774;632.4728;Dithering;10;254;235;228;247;250;249;245;232;230;231;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;215;1641.683,1107.431;Inherit;False;finalOpacity;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;109;673.8463,-312.2968;Float;False;Property;_Glow;Glow Strength;2;1;[HDR];Create;False;0;0;0;False;0;False;0,0,0,0;0,0,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;291;677.0161,-65.16928;Inherit;False;181;NdotV;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;100;854.1592,397.6246;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;126;673.2981,-149.0094;Inherit;False;121;mainTex;1;0;OBJECT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.FractNode;250;-2731.229,1716.356;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;226;496.5859,1375.314;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;233;-4265.664,78.18761;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;104;-66.38965,125.9029;Float;False;finalAlbedo;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;232;-2737.601,1855.733;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;249;-2883.229,1664.356;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;7;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;255;-4499.663,122.1875;Inherit;False;254;dither;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;112;918.2114,-159.6459;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;216;923.9498,278.3799;Inherit;False;215;finalOpacity;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;172;-923.5332,-7.15497;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;228;-2467.601,1856.26;Inherit;False;const float a1 = 0.75487766624669276@$const float a2 = 0.569840290998@$return frac(a1 * float(pixel.x) + a2 * float(pixel.y))@;1;False;1;True;pixel;FLOAT2;0,0;In;;Inherit;False;R2noise;True;False;0;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenParams;231;-2960.601,2015.733;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;133;-95.52808,-87.59631;Float;False;specColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;235;-2303.144,1854.422;Inherit;False;return z >= 0.5 ? 2.-2.*z : 2.*z@;1;False;1;True;z;FLOAT;0;In;;Inherit;False;T;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;254;-2260.358,2105.391;Inherit;False;dither;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;252;-4528.265,24.38753;Inherit;False;Property;_DitheredRefraction;Dithered Refraction;19;0;Create;True;0;0;0;False;1;ToggleUI;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;245;-3057.375,1642.917;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMaxOpNode;170;990.654,398.5679;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;247;-2598.375,1854.917;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;171;-1194.017,0.7037628;Inherit;False;165;surfaceLevel;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;230;-3000.601,1849.733;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.IntNode;113;-458.7034,-215.9207;Float;False;Property;_CullMode;Cull Mode;17;1;[Enum];Create;True;0;0;1;UnityEngine.Rendering.CullMode;True;0;False;0;2;False;0;1;INT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;-57.01001,15.59497;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1197.285,109.4671;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;Silent/FakeGlass Rain;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;2;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;-6;True;Custom;;Transparent;All;14;all;True;True;True;False;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;1;1;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;5;-1;-1;-1;0;False;0;0;True;113;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;True;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.CommentaryNode;293;-2467.636,42.50848;Inherit;False;429;100;Keyword used is BLOOM to conserve keywords;0;;1,1,1,1;0;0
WireConnection;30;0;28;0
WireConnection;30;1;28;1
WireConnection;9;1;30;0
WireConnection;9;5;153;0
WireConnection;137;1;139;0
WireConnection;140;0;9;0
WireConnection;140;1;137;0
WireConnection;87;0;140;0
WireConnection;295;0;314;31
WireConnection;296;0;314;0
WireConnection;300;0;299;0
WireConnection;300;1;298;0
WireConnection;121;0;122;0
WireConnection;302;0;299;0
WireConnection;302;1;300;0
WireConnection;302;2;301;0
WireConnection;123;0;121;0
WireConnection;123;1;34;0
WireConnection;303;0;302;0
WireConnection;177;0;43;0
WireConnection;174;0;123;0
WireConnection;152;0;144;0
WireConnection;152;1;96;1
WireConnection;42;0;174;0
WireConnection;42;1;177;0
WireConnection;26;0;304;0
WireConnection;125;0;123;0
WireConnection;150;0;152;0
WireConnection;44;0;42;2
WireConnection;206;0;26;0
WireConnection;118;0;117;0
WireConnection;118;1;117;1
WireConnection;149;0;150;0
WireConnection;149;1;148;0
WireConnection;241;0;31;0
WireConnection;37;0;125;0
WireConnection;63;0;46;0
WireConnection;239;0;241;0
WireConnection;239;1;270;3
WireConnection;308;0;149;0
WireConnection;308;1;307;0
WireConnection;238;0;241;0
WireConnection;238;1;270;2
WireConnection;115;1;118;0
WireConnection;60;0;35;0
WireConnection;191;0;27;0
WireConnection;244;0;241;0
WireConnection;244;1;270;1
WireConnection;242;0;191;0
WireConnection;242;1;239;0
WireConnection;39;0;46;0
WireConnection;40;0;38;0
WireConnection;40;1;46;0
WireConnection;309;0;308;0
WireConnection;240;0;191;0
WireConnection;240;1;238;0
WireConnection;243;0;191;0
WireConnection;243;1;244;0
WireConnection;49;0;60;0
WireConnection;49;1;63;0
WireConnection;151;0;96;1
WireConnection;151;1;143;0
WireConnection;151;2;306;0
WireConnection;116;0;115;2
WireConnection;54;0;259;0
WireConnection;54;1;258;0
WireConnection;146;0;151;0
WireConnection;190;0;53;0
WireConnection;190;1;26;0
WireConnection;190;2;242;0
WireConnection;48;0;49;0
WireConnection;41;0;39;0
WireConnection;41;1;40;0
WireConnection;57;0;54;0
WireConnection;166;0;309;0
WireConnection;186;0;53;0
WireConnection;186;1;26;0
WireConnection;186;2;243;0
WireConnection;180;0;53;0
WireConnection;180;1;26;0
WireConnection;180;2;240;0
WireConnection;51;0;48;0
WireConnection;5;0;180;0
WireConnection;5;1;195;0
WireConnection;5;2;119;0
WireConnection;165;0;146;0
WireConnection;7;0;190;0
WireConnection;7;1;195;0
WireConnection;7;2;119;0
WireConnection;1;0;186;0
WireConnection;1;1;195;0
WireConnection;1;2;119;0
WireConnection;212;0;41;0
WireConnection;181;0;57;0
WireConnection;6;0;5;0
WireConnection;210;0;211;0
WireConnection;8;0;7;0
WireConnection;267;0;53;0
WireConnection;267;1;206;0
WireConnection;267;2;191;0
WireConnection;3;0;1;0
WireConnection;225;1;217;0
WireConnection;4;0;3;0
WireConnection;4;1;6;0
WireConnection;4;2;8;0
WireConnection;209;0;213;0
WireConnection;209;1;210;0
WireConnection;209;2;214;0
WireConnection;266;0;267;0
WireConnection;266;1;195;0
WireConnection;266;2;119;0
WireConnection;203;0;205;0
WireConnection;203;1;207;0
WireConnection;47;0;42;1
WireConnection;47;1;52;0
WireConnection;47;2;182;0
WireConnection;279;0;47;0
WireConnection;279;1;280;0
WireConnection;164;0;91;0
WireConnection;208;0;203;0
WireConnection;208;2;225;0
WireConnection;208;3;209;0
WireConnection;287;0;225;0
WireConnection;292;1;266;0
WireConnection;292;0;4;0
WireConnection;272;0;284;0
WireConnection;224;1;208;0
WireConnection;224;2;217;0
WireConnection;290;0;287;0
WireConnection;157;0;164;0
WireConnection;261;0;292;0
WireConnection;56;0;60;0
WireConnection;99;0;41;0
WireConnection;99;1;168;0
WireConnection;99;2;279;0
WireConnection;200;0;199;0
WireConnection;310;0;313;0
WireConnection;310;1;272;0
WireConnection;106;0;99;0
WireConnection;288;0;224;0
WireConnection;288;1;290;0
WireConnection;66;0;157;0
WireConnection;66;1;167;0
WireConnection;66;2;120;0
WireConnection;55;0;56;0
WireConnection;176;1;175;0
WireConnection;176;2;178;0
WireConnection;201;1;106;0
WireConnection;201;0;288;0
WireConnection;45;0;262;0
WireConnection;45;1;47;0
WireConnection;45;2;55;0
WireConnection;283;0;310;0
WireConnection;283;1;279;0
WireConnection;169;0;167;0
WireConnection;169;1;66;0
WireConnection;169;2;176;0
WireConnection;169;3;200;0
WireConnection;215;0;201;0
WireConnection;100;0;45;0
WireConnection;100;1;169;0
WireConnection;100;2;283;0
WireConnection;250;0;249;0
WireConnection;233;1;31;0
WireConnection;233;2;252;0
WireConnection;104;0;42;0
WireConnection;232;0;230;0
WireConnection;232;1;231;0
WireConnection;249;0;245;2
WireConnection;112;0;109;0
WireConnection;112;1;126;0
WireConnection;112;2;291;0
WireConnection;172;0;171;0
WireConnection;172;1;43;0
WireConnection;228;0;247;0
WireConnection;133;0;42;1
WireConnection;235;0;228;0
WireConnection;254;0;235;0
WireConnection;170;0;100;0
WireConnection;247;0;232;0
WireConnection;247;1;250;0
WireConnection;36;0;42;0
WireConnection;36;1;37;0
WireConnection;0;0;36;0
WireConnection;0;2;112;0
WireConnection;0;9;216;0
WireConnection;0;13;170;0
ASEEND*/
//CHKSM=25FB719517932AB308F8ED5C5B19CECCC2BC799B