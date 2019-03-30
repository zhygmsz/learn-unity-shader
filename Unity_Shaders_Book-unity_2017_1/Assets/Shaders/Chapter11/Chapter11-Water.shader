Shader "Unity Shaders Book/Chapter 11/Water" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_Magnitude ("Distortion Magnitude", Float) = 1
 		_Frequency ("Distortion Frequency", Float) = 1
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10
 		_Speed ("Speed", Float) = 0.5
	}
	SubShader {
		// Need to disable batching because of the vertex animation
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			
			CGPROGRAM  
			#pragma vertex vert 
			#pragma fragment frag
			
			#include "UnityCG.cginc" 
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			float _Speed;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			v2f vert(a2v v) {
				v2f o;
				
				float4 offset;
				offset.yzw = float3(0.0, 0.0, 0.0);
				offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
				o.pos = UnityObjectToClipPos(v.vertex + offset);
				
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv +=  float2(0.0, _Time.y * _Speed);

				//水波的网格用的不再是quad的四顶点，而是用的mesh片儿，一个细长的带，带的两侧布满了顶点，方便做水波纹顶点扭曲动画。
				//这个片是细长的，和纹理对应起来。水波纹理的条纹是沿着其纹理空间的Y轴的。所以对uv的Y方向进行了同向渐进式偏移，搭配纹理的过滤方式为重复模式。
				//对顶点位置的偏移只是影响最终映射到屏幕上的位置，并不会影响纹理采样的结果。相当于整个水波效果是由顶点动画（正弦函数）+纹理坐标偏移，共同组合出来的。
				
				//扭曲效果复盘，把_Speed设置成0，抛开纹理动画的因素，更容易理解水波扭曲效果的实现方式。
				//当_InvWaveLength为0时，_Frequency为5，_Magnitude为0.05时。其效果是整个细带沿着Scene视图的红轴（X轴）上下移动，呈sin曲线效果。
				//因为对顶点修改的是X坐标，而该X坐标并不是Transform组件里的X，而是对于水波网格自身空间（亦即模型空间下）来说的X，也就是Scene视图下的红轴。
				//现在对于每个顶点来说算出的offset.x都是相同的，所以细带会以一个整体的形式sin曲线移动。为了让每个顶点都有不同的sin曲线效果，引入了vertex.xyz，并引入了一个波长系数。
				//这样sin方法内的值不光和时间（_Time.y）有关，还和每个顶点的位置（v.vertex.xyz）有关，最后计算出的sin函数值，就随着顶点不同而变化了，而该变化正是sin曲线。

				//本来是竖长的带状，经过旋转和缩放，最后横向的摆在了摄像机前。

				//最后放开纹理坐标偏移，就看到了水波效果
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed4 c = tex2D(_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				
				return c;
			} 
			
			ENDCG
		}
	}
	//水波动画在forwardbase理设置的是半透明物体渲染模式，所以fallabck设置了transparent里的。
	//但它没有shadercaster的pass
	FallBack "Transparent/VertexLit"
}
