Shader "Unity Shaders Book/Chapter 15/Water Wave" {
	Properties {
		_Color ("Main Color", Color) = (0, 0.15, 0.115, 1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_WaveMap ("Wave Map", 2D) = "bump" {}
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
		_WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01
		_WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01
		_Distortion ("Distortion", Range(0, 100)) = 10
	}
	SubShader {
		//反射效果，采样立方体贴图，需要生成立方体贴图
		//折射效果，抓取屏幕图像，偏移当前片元uv再采样，一般使用切线空间下的法线来充当偏移
		//生成立方体贴图和抓取屏幕图像，都需要在所有不透明物体渲染完成之后再处理
		//因此Queue是Transparent

		//RenderType是为了着色器替换技术预留的，在计算深度和法线纹理时，unity提供单一方法直接重渲一遍符合要求的物体，而RenderType就是挑选shader的要求
		// We must be transparent, so other objects are drawn before this one.
		Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		
		// This pass grabs the screen behind the object into a texture.
		// We can access the result in the next pass as _RefractionTex
		GrabPass { "_RefractionTex" }
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _WaveMap;
			float4 _WaveMap_ST;
			samplerCUBE _Cubemap;
			fixed _WaveXSpeed;
			fixed _WaveYSpeed;
			float _Distortion;	
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
				float4 TtoW1 : TEXCOORD3;  
				float4 TtoW2 : TEXCOORD4; 
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.scrPos = ComputeGrabScreenPos(o.pos);
				
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);

				//光照可以在切线空间，也可以在世界空间计算
				//但因为该效果是反射（采样立方体纹理）+折射（偏转采样屏幕图像），更适合用世界空间下计算
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				//在世界空间下的三个基向量(TBN)，列优先排列出矩阵，即为切线空间到世界空间的转换矩阵
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				//float2(_WaveXSpeed, _WaveYSpeed)向量决定了水波纹理的偏移方向（用来模拟流动效果）
				//引入_Time.y，是为了随时间变化，但最后的效果是呈现出周期性的
				float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);
				//float2 speed = _Time.y * float2(0, 0);
				
				// Get the normal in tangent space
				fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;
				fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
				fixed3 bump = normalize(bump1 + bump2);
				
				// Compute the offset in tangent space
				//对当前片元的屏幕图像采样uv偏转值
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				//偏转值再经过一次z乘法，目的是折射效果随物体深度变化，越靠水底的物体其折射效果越明显
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				//手动执行透视除法，得出[0, 1]的屏幕坐标，也就是屏幕图像的uv坐标
				//折射颜色只是对屏幕图像的一次扭曲，并没有主纹理颜色参与
				fixed3 refrCol = tex2D( _RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
				
				// Convert the normal to world space
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				//主纹理采样结果和反射颜色叠加
				fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);
				fixed3 reflDir = reflect(-viewDir, bump);
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb * _Color.rgb;
				
				//菲涅尔反射系数本身，是受观察向量和法线的影响，两者越接近反射效果越弱，折射效果越强，符合现实生活体验
				fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);
				//fresnel = 1;  //只有反射没有折射，水面上全是立方体纹理的颜色，水面不透明，看不到下方物体
				fresnel = 0;  //只有折射没有反射，水面完全透明，看到下方，水面上没有反射周围环境的颜色
				fixed3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);

				//水面的波动效果，来自对屏幕图像的扭曲。屏幕图像来自于GrabPass，扭曲来自法线。
				//随时间变化周期性偏移采样发现纹理uv，可以得到连续的波动效果。
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
	}
	// Do not cast shadow
	FallBack Off
}
