using UnityEngine;
using System.Collections;

public class MotionBlur : PostEffectsBase {

	public Shader motionBlurShader;
	private Material motionBlurMaterial = null;

	public Material material {  
		get {
			motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
			return motionBlurMaterial;
		}  
	}

	[Range(0.0f, 0.9f)]
	public float blurAmount = 0.5f;
	
	private RenderTexture accumulationTexture;

	void OnDisable() {
		DestroyImmediate(accumulationTexture);
	}

	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			// Create the accumulation texture
			if (accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height) {
				DestroyImmediate(accumulationTexture);
				accumulationTexture = new RenderTexture(src.width, src.height, 0);
				accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
				Graphics.Blit(src, accumulationTexture);
			}

			// We are accumulating motion over frames without clear/discard
			// by design, so silence any performance warnings from Unity
			accumulationTexture.MarkRestoreExpected();

			material.SetFloat("_BlurAmount", 1.0f - blurAmount);

            //每帧，都对新图（src）做处理，主要是修改透明度并和accumulationTexture做混合。
            //并且在每帧的混合时，只混合RGB通道，A通道总是从新图（src）复制到目标图（accumulationTexture）
            //虽然是运动模糊，但本质上并没有blur相关的算法在，而是用混合累积的方式模拟的运动模糊。
            //一个像素(1, 0, 0, 1)在屏幕上移动，复盘整个模糊过程。
            //像素不动时，src和accumulationTexture内容一致，A通道保持不变，RGB通道使用SrcAlpha OneMinusSrcAlpha方式，所以混合完后还是原图。
            //当像素移动时，第二帧的时候像素位置已经发生了变化。使用混合后，屏幕上的最终效果图是两个像素的透明度都被降低了。
            //移动第三帧时，像素移动到了新的位置，上两个位置进一步降低透明度，而第三帧的像素被第一次混合。
            //一个像素在不停的移动，每一帧产生一个位置。最新的一帧对应的像素被第一次混合，透明度降低。像素经过的帧数，就是其被混合的次数。
            //混合的足够多后，目标图（accumulationTexture）里就趋近于0了，混合时显示的就是原图（src）。
            //有个不合理的地方是，最新的一张图也会被混合，降低透明度，这是不符合运动模糊实际情况的。
            //实际中的运动模糊，当前帧一定是清晰的，然后再拖尾。
            Graphics.Blit (src, accumulationTexture, material);
			Graphics.Blit (accumulationTexture, dest);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
