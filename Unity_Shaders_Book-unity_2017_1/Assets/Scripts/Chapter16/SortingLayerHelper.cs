using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SortingLayerHelper : MonoBehaviour
{

    public string sortingLayerName = "";

    private void Awake()
    {
        MeshRenderer meshRenderer = transform.GetComponent<MeshRenderer>();
        if (meshRenderer != null)
        {
            meshRenderer.sortingLayerID = SortingLayer.NameToID(sortingLayerName);
        }
            
    }
    // Use this for initialization
    void Start ()
    {
        
	}
	
	// Update is called once per frame
	void Update ()
    {
		
	}
}
