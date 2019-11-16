using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEngine;

public class SnowMelt : MonoBehaviour
{
    private Renderer mRenderer = null;
    private Material mMat = null;

    // 非NGUI图集方案
    public Texture mAtlasTex;
    // 法线只需要一张即可，选取中间帧
    public Texture mNormalTex;
    public int mRowNum;
    public int mColNum;

    private List<Vector4> mSpriteUVList = null;
    private int mSpriteNum;

    private int mCurTexIdx = -1;
    private int mNextTexIdx = -1;

    // 两张图片之间可插值帧数
    [Tooltip("两片雪花之间可插值帧数")]
    [Range(10, 20)]
    public int mLerpMaxFrame = 15;
    private int mCurLerpCount = -1;
    private float mLerpStepValue = 1f;

    // 雪花类型，来自mgr的赋值，用于mgr分类回收
    private int mSnowType = -1;
    private SnowMeltMgr.OnSnowMeltEndCallback mOnSnowMeltEndCallback;

    // 测试用字段
    // 缓存位置，在Show时不立即更新位置，在Update里更新两帧后再更新位置，尝试解决闪过问题
    private Vector3 mCachedLocalPos;
    // 在Show方法里先挪到远方，待Updata里更新
    private Vector3 mFarLocalPos = new Vector3(-10000f, 0f, 0f);

    private void Start()
    {
        Init();
        Reset();
    }

    public void Init()
    {
        mRenderer = transform.GetComponent<Renderer>();
        if (mRenderer == null)
        {
            string str = string.Format("SnowMelt miss Renderer, transform.name = {0}", transform.name);
            Debug.LogError(str);
            return;
        }

        mMat = mRenderer.material;
        if (mMat == null)
        {
            string str = string.Format("mRenderer.material is null, transform.name = {0}", transform.name);
            Debug.LogError(str);
            return;
        }

        if (mAtlasTex && mNormalTex)
        {
            mMat.SetTexture("_AtlasTex", mAtlasTex);
            mMat.SetTexture("_NormalTex", mNormalTex);
        }
        else
        {
            Debug.LogError("mAtlas or mNormalTex is null");
            return;
        }

        CalSpriteUVList();

        CalLerpStepValue();
    }

    public void SetSnowType(int snowType, SnowMeltMgr.OnSnowMeltEndCallback onSnowMeltEndCallback)
    {
        mSnowType = snowType;
        mOnSnowMeltEndCallback = onSnowMeltEndCallback;
    }

    public int GetSnowType()
    {
        return mSnowType;
    }

    private void NotifySnowMeltEnd()
    {
        if (mOnSnowMeltEndCallback != null)
        {
            mOnSnowMeltEndCallback(this);
        }
    }

    private void CalSpriteUVList()
    {
        mSpriteNum = mRowNum * mColNum;
        if (mSpriteNum == 0)
        {
            string str = string.Format("mSpriteNum is 0, transform.name = {0}", transform.name);
            Debug.LogError(str);
            return;
        }

        mSpriteUVList = new List<Vector4>(mSpriteNum);

        // sprite name强制xuehua_x格式（x从0开始自增），不是的则报错
        int texW = mAtlasTex.width;
        int texH = mAtlasTex.height;
        int spriteW = texW / mColNum;
        int spriteH = texH / mRowNum;
        Rect rect = new Rect();
        for (int row = 0; row < mRowNum; ++row)
        {
            rect.yMin = spriteH * row;
            rect.yMax = spriteH * (row + 1);
            for (int col = 0; col < mColNum; ++col)
            {
                rect.xMin = spriteW * col;
                rect.xMax = spriteW * (col + 1);
                Rect uv = NGUIMath.ConvertToTexCoords(rect, texW, texH);
                mSpriteUVList.Add(new Vector4(uv.xMin, uv.xMax, uv.yMin, uv.yMax));
            }
        }
    }

    private void CalLerpStepValue()
    {
        mLerpStepValue = 1f / (mLerpMaxFrame - 1);
    }

    // inspector面板属性变动回调
    private void OnValidate()
    {
        CalLerpStepValue();
        Reset();
    }

    private void Reset()
    {
        mCurLerpCount = -1;
    }

    // 开始一次融化过程
    public void Show(Vector3 localPos)
    {
        Reset();
        transform.localPosition = mFarLocalPos;
        gameObject.SetActive(true);

        mCachedLocalPos = localPos;
    }

    // 隐藏go，重置逻辑，供下次显示
    public void Hide()
    {
        gameObject.SetActive(false);
        Reset();
    }

    private void Update()
    {
        ++mCurLerpCount;
        if (mCurLerpCount == 2)
        {
            transform.localPosition = mCachedLocalPos;
        }
        int curTexIdx = mCurLerpCount / mLerpMaxFrame;
        float lerpValue = (mCurLerpCount % mLerpMaxFrame) * mLerpStepValue;
        if (curTexIdx != mCurTexIdx)
        {
            mCurTexIdx = curTexIdx;
            mNextTexIdx = mCurTexIdx + 1;
            if (mMat != null)
            {
                mMat.SetVector("_CurUVRange", mSpriteUVList[mCurTexIdx]);
                mMat.SetVector("_NextUVRange", mSpriteUVList[mNextTexIdx]);
                mMat.SetFloat("_CurLerpNextValue", lerpValue);
            }
        }
        else
        {
            if (mMat != null)
            {
                mMat.SetFloat("_CurLerpNextValue", lerpValue);
            }

            if (mCurTexIdx == mSpriteNum - 2)
            {
                if (Mathf.Abs(lerpValue - 1f) <= float.Epsilon)
                {
                    // 最后一张图的最后一插值，通知结束
                    NotifySnowMeltEnd();
                    //Hide();
                    //Reset();
                }
            }
        }
    }

    private void OnDestroy()
    {
        if (mMat != null)
        {
            GameObject.Destroy(mMat);
        }
    }
}
