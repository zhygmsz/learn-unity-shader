using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SnowMeltMgr : MonoBehaviour
{
    public delegate void OnSnowMeltEndCallback(SnowMelt snowMelt);
    private OnSnowMeltEndCallback mOnSnowMeltEndCallback;

    public List<GameObject> mSnowGoList = null;
    // 雪花样式数量，取决于mSnowGoList数量
    private int mSnowTypeCount = 0;
    // 每种样式雪花预先生成实例数量
    private int mPreGenSnowMeltNum = 3;
    private Dictionary<int, List<SnowMelt>> mSnowMeltHideDic = null;
    private Dictionary<int, List<SnowMelt>> mSnowMeltShowingDic = null;

    // 随机出现时间间隔
    public float mMinDuration = 1f;
    public float mMaxDuration = 3f;
    private float mCurDuration = 1f;
    private float mCurCounter = 0f;

    // 可出现雪花区域，NGUI坐标范围
    private Vector2 mScreenSize;
    // 内安全区域四边界，NGUI坐标值
    private Vector4 mSafeAreaMin;
    // 外安全区域四边界，NGUI坐标值
    private Vector4 mSafeAreaMax;
    private List<Vector4> mAreaList = null;

    // 雪花在不同设备分辨率下的相对观感大小要大致相同，该值为相对于UIRoot设计分辨率的缩放系数
    // 实例化出来的雪花Go局部缩放系数都要应用该值
    private float mSnowLocalScaleFactor = 1f;

    private void Awake()
    {
        UIRoot uiRoot = GameObject.Find("UI Root").GetComponent<UIRoot>();
        if (uiRoot == null)
        {
            Debug.LogError("uiRoot is null");
            return;
        }

        int screenW = Screen.width;
        int screenH = Screen.height;
        float logicW = uiRoot.manualWidth;
        float logicH = uiRoot.manualHeight;
        float ratio = (float)screenW / (float)screenH;
        if (uiRoot.fitHeight)
        {
            logicW = logicH * ratio;
            mSnowLocalScaleFactor = (float)screenH / logicH;
        }
        else
        {
            logicH = logicW / ratio;
            mSnowLocalScaleFactor = (float)screenW / logicW;
        }
        mScreenSize = new Vector2(logicW, logicH);

        // 可以在inspector上配置
        Vector4 minUV = new Vector4(-0.5f, 0.5f, -0.5f, 0.5f);
        Vector4 maxUV = new Vector4(-0.85f, 0.85f, -0.85f, 0.85f);
        InitSafeArea(minUV, maxUV);

        mOnSnowMeltEndCallback = OnSnowMeltEnd;

        Init();
    }

    private void OnEnable()
    {
        Show();
    }

    private void OnDisable()
    {
        Hide();
    }

    private void Update()
    {
        mCurCounter += Time.deltaTime;
        if (mCurCounter >= mCurDuration)
        {
            RandomGenSnow(Mathf.RoundToInt(mCurDuration));
            mCurCounter = 0f;
            RandomOneDuration();
        }
    }

    // 回收雪花
    private void OnSnowMeltEnd(SnowMelt snowMelt)
    {
        if (snowMelt != null)
        {
            snowMelt.Hide();

            AddSnowMelt(mSnowMeltHideDic, snowMelt);
            RemoveSnowMelt(mSnowMeltShowingDic, snowMelt);
        }
    }

    private void AddSnowMelt(Dictionary<int, List<SnowMelt>> dic, SnowMelt snowMelt)
    {
        if (snowMelt == null)
        {
            return;
        }
        int snowType = snowMelt.GetSnowType();
        if (dic.ContainsKey(snowType))
        {
            List<SnowMelt> list = dic[snowType];
            if (list != null && list.Contains(snowMelt) == false)
            {
                list.Add(snowMelt);
            }
        }
    }

    private void RemoveSnowMelt(Dictionary<int, List<SnowMelt>> dic, SnowMelt snowMelt)
    {
        if (snowMelt == null)
        {
            return;
        }
        int snowType = snowMelt.GetSnowType();
        if (dic.ContainsKey(snowType))
        {
            List<SnowMelt> list = dic[snowType];
            if (list != null && list.Contains(snowMelt))
            {
                list.Remove(snowMelt);
            }
        }
    }

    // 准备雪花池
    public void Init()
    {
        if (mSnowGoList == null || mSnowGoList.Count == 0)
        {
            Debug.LogError("mSnowGoList is null or Count is 0");
            return;
        }

        mSnowTypeCount = mSnowGoList.Count;

        // int作为key，开辟相同数量，不会引发字典扩容
        mSnowMeltHideDic = new Dictionary<int, List<SnowMelt>>(mSnowGoList.Count);
        mSnowMeltShowingDic = new Dictionary<int, List<SnowMelt>>(mSnowGoList.Count);
        for (int snowGoIdx = 0, max = mSnowGoList.Count; snowGoIdx < max; ++snowGoIdx)
        {
            // 开辟5个容量，List几乎不用扩容
            List<SnowMelt> list = new List<SnowMelt>(5);
            List<SnowMelt> showingList = new List<SnowMelt>(5);

            for (int snowMeltIdx = 0; snowMeltIdx < mPreGenSnowMeltNum; ++snowMeltIdx)
            {
                SnowMelt snowMelt = CreateSnowMelt(snowGoIdx);
                list.Add(snowMelt);
            }

            mSnowMeltHideDic.Add(snowGoIdx, list);
            mSnowMeltShowingDic.Add(snowGoIdx, showingList);
        }
    }

    // 创建一个雪花
    private SnowMelt CreateSnowMelt(int snowType)
    {
        SnowMelt newSnowMelt = null;

        if (0 <= snowType && snowType < mSnowTypeCount)
        {
            GameObject snowGo = mSnowGoList[snowType];
            Vector3 preLocalScale = snowGo.transform.localScale;
            GameObject newGo = GameObject.Instantiate(snowGo);
            newGo.transform.parent = transform;
            newGo.transform.localRotation = Quaternion.identity;
            newGo.transform.localScale = preLocalScale * mSnowLocalScaleFactor;
            newSnowMelt = newGo.GetComponent<SnowMelt>();
            newSnowMelt.Init();
            newSnowMelt.SetSnowType(snowType, mOnSnowMeltEndCallback);
            newSnowMelt.Hide();
        }

        return newSnowMelt;
    }

    // 获取一个雪花，先从池里取，没有再创建
    private SnowMelt GenSnowMelt(int snowType)
    {
        SnowMelt snowMelt = null;

        if (mSnowMeltHideDic.ContainsKey(snowType))
        {
            List<SnowMelt> list = mSnowMeltHideDic[snowType];
            if (list != null && list.Count > 0)
            {
                snowMelt = list[0];
                list.RemoveAt(0);
            }
            else
            {
                snowMelt = CreateSnowMelt(snowType);
            }
        }

        return snowMelt;
    }

    // 开始融化
    public void Show()
    {
        RandomOneDuration();
    }

    // 结束融化，回收雪花并隐藏自身，可重新开始
    public void Hide()
    {
        var et = mSnowMeltShowingDic.GetEnumerator();
        while (et.MoveNext())
        {
            List<SnowMelt> list = et.Current.Value;
            if (list == null)
            {
                continue;
            }
            for (int i = 0, max = list.Count; i < max; ++i)
            {
                SnowMelt snowMelt = list[0];
                list.RemoveAt(0);

                snowMelt.Hide();
                AddSnowMelt(mSnowMeltHideDic, snowMelt);
            }
        }
    }

    private void RandomOneDuration()
    {
        mCurDuration = Random.Range(mMinDuration, mMaxDuration);
    }

    // 在屏幕上随机位置创建雪花，count:数量
    private void RandomGenSnow(int count)
    {
        // 强制改成1个
        count = 1;
        for (int i = 0; i < count; ++i)
        {
            // 随机雪花样式
            int snowType = Random.Range(0, mSnowTypeCount);
            SnowMelt snowMelt = GenSnowMelt(snowType);
            if (snowMelt != null)
            {
                // 随机区域和位置
                int listIdx = Random.Range(0, mAreaList.Count);
                Vector4 v4 = mAreaList[listIdx];
                float rX = Random.Range(v4.x, v4.y);
                float rY = Random.Range(v4.z, v4.w);
                Vector3 localPos = new Vector3(rX, rY, 0);

                AddSnowMelt(mSnowMeltShowingDic, snowMelt);

                snowMelt.Show(localPos);
            }
        }
    }

    private void InitSafeArea(Vector4 minUV, Vector4 maxUV)
    {
        Vector4 temp = new Vector4(mScreenSize.x, mScreenSize.x, mScreenSize.y, mScreenSize.y);
        temp *= 0.5f;
        mSafeAreaMin = Vector4.Scale(minUV, temp);
        mSafeAreaMax = Vector4.Scale(maxUV, temp);

        mAreaList = new List<Vector4>(8);

        // 1 2 3
        // 4   5
        // 6 7 8
        Vector4 a1 = new Vector4(mSafeAreaMax.x, mSafeAreaMin.x, mSafeAreaMin.w, mSafeAreaMax.w);
        mAreaList.Add(a1);
        Vector4 a2 = new Vector4(mSafeAreaMin.x, mSafeAreaMin.y, mSafeAreaMin.w, mSafeAreaMax.w);
        mAreaList.Add(a2);
        Vector4 a3 = new Vector4(mSafeAreaMin.y, mSafeAreaMax.y, mSafeAreaMin.w, mSafeAreaMax.w);
        mAreaList.Add(a3);

        Vector4 a4 = new Vector4(mSafeAreaMax.x, mSafeAreaMin.x, mSafeAreaMin.z, mSafeAreaMin.w);
        mAreaList.Add(a4);
        Vector4 a5 = new Vector4(mSafeAreaMin.y, mSafeAreaMax.y, mSafeAreaMin.z, mSafeAreaMin.w);
        mAreaList.Add(a5);

        Vector4 a6 = new Vector4(mSafeAreaMax.x, mSafeAreaMin.x, mSafeAreaMax.z, mSafeAreaMin.z);
        mAreaList.Add(a6);
        Vector4 a7 = new Vector4(mSafeAreaMin.x, mSafeAreaMin.y, mSafeAreaMax.z, mSafeAreaMin.z);
        mAreaList.Add(a7);
        Vector4 a8 = new Vector4(mSafeAreaMin.y, mSafeAreaMax.y, mSafeAreaMax.z, mSafeAreaMin.z);
        mAreaList.Add(a8);
    }
}
