Shader "Unity Shaders Book/Chapter 6/Diffuse Vertex Test"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 color : COLOR;
            };

            //世界空间下，法线(normal)与光照向量(lightdir)的数量积
            //法线从Render组件传递到顶点着色器，转换到世界空间下
            //光照向量（顶点到光源的方向），区分不同类型的光源，目前只考虑了方向光，点光源和聚光灯怎么计算？
            //这些计算细则都被unity包装在了UnityWorldSpaceLightDir方法里

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //给环境光也应用上材质的漫反射系数，会使效果更暗，这么做有什么应用场景吗？

                fixed3 worldNormal = normalize(mul(v.vertex, (float3x3)unity_WorldToObject));
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));
                //_Diffuse.rgb与其叫做材质的漫反射颜色，倒不如叫做漫反射系数更好，高光同理

                o.color = ambient + diffuse;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }
            
            ENDCG
        }
    }
}