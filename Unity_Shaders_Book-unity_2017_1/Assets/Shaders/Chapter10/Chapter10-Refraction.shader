Shader "Unity Shaders Book/Chapter 10/Refraction" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_RefractColor ("Refraction Color", Color) = (1, 1, 1, 1)
		_RefractAmount ("Refraction Amount", Range(0, 1)) = 1
		_RefractRatio ("Refraction Ratio", Range(0.1, 1)) = 0.5
		_Cubemap ("Refraction Cubemap", Cube) = "_Skybox" {}
		_Gloss ("Gloss", Range(8, 256)) = 20
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma multi_compile_fwdbase	
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			fixed4 _RefractColor;
			float _RefractAmount;
			fixed _RefractRatio;
			samplerCUBE _Cubemap;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				fixed3 worldRefr : TEXCOORD3;
				SHADOW_COORDS(4)
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				
				//最初不理解物体表面的折射模拟是怎么回事，代码概念和物理名词对应不上。
				//后来看到图后理解了，我们看一个半透明物体时，能透过物体看到后面的环境，而看到的就是折射现象导致的。
				//我们以一个方向观察半透明物体时，真实过程其实是，周围空间的某个点发出的光线，射入半透明物体。
				//入物体时发生一次折射，光线有所偏转，出物体时又发生一次折射，光线被矫正回来。
				//入物体前的光线方向和出物体后的是平行的，只是只是发生了弯折，这便是折射的本质。

				//因此我们还是以反推的方式，由观察方向（出物体后光线方向）开始，反向推出了入物体前光线方向
				//用这个入物体前光线方向采样立方体纹理，并着色在物体表面上，即描述了该物体表面折射周围空间。

				//但计算两次折射比较麻烦，而一次折射后的效果看起来也很好，所以就用一次折射代替了物理上真正的折射。
				// Compute the refract dir in world space
				o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);
				
				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);
				fixed3 halfDir = normalize(worldLightDir + worldViewDir);
								
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));
				fixed3 specular = _LightColor0.rgb * _Color.rgb * pow(saturate(dot(halfDir, worldNormal)), _Gloss);
				
				// Use the refract dir in world space to access the cubemap
				fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				
				// Mix the diffuse color with the refract color
				fixed3 color = ambient + lerp(diffuse + specular, refraction, _RefractAmount) * atten;
				
				return fixed4(color, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Reflective/VertexLit"
}
