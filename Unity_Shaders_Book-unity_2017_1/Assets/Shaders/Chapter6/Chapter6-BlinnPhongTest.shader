Shader "Unity Shaders Book/Chapter 6/Blinn-Phong Test"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8, 256)) = 20
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

            //半角向量 = 平分光照向量和观察向量夹角的向量
            //使用半角向量和法线来模拟高光，本身没有物理学意义，但某些情况下效果会更好

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
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                float diffuseFactor = saturate(dot(worldNormal, worldLightDir));
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * diffuseFactor;

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                float specularFactor = pow(saturate(dot(worldNormal, halfDir)), _Gloss);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * specularFactor;

                fixed3 color = ambient + diffuse + specular;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}