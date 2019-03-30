Shader "Unity Shaders Book/Chapter 11/Billboard" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1 
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
			
			#include "Lighting.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed _VerticalBillboarding;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				//脱离于真实物体中心点，利用简单的零点来假定中心点。
				float3 center = float3(0, 0, 0);
				//并把世界空间下的摄像机位置也转换到该物体的模型空间下，结合这一句，上文中的(0,0,0)其实是物体模型空间下的零点
				float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1));
				
				//确定了法线
				float3 normalDir = viewer - center;
				normalDir = normalize(normalDir);

				//一般做法是选取(0,1,0)作为近似up方向和法线一起求出正确的right方向，但这里做了一个判断，当法线方向无限接近(0,1,0)时，换作用(0, 0, 1)
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
				float3 rightDir = normalize(cross(upDir, normalDir));

				//用正确的法线和right求出正确的up
				upDir = normalize(cross(normalDir, rightDir));

				//最后得到的right,up,normal都是单位向量，用来构建正交基，进而构造旋转矩阵。

				//当_VerticalBillboarding为1时，表明物体up方向始终朝上，例如场景里的树木，花草，以及头顶的title
				//当为0时，则表明不限制up方向，这样随着摄像机移动，物体会在竖直方向上倾斜，不符合现实情况。
				//场景中使用公告板技术时，一般选择第一种方式。
				if (_VerticalBillboarding == 1)
				{
					//强制纠正物体的up方向
					upDir.y = 1;
				}
				//至此，所有的工作都是围绕这假定中心点来的，包括right,up,normal这三个基向量。

				//相当于在位置(0,0,0)处构造了一个坐标系，三个轴向分别是right,up.normal
				
				//三个基向量按照列优先方式组合出的旋转矩阵是从新坐标系转（以(0,0,0)为原点，以right,up,normal为三个轴向）到旧坐标系（以物体真实局部坐标系）的。但我们的需求是从旧坐标系转到到新坐标系。
				//所以三个基向量就按照行优先的方式排列出来。对应(rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z)
				
				//真实物体的顶点先平移到新坐标系的原点处
				float3 centerOffs = v.vertex.xyz - center;
				//应用旋转矩阵，之后再平移回去。这就就得到了真实物体顶点的正确旋转。
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
				//这一过程中，额外引入的(0,0,0)以及新坐标系，只是为了计算旋转方便。像是一个操作外壳，把旋转矩阵算出后，拿真实物体的顶点平移过来后旋转，之后再平移回去。
				//所以直接拿真实物体的顶点坐标来应用旋转矩阵是错误的，因为这两个本质上没关系。
				
				o.pos = UnityObjectToClipPos(float4(localPos, 1));

				//o.pos = UnityObjectToClipPos(v.vertex);

				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				fixed4 c = tex2D (_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				
				return c;
			}
			
			ENDCG
		}
	} 
	FallBack "Transparent/VertexLit"
}
