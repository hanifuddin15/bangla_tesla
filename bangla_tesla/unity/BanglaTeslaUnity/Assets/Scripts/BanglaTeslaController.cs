using UnityEngine;

/// <summary>
/// Vehicle Controller for the "Bangla Tesla" Rocket Rickshaw.
/// Supports both grounded 3-wheel street driving and Rocket Hover/Flight mode.
/// Optimized for Unity on Android with on-screen mobile controls.
/// </summary>
[RequireComponent(typeof(Rigidbody))]
public class BanglaTeslaController : MonoBehaviour
{
    [Header("3-Wheel Rigging & Transforms")]
    [Tooltip("The front steering fork that pivots left/right")]
    public Transform frontFork;
    [Tooltip("The front rolling wheel")]
    public Transform frontWheel;
    [Tooltip("The rear left rolling wheel")]
    public Transform rearWheelLeft;
    [Tooltip("The rear right rolling wheel")]
    public Transform rearWheelRight;
    [Tooltip("Passenger seat anchor point for mission passengers")]
    public Transform passengerSeatPoint;

    [Header("Rocket Jet Thrusters (Cyan Plasma)")]
    public Transform frontThruster;
    public Transform rearThrusterLeft;
    public Transform rearThrusterRight;
    public ParticleSystem[] thrusterParticles;
    public Light[] thrusterLights;

    [Header("Driving Physics")]
    public float motorTorque = 1200f;
    public float maxSpeed = 35f;           // Typical street speed in km/h
    public float brakeForce = 2000f;
    public float maxSteerAngle = 35f;
    public float turnSmoothSpeed = 10f;
    public float centerOfMassY = -0.3f;    // Low center of mass to prevent tipping

    [Header("Bangla Tesla Hover / Rocket Boost Mode")]
    public bool isRocketBoostActive = false;
    public float rocketBoostSpeed = 75f;   // High-speed flight mode
    public float hoverHeight = 2.0f;       // Hover distance above ground
    public float hoverSpringForce = 3500f;
    public float hoverDamping = 600f;
    public float rocketForwardThrust = 4500f;

    [Header("Sound & Feedback")]
    public AudioSource engineAudio;
    public AudioSource rocketAudio;
    public AudioSource bellAudio;          // Classic "Tring Tring" rickshaw bell

    // Internal State
    private Rigidbody rb;
    private float currentSteerAngle = 0f;
    private float horizontalInput = 0f;
    private float verticalInput = 0f;
    private bool isBraking = false;
    private bool isGrounded = true;

    // Public getters for Flutter HUD
    public float CurrentSpeedKmh => rb != null ? rb.velocity.magnitude * 3.6f : 0f;
    public bool IsHovering => isRocketBoostActive;

    private void Awake()
    {
        rb = GetComponent<Rigidbody>();
        rb.centerOfMass = new Vector3(0f, centerOfMassY, 0f);
        rb.drag = 0.5f;
        rb.angularDrag = 3.0f;
    }

    private void Update()
    {
        // 1. Process Input (Desktop keyboard or mobile touch triggers)
        ProcessInput();

        // 2. Animate visual components (fork steering & wheel rolling)
        AnimateVisualWheels();

        // 3. Update thrusters visual effects
        UpdateThrusterEffects();
    }

    private void FixedUpdate()
    {
        if (isRocketBoostActive)
        {
            ApplyRocketHoverPhysics();
        }
        else
        {
            ApplyStreetDrivingPhysics();
        }
    }

    private void ProcessInput()
    {
        // Read keyboard input if available, or keep touch input provided by UI buttons
#if UNITY_EDITOR || UNITY_STANDALONE
        if (Mathf.Abs(Input.GetAxis("Horizontal")) > 0.05f)
            horizontalInput = Input.GetAxis("Horizontal");
        if (Mathf.Abs(Input.GetAxis("Vertical")) > 0.05f)
            verticalInput = Input.GetAxis("Vertical");

        isBraking = Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.Space);
        
        if (Input.GetKeyDown(KeyCode.B))
        {
            RingRickshawBell();
        }

        if (Input.GetKeyDown(KeyCode.T))
        {
            ToggleRocketBoost();
        }
#endif
    }

    private void ApplyStreetDrivingPhysics()
    {
        // Forward / Reverse acceleration
        float targetSpeed = verticalInput * (maxSpeed / 3.6f);
        Vector3 forwardVelocity = Vector3.Project(rb.velocity, transform.forward);
        
        if (isBraking)
        {
            rb.AddForce(-forwardVelocity.normalized * brakeForce, ForceMode.Force);
        }
        else if (Mathf.Abs(verticalInput) > 0.05f)
        {
            if (forwardVelocity.magnitude < (maxSpeed / 3.6f))
            {
                rb.AddForce(transform.forward * (verticalInput * motorTorque), ForceMode.Force);
            }
        }

        // 3-Wheel Steering
        float turnAmount = horizontalInput * (currentSteerAngle / maxSteerAngle);
        float currentSpeed = rb.velocity.magnitude;
        if (currentSpeed > 0.5f)
        {
            float direction = Vector3.Dot(rb.velocity, transform.forward) >= 0 ? 1f : -1f;
            float yaw = turnAmount * 60f * direction * Time.fixedDeltaTime;
            transform.Rotate(0f, yaw, 0f);
        }

        // Rickshaw banking/tilt for natural street feel
        float rollAngle = -horizontalInput * 4f * Mathf.Clamp01(currentSpeed / 10f);
        Vector3 euler = transform.localEulerAngles;
        euler.z = Mathf.LerpAngle(euler.z, rollAngle, Time.fixedDeltaTime * 5f);
        transform.localEulerAngles = euler;
    }

    private void ApplyRocketHoverPhysics()
    {
        // Hover raycasts for all 3 wheel points (Front, Rear-Left, Rear-Right)
        ApplyThrusterHoverForce(frontThruster != null ? frontThruster.position : transform.position + transform.forward * 0.75f);
        ApplyThrusterHoverForce(rearThrusterLeft != null ? rearThrusterLeft.position : transform.position - transform.forward * 0.6f - transform.right * 0.5f);
        ApplyThrusterHoverForce(rearThrusterRight != null ? rearThrusterRight.position : transform.position - transform.forward * 0.6f + transform.right * 0.5f);

        // Rocket forward propulsion
        float boostTargetSpeed = rocketBoostSpeed / 3.6f;
        if (rb.velocity.magnitude < boostTargetSpeed)
        {
            rb.AddForce(transform.forward * rocketForwardThrust, ForceMode.Force);
        }

        // Air steering
        if (Mathf.Abs(horizontalInput) > 0.05f)
        {
            transform.Rotate(0f, horizontalInput * 70f * Time.fixedDeltaTime, 0f);
        }
    }

    private void ApplyThrusterHoverForce(Vector3 thrusterWorldPos)
    {
        Ray ray = new Ray(thrusterWorldPos, Vector3.down);
        if (Physics.Raycast(ray, out RaycastHit hit, hoverHeight * 2f))
        {
            float distance = hit.distance;
            float error = hoverHeight - distance;
            float force = error * hoverSpringForce - rb.velocity.y * hoverDamping;
            rb.AddForceAtPosition(Vector3.up * Mathf.Max(0f, force), thrusterWorldPos, ForceMode.Force);
        }
    }

    private void AnimateVisualWheels()
    {
        // Front Fork Steering Angle
        float targetSteer = horizontalInput * maxSteerAngle;
        currentSteerAngle = Mathf.Lerp(currentSteerAngle, targetSteer, Time.deltaTime * turnSmoothSpeed);
        if (frontFork != null)
        {
            frontFork.localRotation = Quaternion.Euler(0f, currentSteerAngle, 0f);
        }

        // Rolling Wheels
        float speed = rb.velocity.magnitude;
        float rollAngle = (speed / 0.35f) * Mathf.Rad2Deg * Time.deltaTime;
        float rollDirection = Vector3.Dot(rb.velocity, transform.forward) >= 0 ? 1f : -1f;

        if (frontWheel != null) frontWheel.Rotate(Vector3.right, rollAngle * rollDirection, Space.Self);
        if (rearWheelLeft != null) rearWheelLeft.Rotate(Vector3.right, rollAngle * rollDirection, Space.Self);
        if (rearWheelRight != null) rearWheelRight.Rotate(Vector3.right, rollAngle * rollDirection, Space.Self);
    }

    private void UpdateThrusterEffects()
    {
        bool emit = isRocketBoostActive;

        if (thrusterParticles != null)
        {
            foreach (var ps in thrusterParticles)
            {
                if (ps == null) continue;
                if (emit && !ps.isPlaying) ps.Play();
                else if (!emit && ps.isPlaying) ps.Stop();
            }
        }

        if (thrusterLights != null)
        {
            foreach (var l in thrusterLights)
            {
                if (l != null) l.enabled = emit;
            }
        }

        if (rocketAudio != null)
        {
            if (emit && !rocketAudio.isPlaying) rocketAudio.Play();
            else if (!emit && rocketAudio.isPlaying) rocketAudio.Stop();
        }
    }

    // --- Mobile Touch UI Hooks (Called from On-Screen Canvas buttons) ---
    public void SetSteerInput(float steer) => horizontalInput = Mathf.Clamp(steer, -1f, 1f);
    public void SetThrottleInput(float throttle) => verticalInput = Mathf.Clamp(throttle, -1f, 1f);
    public void SetBraking(bool braking) => isBraking = braking;

    public void ToggleRocketBoost()
    {
        isRocketBoostActive = !isRocketBoostActive;
        // Notify Flutter
        FlutterUnityBridge.SendMessageToFlutter("OnBoostStateChanged", isRocketBoostActive ? "ON" : "OFF");
    }

    public void RingRickshawBell()
    {
        if (bellAudio != null)
        {
            bellAudio.Play();
        }
    }
}
