using UnityEngine;
using System.Collections;

public class BrightnessSaturationAndContrast : PostEffectsBase {

	public Shader briSatConShader;
	private Material briSatConMaterial;
	public Material material {  
		get {
            //该方法每帧都会执行
            //基类里，如果发现shader和material.shader是相同的，就直接返回material
            //运行时不修改material的shader的话，只有第一次需要创建material，后续都是直接返回
			briSatConMaterial = CheckShaderAndCreateMaterial(briSatConShader, briSatConMaterial);
			return briSatConMaterial;
		}  
	}

	[Range(0.0f, 3.0f)]
	public float brightness = 1.0f;

	[Range(0.0f, 3.0f)]
	public float saturation = 1.0f;

	[Range(0.0f, 3.0f)]
	public float contrast = 1.0f;

	void OnRenderImage(RenderTexture src, RenderTexture dest) {
        //该方法每帧都会执行，在渲染完全部内容后。
        //每帧都设置shader变量
		if (material != null) {
			material.SetFloat("_Brightness", brightness);
			material.SetFloat("_Saturation", saturation);
			material.SetFloat("_Contrast", contrast);

            //Blit的含义是，（内存）块传输
            //unity使用material对src处理后再拷贝到dest
            //具体操作是将src作为material的shader里的_Main_Tex，执行shader，得到新图像，拷贝到dest
            //Blit方法把dest显示到屏幕上
            Graphics.Blit(src, dest, material);

            //后处理效果可以叠加，dest不一定是屏幕。不过后处理比较耗费性能，一个是像素着色器全屏幕绘制，另一个是rendertexture内存占用很大。
            //当多个后处理效果叠加时，就需要多个rendertexture。
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
