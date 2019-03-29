Shader "Unity Shaders Book/Chapter 11/Scrolling Background" {
	Properties {
		_MainTex ("Base Layer (RGB)", 2D) = "white" {}
		_DetailTex ("2nd Layer (RGB)", 2D) = "white" {}
		_ScrollX ("Base layer Scroll Speed", Float) = 1.0
		_Scroll2X ("2nd layer Scroll Speed", Float) = 1.0
		_Multiplier ("Layer Multiplier", Float) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;
			sampler2D _DetailTex;
			float4 _MainTex_ST;
			float4 _DetailTex_ST;
			float _ScrollX;
			float _Scroll2X;
			float _Multiplier;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
			};
			
			v2f vert (a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				//o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
				//o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);

				//纹理坐标偏移的工作从顶点着色器挪到片元着色器也是一样的效果，本质上是随着时间递增，渐进式的朝一个方向偏移，并搭配纹理的过滤方式为重复模式。
				//背景层偏移系数为0.07（7/100），前景层偏移系数为0.05（5/100），虽然着色器方法是每帧调用，但_Time.y是每秒加1
				//如果以每秒来看待纹理坐标偏移，则float2(_ScrollX, 0.0) * _Time.y这一部分是一直倍增的，系数就是7/100，但frac方法取的是小数部分
				//这样就会出现一个问题，在超过1的节点上，那次偏移值不是7/100
				//5/100这个系数更有问题，换成5/10更好理解，秒从0/1/2/3的增加，而frac方法后的结果却是，0/0.5/0/0.5。而正确的结果应该是0/0.5/1/0.5/1并以此递增0.5
				//以这种方式实现的纹理动画，本质上是不精确的，或是不准确的，只是差别很细微，不明显而已。

				//精确的计算方式，以重复模式，每次步进相同长度。
				//其实用_Time.y来做自变量，会受到帧率的影响，因为帧与帧之间的时长差异会体现在不同次的_Time.y上。但游戏效果也确实如此，游戏卡也体现出纹理动画卡
				float offsetX = _ScrollX * _Time.y;
				if (offsetX > 1)
				{
					offsetX -= 1;
				}
				float offset2X = _Scroll2X * _Time.y;
				if (offset2X > 1)
				{
					offset2X -= 1;
				}
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + float2(offsetX, 0);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + float2(offset2X, 0);

				//o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				//o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex);
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				//fixed4 firstLayer = tex2D(_MainTex, i.uv.xy + frac(float2(_ScrollX, 0.0) * _Time.y));
				//fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw + frac(float2(_Scroll2X, 0.0) * _Time.y));
				fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
				fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);
				
				fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);
				c.rgb *= _Multiplier;
				
				return c;
			}
			
			ENDCG
		}
	}
	FallBack "VertexLit"
}
