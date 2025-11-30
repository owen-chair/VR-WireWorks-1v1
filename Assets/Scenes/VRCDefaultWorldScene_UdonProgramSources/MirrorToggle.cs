
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class MirrorToggle : UdonSharpBehaviour
{
    public GameObject m_MirrorObject;

    public AudioSource m_ToggleOnSound;
    public AudioSource m_ToggleOffSound;
    
    void Start()
    {
        
    }

    public override void Interact()
    {
        base.Interact();
        
        if (this.m_MirrorObject == null) { Debug.LogError("MirrorToggle.cs: Interact: mirrorObject is null"); return; }

        if (this.m_MirrorObject.gameObject.activeSelf)
        {
            this.m_MirrorObject.gameObject.SetActive(false);
            if (this.m_ToggleOffSound != null)
            {
                this.m_ToggleOffSound.Play();
            }
        }
        else
        {
            this.m_MirrorObject.gameObject.SetActive(true);
            if (this.m_ToggleOnSound != null)
            {
                this.m_ToggleOnSound.Play();
            }
        }
    }
}
