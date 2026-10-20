using System;
using UnityEngine;

/// <summary>
/// Bridge handling two-way communication between Flutter and Unity.
/// Uses flutter_unity_widget protocol.
/// </summary>
public class FlutterUnityBridge : MonoBehaviour
{
    private static FlutterUnityBridge _instance;
    private BanglaTeslaController vehicleController;

    private void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }
        _instance = this;
        DontDestroyOnLoad(gameObject);
        vehicleController = FindObjectOfType<BanglaTeslaController>();
    }

    /// <summary>
    /// Sends a message from Unity back to the Flutter UI layer.
    /// </summary>
    public static void SendMessageToFlutter(string handler, string message)
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            using (AndroidJavaClass jc = new AndroidJavaClass("com.xraph.plugin.flutter_unity_widget.FlutterUnityWidgetPlugin"))
            {
                jc.CallStatic("onUnityMessage", $"{handler}:{message}");
            }
        }
        catch (Exception ex)
        {
            Debug.LogWarning($"[FlutterUnityBridge] Message error: {ex.Message}");
        }
#else
        Debug.Log($"[Unity -> Flutter] ({handler}): {message}");
#endif
    }

    // --- Inbound Handlers called from Flutter ---

    // Mobile Driving Controls from Flutter overlay HUD
    public void SetSteering(string value)
    {
        if (float.TryParse(value, out float steer) && vehicleController != null)
        {
            vehicleController.SetSteerInput(steer);
        }
    }

    public void SetThrottle(string value)
    {
        if (float.TryParse(value, out float throttle) && vehicleController != null)
        {
            vehicleController.SetThrottleInput(throttle);
        }
    }

    public void SetBraking(string value)
    {
        bool braking = value == "1" || value.ToLower() == "true";
        if (vehicleController != null)
        {
            vehicleController.SetBraking(braking);
        }
    }

    public void ToggleRocketBoost(string _)
    {
        if (vehicleController != null)
        {
            vehicleController.ToggleRocketBoost();
        }
    }

    public void RingBell(string _)
    {
        if (vehicleController != null)
        {
            vehicleController.RingRickshawBell();
        }
    }

    // Vehicle Upgrade Handlers from Flutter Garage
    public void UpgradeMotorPower(string level)
    {
        if (int.TryParse(level, out int lvl) && vehicleController != null)
        {
            vehicleController.motorTorque = 1200f + (lvl * 300f);
            vehicleController.maxSpeed = 35f + (lvl * 5f);
        }
    }

    public void UpgradeRocketBoost(string level)
    {
        if (int.TryParse(level, out int lvl) && vehicleController != null)
        {
            vehicleController.rocketBoostSpeed = 75f + (lvl * 15f);
            vehicleController.rocketForwardThrust = 4500f + (lvl * 800f);
        }
    }
}
