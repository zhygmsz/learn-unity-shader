
Shader "Learn/ScreenSnowMelt"
{
    Properties
    {
        _TintColor ("Tint Color", Color) = (1, 1, 1, 1)
        _AtlasTex ("Atlas Tex", 2D) = "white" {}
        _NormalTex ("Normal", 2D) = "white" {}
        _CurLerpNextValue ("Cur Next Lerp Value", Range(0, 1)) = 0
        _BumpAmt ("Bump Amt", Range(0, 1000)) = 0
    }

    SubShader
    {
        Tags
        {
            "IgnoreProjector" = "True"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        GrabPass
        {
            Tags
            {
                "LightMode" = "Always"
            }
        }

        Pass
        {
            Tags
            {
                "LightMode" = "Always"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            Lighting Off
            SeparateSpecular Off
            ZWrite Off
            Cull Back
            Colormask RGB

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal 
            #pragma target 3.0

            uniform float4 _TintColor;
            uniform float _CurLerpNextValue;
            uniform sampler2D _NormalTex;
            uniform float4 _NormalTex_ST;
            uniform float _BumpAmt;

            uniform sampler2D _GrabTexture;
            uniform float4 _GrabTexture_TexelSize;

            // 图集方案
            uniform sampler2D _AtlasTex;
            uniform float4 _CurUVRange;
            uniform float4 _NextUVRange;

            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };
            struct VertexOutPut
            {
                float4 pos : SV_POSITION;
                float2 uvcur : TEXCOORD0;
                float2 uvnext : TEXCOORD1;
                float4 uvgrab : TEXCOORD2;
                float2 uvbump : TEXCOORD3;
                float4 vertexColor : COLOR;
            };
            VertexOutPut vert(VertexInput v)
            {
                VertexOutPut o = (VertexOutPut)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uvcur = v.texcoord0;
                o.uvnext = v.texcoord0;
                o.uvgrab = ComputeGrabScreenPos(o.pos);
                o.uvbump = TRANSFORM_TEX(v.texcoord0, _NormalTex);
                o.vertexColor = v.vertexColor;
                return o;
            }
            float4 frag(VertexOutPut i) : COLOR
            {
                float2 bump = UnpackNormal(tex2D(_NormalTex, i.uvbump)).rg;
                float2 offset = bump * _BumpAmt * _TintColor.a * _GrabTexture_TexelSize.xy * i.uvgrab.z;
                i.uvgrab.xy = i.uvgrab.xy + offset;
                i.uvgrab.xy /= i.uvgrab.w;
                float4 grabColor = tex2D(_GrabTexture, i.uvgrab.xy);

                i.uvcur.x = lerp(_CurUVRange.x, _CurUVRange.y, i.uvcur.x);
                i.uvcur.y = lerp(_CurUVRange.z, _CurUVRange.w, i.uvcur.y);
                float4 curColor = tex2D(_AtlasTex, i.uvcur);
                i.uvnext.x = lerp(_NextUVRange.x, _NextUVRange.y, i.uvnext.x);
                i.uvnext.y = lerp(_NextUVRange.z, _NextUVRange.w, i.uvnext.y);
                float4 nextColor = tex2D(_AtlasTex, i.uvnext);
                float4 finalColor = lerp(curColor, nextColor, _CurLerpNextValue);
                finalColor *= _TintColor;

                return lerp(grabColor, finalColor, finalColor.a);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
