using System;
using UnityEngine;

/// <summary>
/// Passenger pickup & drop-off mission manager for Bangla Tesla.
/// Handles passenger spawning, destination waypoints, fares in Bangladeshi Taka (৳),
/// and reports mission updates to Flutter.
/// </summary>
public class PassengerMissionController : MonoBehaviour
{
    [System.Serializable]
    public class MissionWaypoint
    {
        public string locationName;       // e.g. "Farmgate", "Dhanmondi 27", "Shahbagh", "Gulshan 1"
        public Transform pickupPoint;
        public Transform dropoffPoint;
        public int baseFareTaka;          // e.g. 60 ৳
        public float timeLimitSeconds;    // e.g. 90s
    }

    [Header("Mission Configuration")]
    public MissionWaypoint[] predefinedMissions;
    public Transform passengerPrefab;
    public Transform currentPassengerInstance;
    public Transform rickshawSeatAnchor;

    [Header("HUD & Markers")]
    public GameObject pickupMarkerVisual;
    public GameObject dropoffMarkerVisual;
    public float interactionRadius = 3.5f;

    [Header("Current Mission State")]
    public bool hasActiveMission = false;
    public bool isPassengerOnboard = false;
    public int currentMissionIndex = 0;
    public float missionTimer = 0f;

    private Transform playerVehicle;

    private void Start()
    {
        var player = FindObjectOfType<BanglaTeslaController>();
        if (player != null)
        {
            playerVehicle = player.transform;
            if (rickshawSeatAnchor == null)
            {
                rickshawSeatAnchor = player.passengerSeatPoint;
            }
        }

        // Start first mission
        StartNextMission();
    }

    private void Update()
    {
        if (!hasActiveMission || playerVehicle == null) return;

        missionTimer += Time.deltaTime;
        MissionWaypoint mission = predefinedMissions[currentMissionIndex];

        // 1. Waiting for Pickup
        if (!isPassengerOnboard)
        {
            if (mission.pickupPoint != null)
            {
                float distToPickup = Vector3.Distance(playerVehicle.position, mission.pickupPoint.position);
                if (distToPickup <= interactionRadius)
                {
                    PickupPassenger();
                }
            }
        }
        // 2. Transporting to Drop-off
        else
        {
            if (mission.dropoffPoint != null)
            {
                float distToDropoff = Vector3.Distance(playerVehicle.position, mission.dropoffPoint.position);
                if (distToDropoff <= interactionRadius)
                {
                    CompleteDropoff();
                }
            }
        }
    }

    public void StartNextMission()
    {
        if (predefinedMissions == null || predefinedMissions.Length == 0) return;

        hasActiveMission = true;
        isPassengerOnboard = false;
        missionTimer = 0f;

        MissionWaypoint mission = predefinedMissions[currentMissionIndex];

        if (pickupMarkerVisual != null && mission.pickupPoint != null)
        {
            pickupMarkerVisual.transform.position = mission.pickupPoint.position;
            pickupMarkerVisual.SetActive(true);
        }
        if (dropoffMarkerVisual != null)
        {
            dropoffMarkerVisual.SetActive(false);
        }

        // Spawn roadside passenger NPC
        if (passengerPrefab != null && mission.pickupPoint != null)
        {
            if (currentPassengerInstance != null) Destroy(currentPassengerInstance.gameObject);
            currentPassengerInstance = Instantiate(passengerPrefab, mission.pickupPoint.position, mission.pickupPoint.rotation);
        }

        // Notify Flutter
        string msg = $"{{\"event\":\"MissionStarted\",\"location\":\"{mission.locationName}\",\"fare\":{mission.baseFareTaka}}}";
        FlutterUnityBridge.SendMessageToFlutter("OnMissionEvent", msg);
    }

    private void PickupPassenger()
    {
        isPassengerOnboard = true;
        MissionWaypoint mission = predefinedMissions[currentMissionIndex];

        if (pickupMarkerVisual != null) pickupMarkerVisual.SetActive(false);
        if (dropoffMarkerVisual != null && mission.dropoffPoint != null)
        {
            dropoffMarkerVisual.transform.position = mission.dropoffPoint.position;
            dropoffMarkerVisual.SetActive(true);
        }

        // Seat the passenger inside the rickshaw rear passenger box
        if (currentPassengerInstance != null && rickshawSeatAnchor != null)
        {
            currentPassengerInstance.SetParent(rickshawSeatAnchor);
            currentPassengerInstance.localPosition = Vector3.zero;
            currentPassengerInstance.localRotation = Quaternion.identity;
        }

        string msg = $"{{\"event\":\"PassengerBoarded\",\"destination\":\"{mission.locationName}\"}}";
        FlutterUnityBridge.SendMessageToFlutter("OnMissionEvent", msg);
    }

    private void CompleteDropoff()
    {
        hasActiveMission = false;
        MissionWaypoint mission = predefinedMissions[currentMissionIndex];

        // Calculate bonuses (speed bonus for fast rocket delivery)
        int bonus = 0;
        if (missionTimer < mission.timeLimitSeconds)
        {
            bonus = Mathf.RoundToInt((mission.timeLimitSeconds - missionTimer) * 0.5f);
        }
        int totalEarned = mission.baseFareTaka + bonus;

        if (dropoffMarkerVisual != null) dropoffMarkerVisual.SetActive(false);
        if (currentPassengerInstance != null)
        {
            Destroy(currentPassengerInstance.gameObject);
            currentPassengerInstance = null;
        }

        string msg = $"{{\"event\":\"MissionCompleted\",\"earnedTaka\":{totalEarned},\"bonus\":{bonus},\"location\":\"{mission.locationName}\"}}";
        FlutterUnityBridge.SendMessageToFlutter("OnMissionEvent", msg);

        // Advance to next mission
        currentMissionIndex = (currentMissionIndex + 1) % predefinedMissions.Length;
        Invoke(nameof(StartNextMission), 3.0f);
    }
}
