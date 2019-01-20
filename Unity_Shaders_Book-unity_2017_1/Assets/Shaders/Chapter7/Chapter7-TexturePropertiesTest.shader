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
                o.color = tex2Dlod(_MainTex, float4(o.uv, 0, 0)).xyz;

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