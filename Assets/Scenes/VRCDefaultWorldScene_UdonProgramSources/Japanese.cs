
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class Japanese : UdonSharpBehaviour
{
    public GameObject m_WhiteboardObject;
    [Header("Assign the Japanese material to apply on interaction")]
    public Material m_JapanMaterial;

    private Renderer _renderer;

    void Start()
    {
        if (m_WhiteboardObject != null)
        {
            _renderer = m_WhiteboardObject.GetComponent<Renderer>();
        }
        else
        {
            _renderer = GetComponent<Renderer>();
        }
    }

    public override void Interact()
    {
        base.Interact();
        // Always apply Japanese material (idempotent)
        ApplyJapanese();
    }
    
    private void ApplyJapanese()
    {
        if (_renderer == null) return;
        if (m_JapanMaterial == null) return;

        Material[] mats = _renderer.sharedMaterials;
        if (mats != null && mats.Length > 0)
        {
            for (int i = 0; i < mats.Length; i++)
            {
                mats[i] = m_JapanMaterial;
            }
            _renderer.sharedMaterials = mats;
        }
        else
        {
            _renderer.sharedMaterial = m_JapanMaterial;
        }
    }
}

