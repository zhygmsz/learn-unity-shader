Shader "Unity Shaders Book/Chapter 10/Reflection Test"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _ReflectColor ("Reflection Color", Color) = (1, 1, 1, 1)
        _ReflectAmount ("Reflect Amount", Range(0, 1)) = 1
        _Cubemap ("Reflection Curmap", Cube) = "_Skybox" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed4 _ReflectColor;
            fixed _ReflectAmount;
            samplerCUBE _Cubemap;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldViewDir : TEXCOORD2;
                fixed3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldViewDir = normalize(i.worldViewDir);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(worldLightDir, worldNormal));

                //最初以为是光线在该点出的反射光线方向来采样立方体纹理，所以认为这个计算过程是错的
                //后来理解了，我们在物体表面看到的已经是反射过的颜色了，就是物体表面反射的空间环境
                //周围空间的某个点发出的光线，射到当前顶点上，反射到我们的观察者这里，于是乎看到了物体表面的颜色。
                //由于反射定律，可以倒着推过去，由观察方向反推到入射光线，然后再采样立方体纹理，得到空间颜色。
                fixed3 worldRefl = reflect(-worldViewDir, worldNormal);
                fixed3 reflection = texCUBE(_Cubemap, worldRefl).rgb * _ReflectColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                //混合漫反射颜色和反射颜色，_ReflectAmount越小最终颜色越接近diffuse，_ReflectAmount越大最终颜色越接近reflection
                fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount) * atten;

                return fixed4(color, 1);
            }

            ENDCG
        }
    }

    FallBack "Reflective/VertexLit"
}