///
///  Reference: 	Praun E, Hoppe H, Webb M, et al. Real-time hatching[C]
///						Proceedings of the 28th annual conference on Computer graphics and interactive techniques. ACM, 2001: 581.
///
Shader "Unity Shaders Book/Chapter 14/Hatching" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_TileFactor ("Tile Factor", Float) = 1
		_Outline ("Outline", Range(0, 1)) = 0.1
		_Hatch0 ("Hatch 0", 2D) = "white" {}
		_Hatch1 ("Hatch 1", 2D) = "white" {}
		_Hatch2 ("Hatch 2", 2D) = "white" {}
		_Hatch3 ("Hatch 3", 2D) = "white" {}
		_Hatch4 ("Hatch 4", 2D) = "white" {}
		_Hatch5 ("Hatch 5", 2D) = "white" {}
	}
	
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		UsePass "Unity Shaders Book/Chapter 14/Toon Shading/OUTLINE"
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag 
			
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"
			
			fixed4 _Color;
			float _TileFactor;
			sampler2D _Hatch0;
			sampler2D _Hatch1;
			sampler2D _Hatch2;
			sampler2D _Hatch3;
			sampler2D _Hatch4;
			sampler2D _Hatch5;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 tangent : TANGENT; 
				float3 normal : NORMAL; 
				float2 texcoord : TEXCOORD0; 
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed3 hatchWeights0 : TEXCOORD1;
				fixed3 hatchWeights1 : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				SHADOW_COORDS(4)
			};
			
			v2f vert(a2v v) {
				v2f o;
				
				o.pos = UnityObjectToClipPos(v.vertex);

				//模型和线条纹理之间对比，模型较大，线条纹理较小，这是基础和前提
				
				//_TileFactor系数的作用
				//当为1时，则是一张小线条纹理贴在模型上，会导致模型上的很多个点的uv坐标采样纹理时都是同一个纹素。感觉上模型上的线条很粗，像是纹理放大后的效果
				//当值等于2时，以前的uv[0, 1]经过扩大后，再采样。效果上相当于有2*2张线条纹理按照OpenGL纹理坐标系的XY轴正方向顺序排列。
				//当值越来越大时，采样时等效的一张纹理图尺寸也在变大，“倍增”现象逐渐减弱并消失。最后模型上的线条粗细和纹理上的一致。
				//因为线条纹理较小，模型较大，所以，值增大的过程其实就是削弱“倍增”效果的过程，直到倍增被彻底消除，模型上的线条效果上等同纹理上的线条粗细
				//值再接着增大，就会出现“收缩”效果，模型上的线条比纹理上的更细
				//总之，_TileFactor调整的过程，就是模型上的线条粗细调整过程
				o.uv = v.texcoord.xy * _TileFactor;
				
				fixed3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed diff = max(0, dot(worldLightDir, worldNormal));
				//计算顶点法线和光照向量之间的点乘结果，当两个向量越靠近，结果越接近1。法线和光照向量垂直则为0，夹角大于90度则为负，被夹逼在0。
				
				o.hatchWeights0 = fixed3(0, 0, 0);
				o.hatchWeights1 = fixed3(0, 0, 0);
				
				//diff是一个[0, 1]之间的值，乘以7后，扩大都[0, 7]，刚好是6个区段
				float hatchFactor = diff * 7.0;
				
				if (hatchFactor > 6.0) {
					// Pure white, do nothing
					//光照向量和法线近似同向，系数全为0
				} else if (hatchFactor > 5.0) {
					o.hatchWeights0.x = hatchFactor - 5.0;
					//这里仅次于同向，但方向上也是很近似，只是给了一个系数
					//剩下的区段内，都是赋予两个系数，只是不同位置。
				} else if (hatchFactor > 4.0) {
					o.hatchWeights0.x = hatchFactor - 4.0;
					o.hatchWeights0.y = 1.0 - o.hatchWeights0.x;
				} else if (hatchFactor > 3.0) {
					o.hatchWeights0.y = hatchFactor - 3.0;
					o.hatchWeights0.z = 1.0 - o.hatchWeights0.y;
				} else if (hatchFactor > 2.0) {
					o.hatchWeights0.z = hatchFactor - 2.0;
					o.hatchWeights1.x = 1.0 - o.hatchWeights0.z;
				} else if (hatchFactor > 1.0) {
					o.hatchWeights1.x = hatchFactor - 1.0;
					o.hatchWeights1.y = 1.0 - o.hatchWeights1.x;
				} else {
					o.hatchWeights1.y = hatchFactor;
					o.hatchWeights1.z = 1.0 - o.hatchWeights1.y;
				}
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				TRANSFER_SHADOW(o);
				
				return o; 
			}
			
			fixed4 frag(v2f i) : SV_Target {			
				fixed4 hatchTex0 = tex2D(_Hatch0, i.uv) * i.hatchWeights0.x;
				fixed4 hatchTex1 = tex2D(_Hatch1, i.uv) * i.hatchWeights0.y;
				fixed4 hatchTex2 = tex2D(_Hatch2, i.uv) * i.hatchWeights0.z;
				fixed4 hatchTex3 = tex2D(_Hatch3, i.uv) * i.hatchWeights1.x;
				fixed4 hatchTex4 = tex2D(_Hatch4, i.uv) * i.hatchWeights1.y;
				fixed4 hatchTex5 = tex2D(_Hatch5, i.uv) * i.hatchWeights1.z;
				//以上6个采样结果受系数影响
				//近似同向的都为0，二等近似同向的只有一个有效颜色，其余区段有两个有效颜色

				//以下公式是为了补充白色，当近似同向时，系数全为0，whiteColor为1（纯白）。二等近似同向时，只有一个系数为[0, 1]，whiteColor有瑕疵的白
				//剩下的区段内，存在两个系数，并且和为1，所以whiteColor为0
				fixed4 whiteColor = fixed4(1, 1, 1, 1) * (1 - i.hatchWeights0.x - i.hatchWeights0.y - i.hatchWeights0.z - 
							i.hatchWeights1.x - i.hatchWeights1.y - i.hatchWeights1.z);
				
				fixed4 hatchColor = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteColor;
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
								
				return fixed4(hatchColor.rgb * _Color.rgb * atten, 1.0);
			}
			
			ENDCG
		}
	}
	FallBack "Diffuse"
}
