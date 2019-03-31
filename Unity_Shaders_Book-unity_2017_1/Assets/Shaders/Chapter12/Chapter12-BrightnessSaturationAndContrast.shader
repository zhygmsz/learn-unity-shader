Shader "Unity Shaders Book/Chapter 12/Brightness Saturation And Contrast" {
	//属性区域仅仅是为了显示在材质属性面板上的，通过定义和pass里字段同名的属性，来暴露给inspector面板，方便调试
	//当在inspector上调整参数时，会自动修改pass里的同名字段，进而改变shader效果。
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Brightness ("Brightness", Float) = 1
		_Saturation("Saturation", Float) = 1
		_Contrast("Contrast", Float) = 1
	}
	SubShader {
		Pass {  
			ZTest Always
			Cull Off 
			ZWrite Off
			
			CGPROGRAM  
			#pragma vertex vert  
			#pragma fragment frag  
			  
			#include "UnityCG.cginc"  
			  
			sampler2D _MainTex;  
			half _Brightness;
			half _Saturation;
			half _Contrast;
			  
			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv: TEXCOORD0;
			};
			  
			v2f vert(appdata_img v) {
				v2f o;
				
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uv = v.texcoord;

				//后处理是对场景的渲染图做处理，所以一般都是针对像素着色器的
						 
				return o;
			}
		
			fixed4 frag(v2f i) : SV_Target {
				fixed4 renderTex = tex2D(_MainTex, i.uv);

				//以RGB颜色空间讨论后处理概念，亮度，饱和度，对比度。
				//其实这三个概念使用HSV颜色空间会更好理解，更直观。

				// Apply brightness
				//后处理范畴的亮度，就是rgb值本身，值越大，亮度越高。值越小，亮度越低。
				//所以通过一个系数相乘，修改亮度值（rgb值）
				fixed3 finalColor = renderTex.rgb * _Brightness;
				
				// Apply saturation
				//后处理范畴的饱和度概念，是偏离灰色的程度，灰色的饱和度为0
				//以下三个系数(0.2125, 0.7154, 0.0721)就是把同等亮度下的饱和度降到最低。这三个系数是经验系数，没有实际物理含义。
				//换句话说，任何一个RGB空间的颜色，它都有一个亮度，就是他们三个分量自身。也都有一个饱和度，饱和度就是他们偏离灰色的程度
				//而灰色相当于饱和度里的原点，RGB三分量分别乘以三个系数，就得到了该亮度下的灰色，也就是饱和度最低的值。
				//再经过插值可以整体调整画面的饱和度。
				fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
				fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
				finalColor = lerp(luminanceColor, finalColor, _Saturation);
				
				// Apply contrast
				//对比度概念，是颜色的差异程度。(0.5, 0.5, 0.5)是对比度最低。
				//再经过插值可以整体调整画面的对比度。
				fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				finalColor = lerp(avgColor, finalColor, _Contrast);

				//总结，饱和度和对比度都是当前RGB三分量值偏离这个概念原点的程度，而饱和度的原点需要RGB三分量辅助经验系数来构造，而对比度则直接用常量值。
				//再用系数插值这个概念原点和当前RGB三分量，可以整体的调整RGB三分量的这个概念值。达到画面效果的整体概念。
				return fixed4(finalColor, renderTex.a);  
			}  
			  
			ENDCG
		}  
	}
	
	Fallback Off
}
