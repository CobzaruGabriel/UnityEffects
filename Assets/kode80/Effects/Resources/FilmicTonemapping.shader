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
		_Exposure ("Exposure", Range( 0.0, 16.0)) = 1.5
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
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
			float _Exposure;
			float _Dither;

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

			float3 Hash( float2 seed)
			{
				return float3( frac(sin(dot( seed, float2(12.9898,78.233))) * 43758.5453) * 2.0 - 1.0,
							   frac(sin(dot( -seed, float2(12.9898,78.233))) * 21879.27265) * 2.0 - 1.0,
							   frac(sin(dot( seed.yx, float2(12.9898,78.233))) * 43758.5453) * 2.0 - 1.0);
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float3 texColor = tex2D( _MainTex, i.uv);
				texColor *= _Exposure;

				float ExposureBias = 2.0f;
				texColor *= ExposureBias;

				float3 curr = FilmicTonemap( texColor);

				float3 whiteScale = 1.0f/FilmicTonemap(W);
				float3 color = _Dither ? (curr + Hash( i.vertex) / 1024.0) * whiteScale :
										 curr * whiteScale;

				return float4( color, 1);
			}
			ENDCG
		}
	}
}
