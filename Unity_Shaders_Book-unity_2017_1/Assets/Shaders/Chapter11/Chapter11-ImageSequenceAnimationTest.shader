Shader "Unity Shaders Book/Chapter 11/Image Sequence Animation Test"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Image Sequence", 2D) = "white" {}
        _HorizontalAmount ("Horizontal Amount", Float) = 8
        _VerticalAmount ("Vertical Amount", Float) = 8
        _Speed ("Speed", Range(1, 100)) = 30
    }

    SubShader
    {
        Tags {  "Queue" = "Transparent"
                "IgnoreProjector" = "True"
                "RenderType" = "Transparent"
            }
        
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //quad是一个由两个三角形组成的平面，一共就四个顶点
                //他们的纹理坐标也很简单，左上(0, 0), 右上(1, 0), 左下(0, 1), 右下(1, 1)
                //光栅化后，这个四边形在屏幕上的像素区域内，每个像素都会得到一个插值后的纹理坐标，介于[0, 1]之间
                //以上部分，如果四边形位置和相机位置都不改变，则像素区域的每个纹理坐标都是固定的
                //在片元着色器里，每个像素拿着自己的纹理坐标去采样一张纹理，并得到一个颜色，最后显示在屏幕像素位置

                //该shader的动画效果就是让每个像素的固定纹理坐标值去采样一张大图里的不同区域里的小图
                //根据帧率外加一个速度系数来不停的变换待采样的小图，以此实现了动画效果

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //_Time.y是自场景加载后经过的时间（秒）
                //假设帧率是100，那么每帧的时间为1/100秒
                //如果_Speed是1，那time的增速就是1/100秒，100帧才能更新一张图片，1秒钟更新1张
                //如果_Speed是50，那time的增速为50/100秒，2帧更新一张图片，1秒钟更新50张
                float time = floor(_Time.y * _Speed);
                float row = floor(time / _HorizontalAmount);
                float column = time - row * _HorizontalAmount;

                //本来uv.xy都是[0, 1]的值，现在要用uv值去采样由8*8张图组合成的一张大图里的某一张图
                //那么相当于uv值被缩小成为原来的1/8了，换句话说，纹理扩大到原来的8倍了
                //现在的uv只能采样1/8份纹理，而row和column是整数倍的1/8份
                //uv.xy和column、row加起来就是纹理被放大后的真实uv值
                //但tex2D方法本身只认[0, 1]的值，所以还需要把放大后的uv值除以8，归一化到[0, 1]，再去采样
                half2 uv = i.uv + float2(column, -row);
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;

                fixed4 c = tex2D(_MainTex, uv);
                c.rgb *= _Color;

                return c;
            }

            ENDCG
        }
    }

    FallBack "Transparent/VertexLit"
}