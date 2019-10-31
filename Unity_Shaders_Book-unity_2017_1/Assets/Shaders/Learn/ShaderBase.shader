// shader名字是整个字符串，包括斜杠。斜杠是为了在material检视面板上选取shader时可以分割多目录
// 名字里可以包含空格
Shader "Learn/ShaderBase"
{
    // 属性区域，在材质检视面板上显示
    // 该区域内的属性对外显示在材质检视面板上，方便调节。对内可以影响同名的uniform变量，或者说是同名uniform变量的对外（材质检视面板）代理
    // 该区域内的属性，如果没有一个同名uniform与其对应，则该属性毫无意义
    // uniform变量如果不需要暴露在材质检视面板上，可以不在该区域声明同名属性，只能在程序里动态设置
    // 属性区域是shader的一部分，任何修改都会保存在材质里
    // 一个Shader只有一个Properties区域
    Properties
    {
        // _Name ("Display Name", Type) = DefaultValue
        // _Name                属性名
        // Display Name         在材质检视面板上显示
        // Type                 变量类型
        // Default Value        默认值

        _MainTex ("Texture", 2D) = "white" {}
        // 2D ： 默认值为空字符串或内置默认纹理字符串（white(1, 1, 1, 1), black(0, 0, 0, 0), gray(0.5, 0.5, 0.5, 0.5), bump(0.5, 0.5, 1, 0.5), red(1, 0, 0, 0)）
        // 填空字符串时按照gray处理，或者说空字符串等价于gray


        _TestFloat1 ("Test Float 1", Float) = 0
    }

    // 子shader，主要用于不同GPU性能等级
    // unity会自动选择第一个当前GPU可用的SubShader，如果找不到则使用FallBack，在FallBack里如果还是找不到则继续递归FallBack
    // 一个Shader里可以包含一个或多个SubShader，至少需要一个
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };


            sampler2D _MainTex;
            float4 _MainTex_ST;

            uniform float _TestFloat2;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
