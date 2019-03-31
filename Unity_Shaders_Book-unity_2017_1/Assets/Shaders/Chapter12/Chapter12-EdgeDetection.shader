Shader "Unity Shaders Book/Chapter 12/Edge Detection" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
	}
	SubShader {
		Pass {  
			ZTest Always
			Cull Off
			ZWrite Off
			
			CGPROGRAM
			
			#include "UnityCG.cginc"
			
			#pragma vertex vert  
			#pragma fragment fragSobel
			
			sampler2D _MainTex;  
			uniform half4 _MainTex_TexelSize;
			fixed _EdgeOnly;
			fixed4 _EdgeColor;
			fixed4 _BackgroundColor;
			
			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv[9] : TEXCOORD0;
			};
			  
			v2f vert(appdata_img v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				half2 uv = v.texcoord;
				
				//理解上，边缘检测针对的是一张图像的各个纹素，理应在像素着色器中根据当前像素的uv，再加上边缘检测算子，利用纹素大小，算出算子内每个格子对应的uv。
				//但这里却把计算过程放到了顶点着色器内，该示例用的是一张图片，只有四个顶点，相当于只计算了图片的四个顶点的算子内格子uv值。
				//因为光栅化插值过程是线性的，所以对于图片覆盖到的屏幕上其他像素来说，线性插值后得到的uv[9]数组里的值，和像素着色器里计算出来的是一样的。
				//换个角度理解，uv[9]数组内的纹理坐标偏移是固定的，和具体哪个片元无关，只计算四个顶点的uv[9]，随后uv[9]随着光栅化线性插值到每个片元里
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
						 
				return o;
			}
			
			fixed luminance(fixed4 color) {
				return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
			}
			
			half Sobel(v2f i) {
				const half Gx[9] = {-1,  0,  1,
										-2,  0,  2,
										-1,  0,  1};
				const half Gy[9] = {-1, -2, -1,
										0,  0,  0,
										1,  2,  1};		
				
				half texColor;
				half edgeX = 0;
				half edgeY = 0;
				for (int it = 0; it < 9; it++) {
					//相邻的两个纹素判定是否存在边界，需要对纹素内的rgb分量做公式计算，这里统一用luminance方法，把一个纹素的rgb三分量对应到一个数值上
					//也就是说，判定边界时，不再用纹素的rgb三分量，而是用经过luminance后的数值代替了
					//至于为什么用luminance方法，如果考虑更佳复杂的情况，是否需要引入额外的计算，来计算替代值。
					texColor = luminance(tex2D(_MainTex, i.uv[it]));
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
				}
				
				half edge = 1 - abs(edgeX) - abs(edgeY);
				//edge值的含义是，该片元是边界的可能性。edge越小，可能性越高。edge越大，可能性越小。
				
				return edge;
			}
			
			fixed4 fragSobel(v2f i) : SV_Target {
				half edge = Sobel(i);
				
				//实际效果来看，图片的边界处，黑边很明显，说明edge越倾向于0
				//图片的纯色处，还是原来的样子，几乎没受影响，说明edge越倾向于1
				fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);
				fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
				//分别计算出，原图颜色时的边界倾向性颜色，和背景图颜色时的边界倾向性颜色。
				//然后再引入一个【只显示边界的倾向性】的值来插值以上得到的两个颜色。
				//当_EdgeOnly为0时，表示普通的描边效果，只有边界处有黑色描边效果，其余地方不变。
				//当_EdgeOnly为1时，表示边界处有描边效果，其余地方根据edge程度变成了_BackgroundColor颜色。
				return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
 			}
			
			ENDCG
		} 
	}
	FallBack Off
}
