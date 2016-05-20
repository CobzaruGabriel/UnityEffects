//  Copyright (c) 2016, Ben Hopkins (kode80)
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//  
//  1. Redistributions of source code must retain the above copyright notice, 
//     this list of conditions and the following disclaimer.
//  
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//     this list of conditions and the following disclaimer in the documentation 
//     and/or other materials provided with the distribution.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
//  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
//  OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
//  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Shader "Hidden/kode80/Effects/FilmicTonemapping"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_LuminanceTex ("Luminance", 2D) = "white" {}
		_Exposure ("Exposure", Range( 0.0, 16.0)) = 1.5
		_AdaptionSpeed( "AdaptionSpeed", Range( 0.0, 100.0)) = 1.0
	}

	CGINCLUDE
	#include "UnityCG.cginc"

	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};

	v2f vert (appdata v)
	{
		v2f o;
		o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv = v.uv;
		return o;
	}
	
	sampler2D _MainTex;
	sampler2D _LuminanceTex;
	float _Exposure;
	float _AdaptionSpeed;
	float _LowestMipLevel;
	float4 _LuminanceRange;
	float4 _ExposureOffset;
	float4 _MainTex_TexelSize;

	static const float A = 0.15;
	static const float B = 0.50;
	static const float C = 0.10;
	static const float D = 0.20;
	static const float E = 0.02;
	static const float F = 0.30;
	static const float W = 11.2;

	// Uncharted 2 tonemap from http://filmicgames.com/archives/75
	float3 FilmicTonemap( float3 x)
	{
		return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
	}

	float4 fragLuminance(v2f i) : COLOR 
	{
		float luminance = Luminance( tex2D( _MainTex, i.uv));
 
		return float4(luminance, luminance, luminance, 1.0);
	}

	float4 fragDownsample( v2f i) : SV_Target
	{
		float4 coord = float4( i.uv.xy, 0.0, _LowestMipLevel);
		float luminance = Luminance( tex2Dlod(_MainTex, coord));
		float alpha = saturate( 0.0125 * _AdaptionSpeed);

		return float4( luminance, luminance, luminance, alpha);
	}

	fixed4 fragTonemap(v2f i) : SV_Target
	{
		float2 luminanceColor = tex2D( _LuminanceTex, i.uv).xy;
		float luminance = luminanceColor.x;

		const float previewSize = 0.1;
		float mid = _LuminanceRange.y;
		if( i.uv.x < previewSize && i.uv.y < previewSize) {
			float r = luminance < mid ? smoothstep( _LuminanceRange.y, _LuminanceRange.x, luminance) : 0.0;
			float g = luminance > mid ? smoothstep( _LuminanceRange.y, _LuminanceRange.z, luminance) : 0.0;
			return float4( r, g, 0.0, 1.0);
		}

		float exposureAdjust = luminance >= mid ? smoothstep( _LuminanceRange.y, _LuminanceRange.z, luminance) * _ExposureOffset.x:
												  smoothstep( _LuminanceRange.y, _LuminanceRange.x, luminance) * _ExposureOffset.y;
		float exposure = clamp( 1.0 + exposureAdjust, 0.01, 16.0);
		//float exposure = clamp( _Exposure + exposureAdjust, 0.21, 16.0);

		float3 texColor = tex2D( _MainTex, i.uv);
		texColor *= exposure;
		float ExposureBias = 2.0f;

		float3 curr = FilmicTonemap(ExposureBias*texColor);

		float3 whiteScale = 1.0f/FilmicTonemap(W);
		float3 color = curr*whiteScale;

		return float4( color,1);
	}
	ENDCG

	SubShader
	{
		// 0 luminance pass
		Pass
		{
			ZTest Always Cull Off ZWrite Off
			Fog { Mode off }      

			CGPROGRAM
			#pragma fragmentoption ARB_precision_hint_fastest 
			#pragma vertex vert
			#pragma fragment fragLuminance
			ENDCG
		}
		// 1 downsample blend pass
		Pass
		{
			ZTest Always Cull Off ZWrite Off
			Fog { Mode off }      

			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
	      	#pragma fragmentoption ARB_precision_hint_fastest 
	      	#pragma vertex vert
	      	#pragma fragment fragDownsample
	      	ENDCG
		}
		// 2 Tonemapping pass
		Pass
		{
			ZTest Always Cull Off ZWrite Off
			Fog { Mode off }      

			CGPROGRAM
			#pragma fragmentoption ARB_precision_hint_fastest 
			#pragma vertex vert
			#pragma fragment fragTonemap
			ENDCG
		}
	}

	Fallback off
}
