using UnityEngine;

/// <summary>
/// Smooth third-person follow camera for Bangla Tesla Rickshaw.
/// Includes speed-based look-ahead, smooth damping, and dynamic FOV on Rocket Boost.
/// </summary>
public class ThirdPersonCamera : MonoBehaviour
{
    [Header("Follow Target")]
    public Transform target;
    public BanglaTeslaController vehicleController;

    [Header("Camera Offsets")]
    public Vector3 offset = new Vector3(0f, 2.2f, -4.5f);
    public float lookOffsetUp = 1.2f;
    public float positionDamping = 8f;
    public float rotationDamping = 12f;

    [Header("Dynamic FOV")]
    public float normalFov = 60f;
    public float boostFov = 75f;
    public float fovDamping = 4f;

    private Camera cam;

    private void Awake()
    {
        cam = GetComponent<Camera>();
    }

    private void LateUpdate()
    {
        if (target == null) return;

        // Dynamic Field of View
        if (cam != null && vehicleController != null)
        {
            float targetFov = vehicleController.IsHovering ? boostFov : normalFov;
            cam.fieldOfView = Mathf.Lerp(cam.fieldOfView, targetFov, Time.deltaTime * fovDamping);
        }

        // Calculate wanted position relative to target's orientation
        Vector3 wantedPosition = target.TransformPoint(offset);
        
        // Prevent camera from clipping through ground
        if (Physics.Raycast(target.position + Vector3.up * lookOffsetUp, (wantedPosition - target.position).normalized, out RaycastHit hit, offset.magnitude))
        {
            wantedPosition = hit.point + hit.normal * 0.2f;
        }

        // Smooth position
        transform.position = Vector3.Lerp(transform.position, wantedPosition, Time.deltaTime * positionDamping);

        // Smooth rotation looking at the vehicle's upper cabin
        Vector3 lookTarget = target.position + Vector3.up * lookOffsetUp;
        Quaternion wantedRotation = Quaternion.LookRotation(lookTarget - transform.position, Vector3.up);
        transform.rotation = Quaternion.Slerp(transform.rotation, wantedRotation, Time.deltaTime * rotationDamping);
    }
}
