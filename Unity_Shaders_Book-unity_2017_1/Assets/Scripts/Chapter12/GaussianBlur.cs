using UnityEngine;
using System.Collections;

public class GaussianBlur : PostEffectsBase {

	public Shader gaussianBlurShader;
	private Material gaussianBlurMaterial = null;

	public Material material {  
		get {
			gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
			return gaussianBlurMaterial;
		}  
	}

    // Blur iterations - larger number means more blur.
    //默认值为0，表示没有模糊。
    //当blurSpread和downSample都为默认值时，该值越大，得到的模糊效果越好，但达到一定程度后，画面就失去了模糊的意义，变得完全看不清。
    [Range(0, 4)]
	public int iterations = 3;
	
	// Blur spread for each iteration - larger value means more blur
    //默认值为1，表示原始的高斯模糊算子覆盖的纹素
    //值偏大时，画面上会有条纹，是因为模糊算子覆盖的纹素间距太大，纹素的差异性增大，相当于给模糊后的结果掺了杂质。
	[Range(0.2f, 3.0f)]
	public float blurSpread = 0.6f;

    //默认值为1，表示不降采样。
    //当iterations和blurSpread都为默认值时，该值增大，也会得到模糊效果。但这种模糊的本质是图片小尺寸被拉伸到大尺寸后的效果，有锯齿。
    //值在增大过程中会损害模糊效果，2或3，尽量为2.
    [Range(1, 8)]
	public int downSample = 2;
	
	/// 1st edition: just apply blur
//	void OnRenderImage(RenderTexture src, RenderTexture dest) {
//		if (material != null) {
//			int rtW = src.width;
//			int rtH = src.height;
//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
//
//			// Render the vertical pass
//			Graphics.Blit(src, buffer, material, 0);
//			// Render the horizontal pass
//			Graphics.Blit(buffer, dest, material, 1);
//
//			RenderTexture.ReleaseTemporary(buffer);
//		} else {
//			Graphics.Blit(src, dest);
//		}
//	} 

	/// 2nd edition: scale the render texture
//	void OnRenderImage (RenderTexture src, RenderTexture dest) {
//		if (material != null) {
//			int rtW = src.width/downSample;
//			int rtH = src.height/downSample;
//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
//			buffer.filterMode = FilterMode.Bilinear;
//
//			// Render the vertical pass
//			Graphics.Blit(src, buffer, material, 0);
//			// Render the horizontal pass
//			Graphics.Blit(buffer, dest, material, 1);
//
//			RenderTexture.ReleaseTemporary(buffer);
//		} else {
//			Graphics.Blit(src, dest);
//		}
//	}

	/// 3rd edition: use iterations for larger blur
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			int rtW = src.width/downSample;
			int rtH = src.height/downSample;

			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			buffer0.filterMode = FilterMode.Bilinear;

			Graphics.Blit(src, buffer0);

			for (int i = 0; i < iterations; i++) {
                //模糊多次的时候，迭代传播范围。_BlurSize在shader里的含义是模糊算子内某个格子的uv坐标偏移。
                //随着多次模糊，对于当前纹素来说的模糊算子覆盖的纹素也在向外传递。效果上更均匀，细致。
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				// Render the vertical pass
				Graphics.Blit(buffer0, buffer1, material, 0);

				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				// Render the horizontal pass
				Graphics.Blit(buffer0, buffer1, material, 1);

				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}

			Graphics.Blit(buffer0, dest);
			RenderTexture.ReleaseTemporary(buffer0);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
