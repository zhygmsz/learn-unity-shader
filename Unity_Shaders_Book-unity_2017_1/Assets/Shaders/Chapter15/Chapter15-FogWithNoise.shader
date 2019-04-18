Shader "Unity Shaders Book/Chapter 15/Fog With Noise" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_FogDensity ("Fog Density", Float) = 1.0
		_FogColor ("Fog Color", Color) = (1, 1, 1, 1)
		_FogStart ("Fog Start", Float) = 0.0
		_FogEnd ("Fog End", Float) = 1.0
		_NoiseTex ("Noise Texture", 2D) = "white" {}
		_FogXSpeed ("Fog Horizontal Speed", Float) = 0.1
		_FogYSpeed ("Fog Vertical Speed", Float) = 0.1
		_NoiseAmount ("Noise Amount", Float) = 1
	}
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		float4x4 _FrustumCornersRay;
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture;
		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;
		sampler2D _NoiseTex;
		half _FogXSpeed;
		half _FogYSpeed;
		half _NoiseAmount;
		
		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float2 uv_depth : TEXCOORD1;
			float4 interpolatedRay : TEXCOORD2;
		};
		
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif
			
			int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
				index = 0;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
				index = 1;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
				index = 2;
			} else {
				index = 3;
			}
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index;
			#endif
			
			o.interpolatedRay = _FrustumCornersRay[index];
				 	 
			return o;
		}
		
		fixed4 frag(v2f i) : SV_Target {
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
			
			//float2(_FogXSpeed, _FogYSpeed)即是速度，也是采样变化方向，表现上为雾的流动方向
			float2 speed = _Time.y * float2(_FogXSpeed, _FogYSpeed);
			//_NoiseAmount过大导致雾明显分块
			float noise = (tex2D(_NoiseTex, i.uv + speed).r - 0.5) * _NoiseAmount;

			//和13章节不同的地方就是噪声，采样噪声纹理用的是采样主纹理的uv
			//noise = 0;

			//计算雾强度的公式里，分子是雾高度上限 - y坐标。
			//如果距离过高，则值为负数，最后的强度值为0，在后面插值时表现为纯粹主纹理（屏幕图像自身）颜色
			//如果距离过低，则值为正数，并且比较大，最后会是1，在后面插值时表现为纯粹的雾颜色
			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
			//_FogDensity，手动调整的整体强度，值过大，则会变相的拉高_FodEnd，使得雾线提高
			//noise，从噪声采样的来的变数，并且uv坐标在随时间变化
			fogDensity = saturate(fogDensity * _FogDensity * (1 + noise));
			
			//雾的稀薄分散是引入了噪声，对雾强度做了一次加工
			//雾的流动，是采样噪声纹理的uv坐标随时间变化
			fixed4 finalColor = tex2D(_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
			
			return finalColor;
		}
		
		ENDCG
		
		Pass {          	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG
		}
	} 
	FallBack Off
}
