using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SnowMeltBatchedMgr : MonoBehaviour
{
    private MeshFilter mMeshFilter;
    private Mesh mMesh;

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
    private Vector3[] mVertices = new Vector3[4];
    private int[] mTriangles = new int[6];
    private Vector2[] mUV0 = new Vector2[4];
    private Vector2[] mUV1 = new Vector2[4];
    private Vector2[] mUV2 = new Vector2[4];
    private Vector2[] mUV3 = new Vector2[4];
    private Vector4[] mTangents = new Vector4[4];
    private Vector3[] mNormals = new Vector3[4];

    

    private void Awake()
    {
        mMeshFilter = gameObject.GetComponent<MeshFilter>();
        if (mMeshFilter == null)
        {
            string str = string.Format("miss MeshFilter, transform.name = {0}", transform.name);
            Debug.LogError(str);
            return;
        }

        if (mAtlasTex == null)
        {
            string str = string.Format("miss mAtlasTex, transform.name = {0}", transform.name);
            Debug.LogError(str);
            return;
        }

        mSnowWidth = mAtlasTex.width / mColNum;
        mSnowHeight = mAtlasTex.height / mRowNum;

        Init();
    }

    private void Init()
    {
        CalSpriteUVList();

        // 插值相关数值
        mStepValue = 1f / mLerpTimes;
        mTotalLerpTimes = (mSpriteNum - 1) * mLerpTimes + 1 + 1;

        //构建网格
        mMesh = new Mesh();
        mMesh.MarkDynamic();
        mMeshFilter.mesh = mMesh;

        mTriangles[0] = 0;
        mTriangles[1] = 2;
        mTriangles[2] = 1;
        mTriangles[3] = 0;
        mTriangles[4] = 3;
        mTriangles[5] = 2;

        mUV0[0].Set(0, 1);
        mUV0[1].Set(0, 0);
        mUV0[2].Set(1, 0);
        mUV0[3].Set(1, 1);

        mMesh.vertices = mVertices;
        mMesh.uv = mUV0;
        mMesh.uv2 = mUV1;
        mMesh.uv3 = mUV2;
        mMesh.uv4 = mUV3;
        mMesh.triangles = mTriangles;
        mMesh.tangents = mTangents;
        mMesh.normals = mNormals;

        AddSnow(Vector2.zero);
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

    private void AddSnow(Vector2 pos)
    {
        mVertices[0].Set(pos.x - mSnowWidth / 2, pos.y + mSnowHeight / 2, 0);
        mVertices[1].Set(pos.x - mSnowWidth / 2, pos.y - mSnowHeight / 2, 0);
        mVertices[2].Set(pos.x + mSnowWidth / 2, pos.y - mSnowHeight / 2, 0);
        mVertices[3].Set(pos.x + mSnowWidth / 2, pos.y + mSnowHeight / 2, 0);

        mNormals[0].Set(Time.frameCount, Time.frameCount + mTotalLerpTimes, 1);
        mNormals[1].Set(Time.frameCount, Time.frameCount + mTotalLerpTimes, 1);
        mNormals[2].Set(Time.frameCount, Time.frameCount + mTotalLerpTimes, 1);
        mNormals[3].Set(Time.frameCount, Time.frameCount + mTotalLerpTimes, 1);
    }

    private void CalAtlasOffset(ref Vector3 normal, out int curIdx, out float lerpValue)
    {
        if (Time.frameCount >= (int)normal.y)
        {
            normal.z = 0f;
            curIdx = mSpriteNum - 2;
            lerpValue = 1f;
        }
        else if (Time.frameCount == ((int)normal.y - 1))
        {
            curIdx = mSpriteNum - 2;
            lerpValue = 1f;
        }
        else
        {
            int pastFrame = Time.frameCount - (int)normal.x - 1;
            curIdx = pastFrame / mLerpTimes;
            lerpValue = (pastFrame % mLerpTimes) * mStepValue;
        }
    }

    private void FillLerpValue()
    {
        for (int idx = 0; idx < 4; ++idx)
        {
            int curIdx;
            float lerpValue;
            CalAtlasOffset(ref mNormals[idx], out curIdx, out lerpValue);
            Vector4 curUV = mSpriteUVList[curIdx];
            Vector4 nextUV = mSpriteUVList[curIdx + 1];
            mUV1[idx].Set(curUV.x, curUV.y);
            mUV2[idx].Set(curUV.z, curUV.w);
            mUV3[idx].Set(lerpValue, lerpValue);
            mTangents[idx].Set(nextUV.x, nextUV.y, nextUV.z, nextUV.w);
        }

        mMesh.vertices = mVertices;
        mMesh.uv2 = mUV1;
        mMesh.uv3 = mUV2;
        mMesh.uv4 = mUV3;
        mMesh.tangents = mTangents;
        mMesh.normals = mNormals;
    }

    private float mTimer = 0f;
    private float mDuration = 2f;
    private void Update()
    {
        mTimer += Time.deltaTime;
        if (mTimer >= mDuration)
        {
            mTimer = 0f;
        }

        FillLerpValue();
    }
}
