// shader名字是整个字符串，包括斜杠。斜杠是为了在material检视面板上选取shader时可以分割多目录
// 名字里可以包含空格
Shader "Learn/ShaderBase"
{
    // 属性区域，在材质检视面板上显示
    // 该区域内的属性对外显示在材质检视面板上，方便调节。对内可以影响同名的uniform变量，或者说是同名uniform变量的对外（材质检视面板）代理
    // 该区域内的属性，如果没有一个同名uniform与其对应，则该属性毫无意义
    // uniform变量如果不需要暴露在材质检视面板上，可以不在该区域声明同名属性，只能在程序里动态设置，同时这些变量也不会被保存到材质里
    // 矩阵和数组只能通过代码动态设置，不能序列化保存，因为这两类数据不能在属性区域定义
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
        // SubShader的Tags用于控制渲染顺序和其他的SubShader参数，以下Tags只允许出现在SubShader区域内，不允许出现在Pass区域
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

            "DisableBatching" = "False"
            // 批处理多个物体时，这些物体会共用同一个MVP矩阵，所有单个物体的顶点位置在其局部空间下是不能动的，换句话说是对批处理保证物体是静态的
            // 所以当某些物体的顶点着色器内有顶点位置变换时，需要禁止合批。有三个选项
            // False：不禁止合批，这也是默认值
            // True：总是禁止合批，对于那些在顶点着色器内位置变换的物体来说，提前告诉渲染引擎禁止合批，算是一个优化项。
            // 因为这些物体即使被合批了，真实顶点位置（复制到大mesh后，大mesh里的顶点位置会随顶点着色器变换）和屏幕像素位置也对不上，尤其是在片段着色器内做额外操作的话。
            // LODFading，主要用于树

            "ForceNoShadowCasting" = "True"
            // 使用该SubShader渲染的物体将不会产生阴影，大部分情况下用于shader replacement透明物体。还有一种情况是你不想从另一个SubShader里继承shadow pass
            // 默认值为False

            "IgnoreProjector" = "True"
            // 忽略Projector（内置投影组件，投影纹理）的影响，一般半透明物体需要设置为True，默认为False

            // "CanUseSpriteAtlas" = "True/False"
            // 和Sprite有关

            "PreviewType" = "Sphere"
            // 材质的检视面板最下方的预览界面里，材质的展示方式
            // Sphere：球方式，默认
            // Plane：2D方式
            // Skybox：天空盒方式
        }
        
        // shader LOD
        LOD 100

        Pass
        {
            // Pass的Tags控制光照细节（环境光，逐顶点光照，逐像素光照等）。以下Tags只允许出现在Pass区域内，不允许出现在SubShader区域
            Tags
            {
                "LightMode" = "ForwardBase"
                // LightMode定义该Pass在光照管线里的角色，光照细节
                // Always：永远渲染，没有光照
                // ForwardBase：使用前向渲染（Forward Rendering Path），环境光，主方向光，逐顶点光照和球谐光照，以及光s照贴图
                // ForwardAdd：使用前向渲染（Forward Rendering Path），用于额外的逐像素光照计算的灯光，一个灯光一个Add Pass
                // Deferred：使用延迟渲染（Deferred Rendering Path），填充g-buffer
                // ShadowCaster：渲染深度信息到shadowmap或depth texture
                // MotionVectors：用于计算逐物体的运动向量
                // PrepassBase：用于遗留的延迟渲染
                // PrepassFinal：用于遗留的延迟渲染
                // Vertex：用于遗留的逐顶点光照
                // VertexLMRGBM：用于遗留的逐顶点光照
                // VertexLM：用于遗留的逐顶点光照。以上遗留不作详细介绍

                "PassFlags" = "OnlyDirectional"
                // PassFlags可以修改渲染管线往该Pass传递数据的方式
                // OnlyDirectional：在使用ForwardBase的Pass里，只有主方向光，环境光和lightprobe的数据传递到该Pass里
                // 意味着不重要灯光的数据不会传递给逐顶点光照或球谐光照的shader变量里，就是说一旦在ForwardBase里使用了该tags，
                // 在该Pass的shader里，是访问不到逐顶点光照或球谐光照的shader变量的

                "RequireOptions" = "SoftVegetation"
                // RequireOptions向渲染引擎指明，只有当一些外部条件满足时才渲染该Pass
                // SoftVegetation：在Quality Window界面开启Soft Vegetation选项时才渲染该Pass
            }

            // 渲染状态设置
            Cull Back
            // 裁剪
            // Back：裁剪背面的图元，默认值
            // Front：裁剪正面的图元
            // Off：不裁剪

            ZWrite On
            // 该物体的像素是否写入到深度缓冲区
            // On：写入，渲染不透明物体，默认值
            // Off：不写入，渲染半透明物体

            ZTest LEqual
            // 深度测试如何比较
            // LEqual：小于等于，默认值
            // Less：小于
            // Greater：大于
            // GEqual：大于等于
            // Equal：等于
            // Notqual：不等于
            // Always：永远通过

            //Offset Factor,Units
            // 控制深度偏移

            //Blend，回头总总结alpha blend和alpha test

            CGPROGRAM
            // CGPROGRAM/ENDCG这一对宏里包含的是HLSL代码，事实上和unity shader无关，是HLSL同时也是CG语言
            // unity提供常用的方法和宏定义
            #pragma vertex vert
            // 将vert函数作为顶点着色器
            #pragma fragment frag
            // 将frag函数作为片段着色器

            // 总结声明变体的两种方式

            //#pragma require 2darray

            // HLSLSupport.cginc 用于跨平台的宏和定义
            // UnityShaderVariables.cginc 
            // 两个文件是自动包含到每一个shader文件里
            #include "UnityCG.cginc"
            // TRANSFORM_TEX宏定义在UnityCG.cginc文件里

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform sampler3D _3DTex;
            uniform samplerCUBE _Cube;
            // 以上是三种纹理属性对应的HLSL变量类型

            uniform float _TestFloat1;
            uniform float _TestInt1;
            uniform half _TestRange1;
            // 属性区域是属于ShaderLab范畴，是unity提供的便利手段。float/half/fixed在类型上是等效的，只是根据取值范围和精度不同，适用于不同情景的数据描述

            uniform float4 _TestColor1;
            uniform half4 _TestVector1;
            // 属性里的Color和Vector都对应HLSL里的float4/half4/fixed4，必须是四分量

            uniform float _TestFloat2;
            // 普通的uniform变量，其uniform修饰符是可以省略的


            struct appdata
            {
                float4 vertex : POSITION;
                // 在vert的输入里，POSITION顶点局部空间位置，用float
                half2 uv0 : TEXCOORD0;
                half2 uv1 : TEXCOORD1;
                // TEXCOORD0-N，用half【-6000, 6000】
                half3 normal : NORMAL;
                // 法线是3分量
                half4 tangent : TANGENT;
                // 切线是4分量，注意区别
                fixed4 vertexColor : COLOR;
                // vert的输入里COLOR表示顶点颜色，用fixed【-2, 2】
            };

            struct v2f
            {
                //float4 vertex : SV_POSITION;
                // 在顶点着色器输出/片段着色器输入里，SV_POSITION等价于SV_Position，顶点的齐次裁剪空间位置，用于屏幕映射对应到某个像素，以及深度值
                half2 uv0 : TEXCOORD0;
                half2 uv1 : TEXCOORD1;
                fixed4 diffuseColor : TEXCOORD2;
                fixed4 vertexColor : TEXCOORD3;
                // unity建议，为了更好的跨平台，vert的输出/frag的输入最好使用TEXCOORDn语义，不用COLORn
                // 在vert输出/frag输入里，COLOR表示寄存器编号，没有实际语义
            };
            
            // unity的Mesh组件里的顶点数据是作为顶点着色器函数的输入，并且每个输入数据都有一个语义修饰，用来指明是位置，颜色，法线，切线，UV坐标等
            // vert的输入可以罗列在函数参数列表里，但更通用的是组织在一个结构体里，unity在UnityCG.cginc文件里提供了
            // appdata_base，position,normal,uv0
            // appdata_tan，相比base多了tangent
            // appdata_full，相比tan多了uv1-uv3（额外多出3套纹理坐标）
            v2f vert (appdata v, out float4 pos : SV_POSITION)
            {
                v2f o = (v2f)0;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                pos = UnityObjectToClipPos(v.vertex);
                // UnityObjectToClipPos方法在UnityShaderUtilities文件里，该文件总是会被包含进所有的unity shader里去
                o.uv0 = TRANSFORM_TEX(v.uv0, _MainTex);
                o.uv1 = o.uv0;
                return o;
            }

            // SV_XXX是D3D 10引入的系统值语义，用于区分D3D 9，10往后都用SV_XXX
            // SV_Target就是其中一个，就是COLOR意思，意味颜色，HLSL目前最多支持8个渲染目标，所以SV_Target0-7，0的话可以不写
            // 其实，我们常写的SV_Target都是SV_Target0的缩写版
            // SV_Depth：默认情况系片段使用光栅化阶段插值出的深度值，但某些效果需要在frag里重写深度值
            // 但这会打破GPU对深度缓冲区的优化，开销类似于alpha test（在frag里使用clip函数）。最好在所有不透明物体渲染后再渲染重写深度值的物体
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv0);
                return col;
            }
            

            // 函数的in/out方式在vert和frag之间传递参数
            /*
            // vert和frag也是普通的cg/HLSL函数，函数的参数传递可以用in/out/inout来修饰，默认的是in，in可以省略，out/inout不能省略
            // vert函数里in参数列表相当于appdata结构体展开，out参数列表相当于v2f结构体展开
            float4 vert(float4 vertex : POSITION, float2 vertUV : TEXCOORD0, out float2 fragUV : TEXCOORD0) : SV_POSITION
            {
                fragUV = TRANSFORM_TEX(vertUV, _MainTex);
                return UnityObjectToClipPos(vertex);
            }

            // vert函数里out修饰的参数和frag函数里in修饰的参数是对应的，类型和语义相同（本质是寄存器编号）的才传递
            fixed4 frag(float2 uv : TEXCOORD0) : SV_Target
            {
                //return fixed4(1, 1, 0, 1);
                fixed4 col = tex2D(_MainTex, uv);
                return col;
            }
            */
            ENDCG
        }
    }

    // fallback英文单词意思是应变计划，备用，退守。但网络上很多都说成回滚，这是错误的
    // FallBack是和unity选择SubShader的策略搭配的，如果所有的SubShader都不符合要求，则选择FallBack内的Shader
    FallBack "Diffuse"
}
