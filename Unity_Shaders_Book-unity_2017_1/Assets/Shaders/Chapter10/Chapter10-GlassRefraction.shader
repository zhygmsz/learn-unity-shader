﻿Shader "Unity Shaders Book/Chapter 10/Glass Refraction" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
		_Distortion ("Distortion", Range(0, 1000)) = 10
		_RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0
	}
	SubShader {
		// We must be transparent, so other objects are drawn before this one.
		Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		
		// This pass grabs the screen behind the object into a texture.
		// We can access the result in the next pass as _RefractionTex
		GrabPass { "_RefractionTex" }
		
		Pass {		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			samplerCUBE _Cubemap;
			float _Distortion;
			fixed _RefractAmount;
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float2 texcoord: TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
			    float4 TtoW1 : TEXCOORD3;  
			    float4 TtoW2 : TEXCOORD4; 
				fixed3 worldNormal : TEXCOORD5;
			};
			
			v2f vert (a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.scrPos = ComputeGrabScreenPos(o.pos);
				
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  

				o.worldNormal = worldNormal;
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {		
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				// Get the normal in tangent space
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));	
				
				// Compute the offset in tangent space
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy * i.scrPos.z;
				//i.srcPos.z值看效果应该是一个[0,1]的值，可以确定一下。它的值是否就是被规范到了[0,1]区间内呢？如果是的话找具体哪个过程
				//offset本身是一个偏移值，很小就够了，太大反而效果突兀
				
				//该折射模型用的是grabpass，可以考虑换成透射光漫反射
				//再把反射模型用成环境映射，看下效果
				
				i.scrPos.xy = offset + i.scrPos.xy;
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;

				//复盘分析
				//当_RefractAmount等于1时，即为只有折射（靠法线模拟出来的），没有反射。
				//因为该shader的queue是半透明，所有当该物体被渲染时，场景里已经全渲染完毕了（除了该立方体外）
				//当_Distortion设置成0时，offset也是0，就是说直接用该立方体背后的像素值（_RefractionTex不经偏移的采样结果）填充了该立方体的当前片元。
				//所以看起来该立方体像是透明的一样，完全没有遮挡后面的物体，其实是和后面的物体同色了而已，纯属视觉欺骗
				//当_Distortion的值逐步增加时，offset也会逐步增大，随之采样_RefractionTex出来的颜色值也会表现的更偏差，这个偏差看起来就是玻璃折射后面的物体效果了
				//当偏差加大到一定程度时，折射表现会显现出法线轮廓，这是因为偏差值完全是依赖法线的。

				// Convert the normal to world space
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				fixed3 reflDir = reflect(-worldViewDir, bump);
				//fixed3 worldNormal = normalize(i.worldNormal);
				//fixed3 reflDir = reflect(-worldViewDir, worldNormal);
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				//fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;
				//fixed3 reflCol = texColor.rgb;
				//立方体如果应用了主纹理和法线图，那就是个不透明物体，不应该再应用反射和折射模型
				//如果想应用反射和折射模型，需要是透明物体，也就需要舍弃掉主纹理采样结果
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb;

				//当_RefractAmount等于0时，即为只有反射，没有折射
				//通过观察向量和法线反推出入射光线，再用入射光线对立方体纹理采样，模拟反射效果。
				//_RefractAmount变量没有作用
				//反射（采样立方体纹理）颜色和主纹理采样出来的颜色做了个相乘后，成为最终颜色。
				//相当于反射颜色里融合了主纹理颜色

				//最后的最后，反射（法线也是采样自毫不相关的纹理）和（模拟）折射效果插值到一起去。
				
				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
	}
	
	FallBack "Diffuse"
}
