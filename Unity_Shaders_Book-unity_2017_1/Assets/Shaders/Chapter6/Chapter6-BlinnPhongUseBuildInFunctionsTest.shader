Shader "Unity Shaders Book/Chapter 6/Blinn-Phong Use Built-In Functions Test"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(1, 500)) = 20
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
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);
                fixed3 worldNormal = normalize(i.worldNormal);
                //虽然在顶点着色器中已经把顶点法线转换到了世界空间并单位化
                //但在光栅化的过程中，某个片元的顶点法线可能不再单位化
                //所以需要在片元着色器里，对顶点法线继续单位化
                fixed diffuseFactor = saturate(dot(worldNormal, worldLightDir));
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * diffuseFactor;

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                float specularFactor = pow(saturate(dot(worldNormal, halfDir)), _Gloss);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * specularFactor;

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}