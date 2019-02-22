shader "Unity Shaders Book/Chapter 5/Test1 Shader"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            uniform fixed4 _Color;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 c = i.color;
                c *= _Color.rgb;
                //return fixed4(c, 1.0);

                //测试_WorldSpaceLightPos0.xyz变量的值，是否是平行光的方向的相反数
                //最后查看官网得知，_WorldSpaceLightPos0.xyz存储的是世界空间下平行光的方向，并不是之前以为的方向相反
                //现在的疑问是：通过旋转矩阵的方式求得的三个基向量，和求由模型空间到切线空间的矩阵方式对不上了？
                //总是相反的？应该是哪里出了岔子，或者是某一个节点出了错误
                //而且对于unity检视面板上的x轴30旋转，如何把30代入旋转矩阵，是30还是-30？
                float y = _WorldSpaceLightPos0.y + 0.5;
                float z = _WorldSpaceLightPos0.z - 0.866;
                return fixed4(0, y, z, 1);
            }

            ENDCG
        }
    }
}