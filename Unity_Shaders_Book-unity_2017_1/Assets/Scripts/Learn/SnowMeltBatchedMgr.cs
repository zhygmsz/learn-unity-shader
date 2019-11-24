using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SnowMeltBatchedMgr : MonoBehaviour
{
    // mesh
    private MeshFilter mMeshFilter;
    private Mesh mMesh;

    // 图集纹理
    public Texture2D mAtlasTex;
    public int mRowNum;
    public int mColNum;
    // 每两帧之间插值次数
    public int mLerpTimes = 15;
    // 总插值次数
    private int mTotalLerpTimes;
    // 插值步进值
    private float mStepValue;
    private int mSnowWidth;
    private int mSnowHeight;
    private List<Vector4> mSpriteUVList = null;
    private int mSpriteNum;

    // 网格数据
    // 数量过多则内存大，过少则频繁数据腾挪，考虑在50-200之间，看平均每秒钟随机出几个雪花
    private const int MAXSNOWNUM = 100;
    // 当前可用的雪花索引，如果找不到则需要数据腾挪，把有效的雪花靠前，无效的雪花靠后
    private int mNextSnowIdx = 0;
    private Vector3[] mVertices = new Vector3[4 * MAXSNOWNUM];
    private int[] mTriangles = new int[6 * MAXSNOWNUM];
    private Vector2[] mUV0 = new Vector2[4 * MAXSNOWNUM];
    private Vector2[] mUV1 = new Vector2[4 * MAXSNOWNUM];
    private Vector2[] mUV2 = new Vector2[4 * MAXSNOWNUM];
    private Vector2[] mUV3 = new Vector2[4 * MAXSNOWNUM];
    private Vector4[] mTangents = new Vector4[4 * MAXSNOWNUM];
    private Vector3[] mNormals = new Vector3[4 * MAXSNOWNUM];

    // 随机出现时间间隔
    public float mMinDuration = 1f;
    public float mMaxDuration = 3f;
    private float mCurDuration = 1f;
    private float mCurCounter = 0f;

    // 随机区域
    // 有效的NGUI坐标范围内，雪花能出现的大小边界，不能太靠外（被UI遮住），也不能太靠里（会遮住主角）
    private Vector4 mMinBorder = new Vector4(-0.05f, 0.05f, -0.05f, 0.05f);
    private Vector4 mMaxBorder = new Vector4(-0.85f, 0.85f, -0.1f, 0.1f);
    // 可出现雪花区域，NGUI坐标范围
    private Vector2 mScreenSize;
    // 内安全区域四边界，NGUI坐标值
    private Vector4 mSafeAreaMin;
    // 外安全区域四边界，NGUI坐标值
    private Vector4 mSafeAreaMax;
    private List<Vector4> mAreaList = null;

    // 雪花在不同设备分辨率下的相对观感大小要大致相同，该值为相对于UIRoot设计分辨率的缩放系数
    // 创建出来的雪花尺寸，都要乘以该值算出新尺寸
    private float mSnowLocalScaleFactor = 1f;


    private void Awake()
    {
        mMeshFilter = gameObject.GetComponent<MeshFilter>();
        if (mMeshFilter == null)
        {
            string str = string.Format("miss MeshFilter, transform.name = {0}", transform.name);
            Debug.LogError(str);
            return;
        }

        InitPreData();

        InitAreaList(mMinBorder, mMaxBorder);
        
        InitSpriteUVList();

        InitMeshData();

        // 随机出第一个雪花时间间隔
        RandomOneDuration();

        // 测试
        mSnowWidth *= 6;
        mSnowHeight *= 6;
        AddSnow(Vector2.zero);
        AddSnow(new Vector2(200, 0));
    }

    // 预结算数据
    private void InitPreData()
    {
        // 计算出每个雪花的尺寸，用于填充位置
        if (mAtlasTex == null)
        {
            string str = string.Format("miss mAtlasTex, transform.name = {0}", transform.name);
            Debug.LogError(str);
            return;
        }
        mSnowWidth = mAtlasTex.width / mColNum;
        mSnowHeight = mAtlasTex.height / mRowNum;

        mSpriteNum = mRowNum * mColNum;

        // 插值相关数值
        mStepValue = 1f / mLerpTimes;
        mTotalLerpTimes = (mSpriteNum - 1) * mLerpTimes + 1;
    }

    private void InitAreaList(Vector4 minBorder, Vector4 maxBorder)
    {
        // 先计算出屏幕上有效的NGUI坐标范围
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

        // 对该范围分割成多个小区域，用于随机位置使用
        Vector4 temp = new Vector4(mScreenSize.x, mScreenSize.x, mScreenSize.y, mScreenSize.y);
        temp *= 0.5f;
        mSafeAreaMin = Vector4.Scale(minBorder, temp);
        mSafeAreaMax = Vector4.Scale(maxBorder, temp);

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

    private void InitSpriteUVList()
    {
        if (mSpriteNum == 0)
        {
            string str = string.Format("mSpriteNum is 0, transform.name = {0}", transform.name);
            Debug.LogError(str);
            return;
        }

        mSpriteUVList = new List<Vector4>(mSpriteNum);

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

    // 初始化网格数据
    private void InitMeshData()
    {
        mMesh = new Mesh();
        mMesh.MarkDynamic();
        mMeshFilter.mesh = mMesh;

        for (int snowIdx = 0; snowIdx < MAXSNOWNUM; ++snowIdx)
        {
            int idx6 = 6 * snowIdx;
            int idx4 = 4 * snowIdx;
            mTriangles[idx6 + 0] = idx4 + 0;
            mTriangles[idx6 + 1] = idx4 + 2;
            mTriangles[idx6 + 2] = idx4 + 1;
            mTriangles[idx6 + 3] = idx4 + 0;
            mTriangles[idx6 + 4] = idx4 + 3;
            mTriangles[idx6 + 5] = idx4 + 2;

            mUV0[idx4 + 0].Set(0, 1);
            mUV0[idx4 + 1].Set(0, 0);
            mUV0[idx4 + 2].Set(1, 0);
            mUV0[idx4 + 3].Set(1, 1);
        }

        mMesh.vertices = mVertices;
        mMesh.uv = mUV0;
        mMesh.uv2 = mUV1;
        mMesh.uv3 = mUV2;
        mMesh.uv4 = mUV3;
        mMesh.triangles = mTriangles;
        mMesh.tangents = mTangents;
        mMesh.normals = mNormals;
    }

    // 数据腾挪，有效雪花往前挪并保证既有顺序，并找出下一个有效的雪花索引
    private int DoAdjust()
    {
        // 假定数组第一个为下次有效雪花索引
        int nextIdx = 0;
        int snowIdx4 = 0;
        int nextIdx4 = 0;
        for (int snowIdx = 0; snowIdx < MAXSNOWNUM; ++snowIdx)
        {
            snowIdx4 = 4 * snowIdx;
            float active = mNormals[snowIdx4 + 0].z;
            if (Mathf.Abs(active - 1f) < Mathf.Epsilon)
            {
                // 索引相等的，数据不用挪动
                if (nextIdx != snowIdx)
                {
                    nextIdx4 = 4 * nextIdx;
                    for (int i = 0; i < 4; ++i)
                    {
                        mVertices[nextIdx4 + i] = mVertices[snowIdx4 + i];
                        mUV1[nextIdx4 + i] = mUV1[snowIdx4 + i];
                        mUV2[nextIdx4 + i] = mUV2[snowIdx4 + i];
                        mUV3[nextIdx4 + i] = mUV3[snowIdx4 + i];
                        mTangents[nextIdx4 + i] = mTangents[snowIdx4 + i];
                        mNormals[nextIdx4 + i] = mNormals[snowIdx4 + i];
                    }
                }
                ++nextIdx;
            }
        }

        // 判断有效性
        return nextIdx;
    }

    // 往mesh里填充数据，如果空余位置不足，则启动数据腾挪
    private void AddSnow(Vector2 pos)
    {
        // 检查下一个可用雪花索引是否有效
        if (mNextSnowIdx >= MAXSNOWNUM)
        {
            // 数据腾挪，并重新赋值一个mNextSnowIdx
            mNextSnowIdx = DoAdjust();
            if (mNextSnowIdx >= MAXSNOWNUM)
            {
                // 调整后还是没有可用的雪花索引，则需要扩容了
                Debug.LogError("调整后，仍然没有可用的雪花索引，网格数据需要扩容");
                return;
            }
        }

        // 计算数组索引
        int idx = 4 * mNextSnowIdx;
        mVertices[idx + 0].Set(pos.x - mSnowWidth / 2, pos.y + mSnowHeight / 2, 0);
        mVertices[idx + 1].Set(pos.x - mSnowWidth / 2, pos.y - mSnowHeight / 2, 0);
        mVertices[idx + 2].Set(pos.x + mSnowWidth / 2, pos.y - mSnowHeight / 2, 0);
        mVertices[idx + 3].Set(pos.x + mSnowWidth / 2, pos.y + mSnowHeight / 2, 0);

        for (int i = 0; i < 4; ++i)
        {
            mNormals[idx + i].Set(Time.frameCount, Time.frameCount + mTotalLerpTimes, 1);
        }

        ++mNextSnowIdx;
    }

    // 在随机位置创建一个雪花
    private void RandomGenSnow()
    {
        // 随机区域和位置
        int listIdx = Random.Range(0, mAreaList.Count);
        Vector4 v4 = mAreaList[listIdx];
        float rX = Random.Range(v4.x, v4.y);
        float rY = Random.Range(v4.z, v4.w);
        Vector3 localPos = new Vector3(rX, rY, 0);

        //AddSnow(localPos);
    }

    private void CalAtlasOffset(ref Vector3 normal, out int curIdx, out float lerpValue, out float active)
    {
        int totalFrame = mTotalLerpTimes;
        int pastFrame = Time.frameCount - (int)normal.x;
        if (pastFrame >= totalFrame)
        {
            // 后续z=0的要在shader里去除掉
            normal.z = 0f;
            curIdx = mSpriteNum - 2;
            lerpValue = 1f;
        }
        else if (pastFrame == totalFrame - 1)
        {
            // 合法有效的最后一帧
            curIdx = mSpriteNum - 2;
            lerpValue = 1f;
        }
        else
        {
            curIdx = pastFrame / mLerpTimes;
            lerpValue = (pastFrame % mLerpTimes) * mStepValue;
        }

        active = normal.z;
    }

    private void FillLerpValue()
    {
        for (int snowIdx = 0; snowIdx < MAXSNOWNUM; ++snowIdx)
        {
            // 一次计算，填充四个顶点
            int idx = 4 * snowIdx + 0;
            int curIdx;
            float lerpValue;
            float active;
            CalAtlasOffset(ref mNormals[idx], out curIdx, out lerpValue, out active);
            Vector4 curUV = mSpriteUVList[curIdx];
            Vector4 nextUV = mSpriteUVList[curIdx + 1];
            for (int i = 0; i < 4; ++i)
            {
                mUV1[idx + i].Set(curUV.x, curUV.y);
                mUV2[idx + i].Set(curUV.z, curUV.w);
                mUV3[idx + i].Set(lerpValue, lerpValue);
                mTangents[idx + i].Set(nextUV.x, nextUV.y, nextUV.z, nextUV.w);
            }
            // 雪花无效
            if (Mathf.Abs(active) < Mathf.Epsilon)
            {
                for (int i = 0; i < 4; ++i)
                {
                    mNormals[idx + i].z = 0f;
                }
            }
        }

        mMesh.vertices = mVertices;
        mMesh.uv2 = mUV1;
        mMesh.uv3 = mUV2;
        mMesh.uv4 = mUV3;
        mMesh.tangents = mTangents;
        mMesh.normals = mNormals;
    }

    private void Update()
    {
        mCurCounter += Time.deltaTime;
        if (mCurCounter >= mCurDuration)
        {
            mCurCounter = 0f;
            RandomOneDuration();

            RandomGenSnow();
        }

        // 当前有雪花数据，才动态插值计算
        if (mNextSnowIdx > 0)
        {
            // 后续，尝试把该计算挪到shader里
            FillLerpValue();
        }
    }

    private void RandomOneDuration()
    {
        mCurDuration = Random.Range(mMinDuration, mMaxDuration);
    }
}
