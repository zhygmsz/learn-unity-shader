
Shader "Learn/ScreenSnowMeltBatched"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "IgnoreProjector" = "True"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            //Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float3 normal : TEXCOORD4;
                float4 tangent : TEXCOORD5;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv0 = TRANSFORM_TEX(v.uv0, _MainTex);

                o.uv1 = v.uv1;
                o.uv2 = v.uv2;
                o.uv3 = v.uv3;
                o.normal = v.normal;
                o.tangent = v.tangent;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 curUV = float2(lerp(i.uv1.x, i.uv1.y, i.uv0.x), lerp(i.uv2.x, i.uv2.y, i.uv0.y));
                float4 curColor = tex2D(_MainTex, curUV);
                float2 nextUV = float2(lerp(i.tangent.x, i.tangent.y, i.uv0.x), lerp(i.tangent.z, i.tangent.w, i.uv0.y));
                float4 nextColor = tex2D(_MainTex, nextUV);
                float4 finalColor = lerp(curColor, nextColor, i.uv3.x);
                return finalColor;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
