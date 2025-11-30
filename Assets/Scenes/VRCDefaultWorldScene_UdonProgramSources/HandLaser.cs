
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.SDK3.Data;
using VRC.Udon;
using VRC.Udon.Common;

public class HandLaser : UdonSharpBehaviour
{
    public VRCPlayerApi player;
    public HandType hand = HandType.RIGHT;

#if !UNITY_ANDROID
    private readonly Vector3 handPosOffset = new Vector3(0.0185f, 0, .0506f);
    private readonly Vector3 handRotOffset = Vector3.up * 40;
#endif

#if UNITY_ANDROID
    private readonly Vector3 handPosOffset = new Vector3(.0079f, 0, .02125f);
    private readonly Vector3 handRotOffset = Vector3.up * 45;
#endif

    void Start()
    {
        if (Networking.LocalPlayer.IsValid() && !Networking.LocalPlayer.IsUserInVR())
        {
            // deactivate hand laser in desktop mode
            this.gameObject.SetActive(false);
        }
    }

    void Update()
    {
        if (!Utilities.IsValid(player))
        {
            player = Networking.LocalPlayer;
        }

        if (!Utilities.IsValid(player))
        {
            return;
        }

        if (!player.IsUserInVR())
        {
            VRCPlayerApi.TrackingData headTrack = player.GetTrackingData(VRCPlayerApi.TrackingDataType.Head);
            transform.position = headTrack.position;
            transform.rotation = headTrack.rotation;

            //this.DisableHighlightsOnPointedObject();

            return;
        }

        VRCPlayerApi.TrackingData trackingData = player.GetTrackingData(
            hand == HandType.RIGHT
                ? VRCPlayerApi.TrackingDataType.RightHand
                : VRCPlayerApi.TrackingDataType.LeftHand);

        Vector3 origin = trackingData.position + trackingData.rotation * handPosOffset;
        Vector3 direction = trackingData.rotation * Quaternion.Euler(handRotOffset) * Vector3.forward;

        transform.position = origin;
        transform.rotation = Quaternion.LookRotation(direction, Vector3.up);

        //this.DisableHighlightsOnPointedObject();
    }

    // attempt at dirty hack to disable vrchat highlights
    // doesnt work
    private void DisableHighlightsOnPointedObject()
    {
        RaycastHit hit;
        float maxDistance = 10f; // tweak as needed

        LayerMask mask = LayerMask.GetMask("Default");
        Ray ray = new Ray(this.transform.position, this.transform.forward);

        if (Physics.Raycast(ray, out hit, maxDistance, mask))
        {
            if (hit.collider == null) return;
            if (hit.collider.gameObject == null) return;

            Debug.Log("HandLaser: Hit object: " + hit.collider.gameObject.name);
    
            GameObject obj = hit.collider.gameObject;

            // Disable highlight on the hit object
            VRC.SDKBase.InputManager.EnableObjectHighlight(obj, false);

            // And on all its renderers
            Renderer[] renderers = obj.GetComponentsInChildren<Renderer>();
            for (int i = 0; i < renderers.Length; i++)
            {
                Renderer r = renderers[i];
                if (r == null) continue;

                VRC.SDKBase.InputManager.EnableObjectHighlight(r, false);
            }
        }
    }
}