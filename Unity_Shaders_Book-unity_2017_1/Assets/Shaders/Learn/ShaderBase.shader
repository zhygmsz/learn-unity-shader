// shader名字是整个字符串，包括斜杠。斜杠是为了在material检视面板上选取shader时可以分割多目录
// 名字里可以包含空格
Shader "Learn/ShaderBase"
{
    // 属性区域，在材质检视面板上显示
    // 该区域内的属性对外显示在材质检视面板上，方便调节。对内可以影响同名的uniform变量，或者说是同名uniform变量的对外（材质检视面板）代理
    // 该区域内的属性，如果没有一个同名uniform与其对应，则该属性毫无意义
    // uniform变量如果不需要暴露在材质检视面板上，可以不在该区域声明同名属性，只能在程序里动态设置，同时这些变量也不会被保存到材质里
    // 属性区域是shader的一部分，任何修改都会保存(序列化)在材质里
    // 一个Shader只有一个Properties区域
    Properties
    {
        // 【属性字段】
        // _Name ("Display Name", Type) = DefaultValue
        // _Name                属性名
        // Display Name         在材质检视面板上显示
        // Type                 变量类型
        // Default Value        默认值

        _MainTex ("Texture", 2D) = "white" {}
        // 2D ： 默认值为空字符串或内置默认纹理字符串（white(1, 1, 1, 1), black(0, 0, 0, 0), gray(0.5, 0.5, 0.5, 0.5), bump(0.5, 0.5, 1, 0.5), red(1, 0, 0, 0)）
        // 填空字符串时按照gray处理，或者说空字符串等价于gray
        // 最后的大括号是用于旧版本(5以前)的固定管线的纹理属性填充，在unity5里被移除。

        _3DTex ("3D Tex", 3D) = "" {}
        _Cube ("Cube", Cube) = "" {}
        _2DArray ("2D Array", 2DArray) = "" {}
        // 以上非2D纹理的默认值统统是空字符串，如果材质里没有对应资源赋值，则使用gray替代

        [Space(50)]

        // 注意
        // 以上纹理类型后面都要跟大括号，如果不跟则和Range类型属性冲突，索性所有的纹理类型属性后面都要跟大括号

        _TestFloat1 ("Test Float 1", Float) = 0
        _TestInt1 ("Test Int 1", Int) = 1
        _TestRange1 ("Test Range 1", Range(1, 5)) = 2.5
        // shader里的float类型数字不后缀f，添加了报错

        _TestColor1 ("Test Color 1", Color) = (1, 1, 0, 1)
        _TestVector1 ("Test Vector 1", Vector) = (1, 1, 1, 1)
        // 以上两个都是浮点型

        [Space(50)]

        // 【属性字段的描述符】
        [NoScaleOffset]
        // 如果一个纹理确实没有Scale和Offset需求，可以使用该属性
        _Normal ("Normal", 2D) = "bump" {}

        [HideInInspector]
        // 该属性在材质检视面板不可见
        _TestInt2 ("Test Int 2", Int) = 1
    }

    // 子shader，主要用于不同GPU性能等级
    // unity会自动选择第一个当前GPU可用的SubShader，如果找不到则使用FallBack，在FallBack里如果还是找不到则继续递归FallBack
    // 一个Shader里可以包含一个或多个SubShader，至少需要一个
    // 一个Shader内的多个SubShader，会同时加载到内存。把SubShader独立成多个Shader，并单独打包，进游戏后再更新适用于机器性能的Shader
    SubShader
    {
        // 【SubShader Tags】
        // SubShader的Tags指明渲染引擎如何并何时渲染，只允许出现在SubShader区域内，不允许出现在Pass区域
        Tags
        {
            "RenderType"="Opaque"
            // RenderType把所有的shader划分到预定义的几个组内，便于Shader Replacement
            // 选项如下：
            // Opaque：大部分的shader（法线，自发光，反射，地形等）
            // Transparent：大部分半透明shader（UI，粒子，地形的半透明pass）
            // TransparentCutout：透明度裁剪（溶解效果）
            // Background：天空盒shader
            // Overlay：Halo（光晕），Flare（耀斑）
            // TreeOpaque：地形引擎的树皮绉
            // TreeTransparentCutout：地形引擎的树叶
            // TreeBillboard：地形引擎的billboard树
            // Grass：地形引擎的草
            // GrassBillboard：地形引擎的billboard草

            "Queue" = "Geometry"
            // Queue控制渲染顺序，指定物体属于哪个渲染队列，所有的透明物体必须保证在所有不透明物体之后
            // Background：1000，最早渲染，适用天空盒
            // Geometry：2000，默认，适用大多数不透明物体
            // AlphaTest：2450，从Geometry分出来的，在所有不透明物体之后渲染AlphaTest可以更高效
            // Transparent：3000，在Geometry和AlphaTest之后渲染，必须保证从后往前的顺序，任何需要alpha-blend（do not write depth buffer）的物体都放到这个队列
            // Overlay：4000， 最后渲染的都放在这个队列，如lens flare（镜头光晕）
            // "Queue" = "Geometry+1"
            // 上述渲染顺序是2001，在所有Geometry物体之后。可以很灵活的控制一个物体渲染顺序在某两个之间，如半透明的水应该在Geometry物体之后，并且在Transparent之后
            // Queue最多到2500都被认为是Opaque物体，优化渲染顺序提升性能。超过2500的Queue被当做Transparent物体并且根据距离排序，由远及近的渲染。
            // 天空盒就在所有Opaque物体和所有Transparent物体之间渲染

            
        }


        LOD 100

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //#pragma require 2darray

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            uniform float _TestFloat2;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }

    // fallback英文单词意思是应变计划，备用，退守。但网络上很多都说成回滚，这是错误的
    // FallBack是和unity选择SubShader的策略搭配的，如果所有的SubShader都不符合要求，则选择FallBack内的Shader
    FallBack "Diffuse"
}
