Shader "Unity Shaders Book/Chapter 7/Texture Properties Test"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
    }

    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag

            #pragma target 5.0

            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 color : COLOR;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.position = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                //原则上，不能在顶点着色器阶段采样纹理
                //但可以选用高级的shadermodel，并选用tex2Dlod方法实现
                o.color = tex2Dlod(_MainTex, float4(o.uv, 0, 0)).rgb;

                //在顶点着色器中采样纹理的四个顶点颜色后，然后在光栅化时插值，最后得到的颜色是深黄色
                //验证这一想法，过程如下
                //获取纹理中四块颜色，并平均出一个新颜色，因为这是正交投影，并且正对着摄像机，以这种方式模拟光栅化的插值
                //试试看是否为同样的深黄色

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //fixed4 c = tex2D(_MainTex, i.uv);
                //return fixed4(c.rgb, 1.0);

                return fixed4(i.color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}