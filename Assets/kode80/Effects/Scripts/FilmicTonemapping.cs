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

using UnityEngine;
using System.Collections;

namespace kode80.Effects
{
	[ExecuteInEditMode]
	public class FilmicTonemapping : MonoBehaviour 
	{
		[Range( 0.0f, 16.0f)]
		public float exposure = 1.5f;
		public float adaptionSpeed = 1.0f;
		public int luminanceTextureSize = 128;
		public float luminanceLow = 0.0f;
		public float luminanceMid = 0.25f;
		public float luminanceHigh = 0.8f;
		public float exposureDown = -1.0f;
		public float exposureUp = 10.0f;

		private Material _material;
		private RenderTexture _prevFrame;
		private RenderTexture _luminanceTexture;
		private Camera _camera;

		// Use this for initialization
		void Start () {
		
		}
		
		// Update is called once per frame
		void Update () {
		
		}

		void OnEnable()
		{
			_camera = GetComponent<Camera>();
		}

		void OnDisable()
		{
			if( _material != null) {
				DestroyImmediate( _material);
				_material = null;
			}

			if( _prevFrame != null) {
				DestroyImmediate( _prevFrame);
				_prevFrame = null;
			}

			if( _luminanceTexture != null) {
				DestroyImmediate( _luminanceTexture);
				_luminanceTexture = null;
			}
		}

		void CreateResourcesIfNeeded()
		{
			if( _material == null)
			{
				_material = new Material( Shader.Find( "Hidden/kode80/Effects/FilmicTonemapping"));
				_material.hideFlags = HideFlags.HideAndDontSave;
			}

			if( _prevFrame == null)
			{
				_prevFrame = new RenderTexture( luminanceTextureSize, luminanceTextureSize, 0, RenderTextureFormat.ARGBHalf);
				_prevFrame.hideFlags = HideFlags.HideAndDontSave;
				_prevFrame.generateMips = true;
				_prevFrame.useMipMap = true;
				ClearRenderTexture( _prevFrame);
			}

			if( _luminanceTexture == null)
			{
				_luminanceTexture = new RenderTexture( 1, 1, 0, RenderTextureFormat.ARGBHalf);
				_luminanceTexture.hideFlags = HideFlags.HideAndDontSave;
				ClearRenderTexture( _luminanceTexture);
			}
		}

		[ImageEffectTransformsToLDR]
		void OnRenderImage( RenderTexture source, RenderTexture destination)
		{
			CreateResourcesIfNeeded();

			Graphics.Blit( source, _prevFrame, _material, 0);

			int lowestMip = (int)Mathf.Log( luminanceTextureSize, 2);
			_material.SetFloat( "_AdaptionSpeed", adaptionSpeed);
			_material.SetFloat( "_LowestMipLevel", lowestMip);
			_material.SetVector( "_LuminanceRange", new Vector4( luminanceLow, luminanceMid, luminanceHigh, 0.0f));
			_material.SetVector( "_ExposureOffset", new Vector4( exposureDown, exposureUp, 0.0f, 0.0f));
			Graphics.Blit( _prevFrame, _luminanceTexture, _material, 1);

			_material.SetFloat( "_Exposure", exposure);
			_material.SetTexture( "_LuminanceTex", _luminanceTexture);

			Graphics.Blit( source, destination, _material, 2);
			RenderTexture.active = null;
		}

		private void ClearRenderTexture( RenderTexture texture)
		{
			RenderTexture oldActive = RenderTexture.active;
			RenderTexture.active = texture;
			GL.Clear( true, true, Color.white);
			RenderTexture.active = oldActive;
		}
	}
}
