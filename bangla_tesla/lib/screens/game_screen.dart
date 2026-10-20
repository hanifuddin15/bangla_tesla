import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Full Real-time 3D Driving Game Engine for Bangla Tesla Rocket Rickshaw.
/// Runs at 60 FPS directly on Android / iOS / Desktop / Web without external plugins.
class GameScreen extends StatefulWidget {
  final Function(int fare) onFareEarned;

  const GameScreen({super.key, required this.onFareEarned});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late Ticker _ticker;

  // --- Vehicle Physics State ---
  double vehicleX = 0.0;          // Lateral lane position (-4.0 to +4.0)
  double vehicleY = 0.0;          // Elevation / Hover height (0.0 = ground, 1.8 = hover)
  double vehicleZ = 0.0;          // Distance traveled forward (meters)
  double speedKmh = 0.0;          // Current speed
  double targetSpeedKmh = 0.0;    // Desired speed
  double steerAngle = 0.0;        // Front steering fork angle (-0.4 to +0.4 rad)
  double wheelRotation = 0.0;     // Rolling wheels angle
  double rickshawRoll = 0.0;      // Banking tilt into turns

  // --- Rocket Thrusters & Hover State ---
  bool isRocketBoost = false;
  double thrusterGlow = 0.0;
  List<ThrusterParticle> particles = [];

  // --- Input State ---
  bool isSteeringLeft = false;
  bool isSteeringRight = false;
  bool isGasPressed = false;
  bool isBrakePressed = false;

  // --- Mission & Economy State ---
  int currentFaresTaka = 0;
  bool hasPassenger = false;
  String currentPickupLocation = "ফার্মগেট মোড় (Farmgate)";
  String currentDropoffLocation = "শাহবাগ চত্বর (Shahbagh)";
  double nextPassengerZ = 120.0; // Distance ahead for passenger pickup
  double missionDropoffZ = 350.0; // Distance ahead for dropoff
  int missionFare = 80;
  String missionAlertText = "যাত্রী খুঁজুন: সামনের মোড়ে যাত্রী অপেক্ষা করছে!";

  // Visual bells
  bool showBellRipple = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onGameTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onGameTick(Duration elapsed) {
    // 60 FPS physics integration
    const double dt = 1.0 / 60.0;

    // 1. Steering & Banking
    if (isSteeringLeft) {
      steerAngle = (steerAngle - 3.5 * dt).clamp(-0.45, 0.45);
    } else if (isSteeringRight) {
      steerAngle = (steerAngle + 3.5 * dt).clamp(-0.45, 0.45);
    } else {
      steerAngle = steerAngle * 0.85; // Auto center
    }

    // Vehicle lateral movement
    if (speedKmh > 0.5) {
      vehicleX += steerAngle * (speedKmh / 20.0) * dt * 8.0;
      vehicleX = vehicleX.clamp(-4.2, 4.2);
      rickshawRoll = -steerAngle * 0.35;
    } else {
      rickshawRoll = 0.0;
    }

    // 2. Throttle & Braking
    double maxDriveSpeed = isRocketBoost ? 95.0 : 38.0;
    if (isGasPressed) {
      targetSpeedKmh = maxDriveSpeed;
    } else if (isBrakePressed) {
      targetSpeedKmh = 0.0;
    } else {
      targetSpeedKmh = isRocketBoost ? 65.0 : 0.0; // Rocket maintains cruise
    }

    // Smooth speed acceleration / braking
    double accelRate = isBrakePressed ? 45.0 : (isRocketBoost ? 30.0 : 18.0);
    if (speedKmh < targetSpeedKmh) {
      speedKmh = min(maxDriveSpeed, speedKmh + accelRate * dt);
    } else if (speedKmh > targetSpeedKmh) {
      speedKmh = max(0.0, speedKmh - accelRate * 1.5 * dt);
    }

    // 3. Forward Distance & Wheel Rotation
    double metersPerSecond = speedKmh * (1000.0 / 3600.0);
    vehicleZ += metersPerSecond * dt;
    wheelRotation += metersPerSecond * dt * 3.5;

    // 4. Hover Physics (Smooth VTOL liftoff when boost is active)
    double targetY = isRocketBoost ? 1.6 : 0.0;
    vehicleY += (targetY - vehicleY) * 6.0 * dt;

    if (isRocketBoost) {
      thrusterGlow = min(1.0, thrusterGlow + 4.0 * dt);
      // Spawn thruster particles
      if (Random().nextDouble() < 0.8) {
        particles.add(ThrusterParticle(
          x: vehicleX + (Random().nextDouble() - 0.5) * 0.8,
          y: vehicleY - 0.2,
          z: vehicleZ - 0.3,
          vx: (Random().nextDouble() - 0.5) * 0.4,
          vy: -1.5 - Random().nextDouble() * 2.0,
          vz: -metersPerSecond * 0.4,
          life: 0.4,
        ));
      }
    } else {
      thrusterGlow = max(0.0, thrusterGlow - 3.0 * dt);
    }

    // Update particles
    for (var p in particles) {
      p.update(dt);
    }
    particles.removeWhere((p) => p.life <= 0);

    // 5. Missions Check (Pickup / Drop-off along the road)
    if (!hasPassenger) {
      if ((vehicleZ - nextPassengerZ).abs() < 5.0 && speedKmh < 15.0) {
        // Passenger Picked Up!
        hasPassenger = true;
        missionAlertText = "🎉 যাত্রী উঠেছে! গন্তব্য: $currentDropoffLocation";
        missionDropoffZ = vehicleZ + 250.0;
      }
    } else {
      if ((vehicleZ - missionDropoffZ).abs() < 6.0 && speedKmh < 15.0) {
        // Passenger Dropped Off!
        hasPassenger = false;
        currentFaresTaka += missionFare;
        widget.onFareEarned(missionFare);
        missionAlertText = "💰 ট্রিপ সমাপ্ত! ভাড়া আদায়: ৳ $missionFare টাকা";
        nextPassengerZ = vehicleZ + 180.0;
        missionFare = 70 + (currentFaresTaka % 50);
      }
    }

    setState(() {});
  }

  void _ringBell() {
    setState(() {
      showBellRipple = true;
      missionAlertText = "🔔 ট্রিং! ট্রিং! সাইড দেন মামা!";
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => showBellRipple = false);
    });
  }

  void _toggleRocket() {
    setState(() {
      isRocketBoost = !isRocketBoost;
      missionAlertText = isRocketBoost
          ? "🚀 বাংলা টেসলা রকেট প্লাজমা সক্রিয়! (HOVER BOOST ACTIVE)"
          : "🛺 গ্রাউন্ড সাইক্লিং মোড";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D14),
      body: Stack(
        children: [
          // 1. Full 3D Driving Canvas Viewport
          Positioned.fill(
            child: CustomPaint(
              painter: World3DRenderer(
                vehicleX: vehicleX,
                vehicleY: vehicleY,
                vehicleZ: vehicleZ,
                speedKmh: speedKmh,
                steerAngle: steerAngle,
                wheelRotation: wheelRotation,
                rickshawRoll: rickshawRoll,
                isRocketBoost: isRocketBoost,
                thrusterGlow: thrusterGlow,
                particles: particles,
                hasPassenger: hasPassenger,
                nextPassengerZ: nextPassengerZ,
                dropoffZ: missionDropoffZ,
              ),
            ),
          ),

          // 2. Top Navigation & Mission HUD
          Positioned(
            top: 45,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Mission Information Panel
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xE6141D2C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasPassenger ? Colors.greenAccent : const Color(0xFF00E5FF),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (hasPassenger ? Colors.greenAccent : const Color(0xFF00E5FF)).withValues(alpha: 0.25),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasPassenger ? Icons.person_pin_circle : Icons.hail,
                              color: hasPassenger ? Colors.greenAccent : Colors.orangeAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasPassenger ? "গন্তব্যে পৌঁছান:" : "যাত্রী পিকআপ পয়েন্ট:",
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hasPassenger ? currentDropoffLocation : currentPickupLocation,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasPassenger
                              ? "বাকি দূরত্ব: ${max(0, (missionDropoffZ - vehicleZ)).toStringAsFixed(0)}m  (ভাড়া: ৳$missionFare)"
                              : "পিকআপ বাকি: ${max(0, (nextPassengerZ - vehicleZ)).toStringAsFixed(0)}m (গাড়ি থামান)",
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Earnings Fare Meter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xE6002A16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.greenAccent, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "মোট আয় (FARES)",
                        style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "৳ $currentFaresTaka",
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Central Mission Notification Banner
          Positioned(
            top: 135,
            left: 20,
            right: 20,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 0.95,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    missionAlertText,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),

          // 4. Digital Speedometer & Status HUD
          Positioned(
            left: 20,
            bottom: 130,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xCC0E1624),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRocketBoost ? const Color(0xFF00E5FF) : Colors.white24,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isRocketBoost ? const Color(0xFF00E5FF).withValues(alpha: 0.3) : Colors.black45,
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        speedKmh.toStringAsFixed(0),
                        style: TextStyle(
                          color: isRocketBoost ? const Color(0xFF00E5FF) : Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("KM/H", style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("SPEED", style: TextStyle(color: Colors.white38, fontSize: 8)),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    isRocketBoost ? "⚡ VTOL ROCKET HOVER" : "🛺 3-WHEEL STREET DRIVE",
                    style: TextStyle(
                      color: isRocketBoost ? const Color(0xFF00E5FF) : Colors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. On-Screen Touch Driving Controls (Steering, Gas, Brake, Rocket, Bell)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Steering Touch Buttons (Left / Right)
                Row(
                  children: [
                    _buildTouchButton(
                      icon: Icons.arrow_back_ios_new,
                      label: "বামে",
                      isActive: isSteeringLeft,
                      onDown: () => setState(() => isSteeringLeft = true),
                      onUp: () => setState(() => isSteeringLeft = false),
                    ),
                    const SizedBox(width: 12),
                    _buildTouchButton(
                      icon: Icons.arrow_forward_ios,
                      label: "ডানে",
                      isActive: isSteeringRight,
                      onDown: () => setState(() => isSteeringRight = true),
                      onUp: () => setState(() => isSteeringRight = false),
                    ),
                  ],
                ),

                // Center Action Buttons (Bell & Tesla Rocket Boost)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bell Button
                    GestureDetector(
                      onTap: _ringBell,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.amber, Colors.orangeAccent]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.amber, blurRadius: 10)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_active, color: Colors.black, size: 16),
                            SizedBox(width: 6),
                            Text("ট্রিং ট্রিং", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Rocket Boost Hover Toggle
                    GestureDetector(
                      onTap: _toggleRocket,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isRocketBoost
                                ? [const Color(0xFF00E5FF), const Color(0xFF0077FF)]
                                : [const Color(0xFF2C394B), const Color(0xFF1B2430)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isRocketBoost ? Colors.white : const Color(0xFF00E5FF),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isRocketBoost
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                                  : Colors.black38,
                              blurRadius: isRocketBoost ? 20 : 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.rocket_launch, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              isRocketBoost ? "হভার উড়ন্ত মোড" : "টেসলা রকেট বুস্ট",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Driving Pedals (Brake & Gas)
                Row(
                  children: [
                    // Brake / Reverse
                    _buildPedal(
                      label: "ব্রেক",
                      subLabel: "BRAKE",
                      color: const Color(0xFFD32F2F),
                      height: 70,
                      isPressed: isBrakePressed,
                      onDown: () => setState(() => isBrakePressed = true),
                      onUp: () => setState(() => isBrakePressed = false),
                    ),
                    const SizedBox(width: 12),
                    // Accelerate Gas
                    _buildPedal(
                      label: "প্যাডেল",
                      subLabel: "GAS",
                      color: const Color(0xFF2E7D32),
                      height: 90,
                      isPressed: isGasPressed,
                      onDown: () => setState(() => isGasPressed = true),
                      onUp: () => setState(() => isGasPressed = false),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onDown,
    required VoidCallback onUp,
  }) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: () => onUp(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF00E5FF) : const Color(0xFF263238),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
              boxShadow: [
                BoxShadow(
                  color: isActive ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : Colors.black45,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: isActive ? Colors.black : Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPedal({
    required String label,
    required String subLabel,
    required Color color,
    required double height,
    required bool isPressed,
    required VoidCallback onDown,
    required VoidCallback onUp,
  }) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: () => onUp(),
      child: Container(
        width: 56,
        height: height,
        decoration: BoxDecoration(
          color: isPressed ? color.withValues(alpha: 0.8) : color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isPressed ? Colors.white : Colors.white38, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isPressed ? 0.7 : 0.4),
              blurRadius: isPressed ? 14 : 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(subLabel, style: const TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}

/// Particle representation for Cyan Plasma Rocket exhaust.
class ThrusterParticle {
  double x, y, z;
  double vx, vy, vz;
  double life;
  final double maxLife;

  ThrusterParticle({
    required this.x,
    required this.y,
    required this.z,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.life,
  }) : maxLife = life;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    z += vz * dt;
    life -= dt;
  }
}

/// Real-time 3D Perspective Vector Renderer for Bangla Tesla, Streets, and Environment.
class World3DRenderer extends CustomPainter {
  final double vehicleX;
  final double vehicleY;
  final double vehicleZ;
  final double speedKmh;
  final double steerAngle;
  final double wheelRotation;
  final double rickshawRoll;
  final bool isRocketBoost;
  final double thrusterGlow;
  final List<ThrusterParticle> particles;
  final bool hasPassenger;
  final double nextPassengerZ;
  final double dropoffZ;

  World3DRenderer({
    required this.vehicleX,
    required this.vehicleY,
    required this.vehicleZ,
    required this.speedKmh,
    required this.steerAngle,
    required this.wheelRotation,
    required this.rickshawRoll,
    required this.isRocketBoost,
    required this.thrusterGlow,
    required this.particles,
    required this.hasPassenger,
    required this.nextPassengerZ,
    required this.dropoffZ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double horizonY = h * 0.40;

    // --- 1. SKY & BANGLADESHI EVENING HORIZON ---
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF060B12), // Deep night sky
          Color(0xFF132238), // Electric dusk
          Color(0xFF263A48), // Dhaka city skyline haze
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, horizonY));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, horizonY), skyPaint);

    // Distant Dhaka City Skyline Silhouette
    _drawCitySkyline(canvas, w, horizonY);

    // --- 2. GROUND & ASPHALT STREET ---
    final groundPaint = Paint()..color = const Color(0xFF1E262B);
    canvas.drawRect(Rect.fromLTWH(0, horizonY, w, h - horizonY), groundPaint);

    // 3D Camera Settings (Third Person Spring Arm behind the rickshaw)
    final double camX = vehicleX * 0.75;
    final double camY = 2.4 + vehicleY * 0.5;
    final double camZ = vehicleZ - 5.0; // 5 meters behind vehicle
    final double fov = w * 0.85;

    Point2D? project(double wx, double wy, double wz) {
      double relX = wx - camX;
      double relY = wy - camY;
      double relZ = wz - camZ;
      if (relZ <= 0.2) return null; // Behind camera
      double scale = fov / relZ;
      return Point2D(w * 0.5 + relX * scale, horizonY - relY * scale, relZ);
    }

    // --- 3. DRAW 3D ROAD & PAVEMENT SEGMENTS ---
    final roadPaint = Paint()..color = const Color(0xFF2B3338);
    final curbPaintL = Paint()..color = const Color(0xFF3E4A52);
    final stripePaint = Paint()..color = Colors.amber.withValues(alpha: 0.85);

    double startZ = (vehicleZ / 5.0).floor() * 5.0;
    for (double z = startZ; z < startZ + 120.0; z += 5.0) {
      double z1 = z;
      double z2 = z + 5.0;

      // Road width is 8.0 meters (-4.0 to +4.0)
      var pL1 = project(-4.0, 0.0, z1);
      var pR1 = project(4.0, 0.0, z1);
      var pL2 = project(-4.0, 0.0, z2);
      var pR2 = project(4.0, 0.0, z2);

      if (pL1 != null && pR1 != null && pL2 != null && pR2 != null) {
        // Road surface quad
        Path roadPath = Path()
          ..moveTo(pL1.x, pL1.y)
          ..lineTo(pR1.x, pR1.y)
          ..lineTo(pR2.x, pR2.y)
          ..lineTo(pL2.x, pL2.y)
          ..close();
        canvas.drawPath(roadPath, roadPaint);

        // Curbs (left & right)
        canvas.drawLine(Offset(pL1.x, pL1.y), Offset(pL2.x, pL2.y), curbPaintL..strokeWidth = 3);
        canvas.drawLine(Offset(pR1.x, pR1.y), Offset(pR2.x, pR2.y), curbPaintL..strokeWidth = 3);

        // Dashed Lane Marking in Center (every other segment)
        if (((z / 5.0).floor() % 2) == 0) {
          var c1 = project(0.0, 0.02, z1);
          var c2 = project(0.0, 0.02, z2);
          if (c1 != null && c2 != null) {
            canvas.drawLine(
              Offset(c1.x, c1.y),
              Offset(c2.x, c2.y),
              stripePaint..strokeWidth = max(1.5, 30.0 / c1.depth),
            );
          }
        }
      }

      // Roadside Bangladeshi Elements (Chai Stalls, Palm Trees, Street Poles)
      _drawRoadsideEnvironment(canvas, z1, project);
    }

    // --- 4. ROADSIDE PASSENGERS & DESTINATION MARKERS ---
    _drawPassengerMarkers(canvas, project);

    // --- 5. ROCKET JET PARTICLES (Cyan Plasma Exhaust) ---
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      var proj = project(p.x, p.y, p.z);
      if (proj != null) {
        double radius = max(2.0, (12.0 / proj.depth) * (p.life / p.maxLife));
        particlePaint.color = const Color(0xFF00E5FF).withValues(alpha: (p.life / p.maxLife) * 0.85);
        canvas.drawCircle(Offset(proj.x, proj.y), radius, particlePaint);
      }
    }

    // --- 6. 3D BANGLA TESLA VEHICLE ---
    _drawBanglaTeslaRickshaw(canvas, project);
  }

  void _drawCitySkyline(Canvas canvas, double w, double horizonY) {
    final skylinePaint = Paint()..color = const Color(0xFF101924);
    double curX = 0;
    final Random r = Random(42);
    while (curX < w) {
      double bW = 20 + r.nextDouble() * 35;
      double bH = 25 + r.nextDouble() * 55;
      canvas.drawRect(Rect.fromLTWH(curX, horizonY - bH, bW, bH), skylinePaint);
      curX += bW + 4;
    }
  }

  void _drawRoadsideEnvironment(Canvas canvas, double z, Point2D? Function(double, double, double) project) {
    int idx = (z / 10.0).floor();

    // Left side: Chai Stalls ("টং দোকান") every 40 meters
    if (idx % 4 == 0) {
      var base = project(-5.5, 0.0, z);
      var roof = project(-5.5, 2.5, z);
      if (base != null && roof != null) {
        double sz = 60.0 / base.depth;
        // Stall body
        canvas.drawRect(
          Rect.fromCenter(center: Offset(base.x, (base.y + roof.y) * 0.5), width: sz * 1.5, height: sz * 1.2),
          Paint()..color = const Color(0xFF8D6E63),
        );
        // Colorful Rickshaw Art style striped awning
        canvas.drawRect(
          Rect.fromCenter(center: Offset(roof.x, roof.y), width: sz * 1.8, height: sz * 0.4),
          Paint()..color = Colors.redAccent,
        );
      }
    }

    // Right side: Streetlights with neon lamps
    if (idx % 2 == 1) {
      var poleBase = project(4.8, 0.0, z);
      var poleTop = project(4.8, 4.0, z);
      if (poleBase != null && poleTop != null) {
        canvas.drawLine(
          Offset(poleBase.x, poleBase.y),
          Offset(poleTop.x, poleTop.y),
          Paint()..color = Colors.grey.shade400..strokeWidth = max(1.5, 25.0 / poleBase.depth),
        );
        // Glowing street lamp
        canvas.drawCircle(
          Offset(poleTop.x, poleTop.y),
          max(3.0, 40.0 / poleBase.depth),
          Paint()..color = Colors.yellowAccent.withValues(alpha: 0.8),
        );
      }
    }
  }

  void _drawPassengerMarkers(Canvas canvas, Point2D? Function(double, double, double) project) {
    // 1. Pickup Marker (if looking for passenger)
    if (!hasPassenger) {
      var p = project(-3.2, 0.0, nextPassengerZ);
      if (p != null) {
        double size = max(8.0, 180.0 / p.depth);
        // Glowing waypoint beacon
        canvas.drawCircle(
          Offset(p.x, p.y),
          size * 1.4,
          Paint()..color = Colors.greenAccent.withValues(alpha: 0.35)..style = PaintingStyle.fill,
        );
        // Roadside Passenger Person
        canvas.drawCircle(Offset(p.x, p.y - size * 0.8), size * 0.35, Paint()..color = const Color(0xFFFDD835));
        canvas.drawRect(
          Rect.fromCenter(center: Offset(p.x, p.y - size * 0.35), width: size * 0.4, height: size * 0.6),
          Paint()..color = Colors.blueAccent,
        );
      }
    }
    // 2. Dropoff Marker (if passenger on board)
    else {
      var p = project(3.2, 0.0, dropoffZ);
      if (p != null) {
        double size = max(10.0, 220.0 / p.depth);
        // Target Drop-off ring
        canvas.drawCircle(
          Offset(p.x, p.y),
          size * 1.5,
          Paint()..color = Colors.amberAccent.withValues(alpha: 0.4)..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          Offset(p.x, p.y),
          size * 0.8,
          Paint()..color = Colors.amberAccent..style = PaintingStyle.stroke..strokeWidth = 3,
        );
      }
    }
  }

  void _drawBanglaTeslaRickshaw(Canvas canvas, Point2D? Function(double, double, double) project) {
    // Vehicle Center in world coordinates
    double vx = vehicleX;
    double vy = vehicleY;
    double vz = vehicleZ;

    // Local coordinates transformed into World coordinates
    Point2D? vproj(double lx, double ly, double lz) {
      // Apply banking roll around local Z axis
      double cosR = cos(rickshawRoll);
      double sinR = sin(rickshawRoll);
      double rx = lx * cosR - ly * sinR;
      double ry = lx * sinR + ly * cosR;

      return project(vx + rx, vy + ry, vz + lz);
    }

    // --- A. THREE WHEELS & ROCKET THRUSTERS ---
    // 1. Rear Left Wheel (lx = -0.55, lz = -0.45)
    _drawWheelAndThruster(canvas, vproj, -0.55, 0.35, -0.45, isSteerable: false);

    // 2. Rear Right Wheel (lx = 0.55, lz = -0.45)
    _drawWheelAndThruster(canvas, vproj, 0.55, 0.35, -0.45, isSteerable: false);

    // 3. Front Wheel (lx = 0.0, lz = 1.05) - Steerable
    _drawWheelAndThruster(canvas, vproj, 0.0, 0.35, 1.05, isSteerable: true);

    // --- B. RICKSHAW CARRIAGE & SEAT (Rich Hand-Painted Rickshaw Art) ---
    var seatBL = vproj(-0.52, 0.42, -0.55);
    var seatBR = vproj(0.52, 0.42, -0.55);
    var seatTR = vproj(0.52, 0.82, -0.55);
    var seatTL = vproj(-0.52, 0.82, -0.55);

    if (seatBL != null && seatBR != null && seatTR != null && seatTL != null) {
      // Traditional Ornate Rickshaw Art Backplate (Peacock & Flowers)
      Path artPlate = Path()
        ..moveTo(seatBL.x, seatBL.y)
        ..lineTo(seatBR.x, seatBR.y)
        ..lineTo(seatTR.x, seatTR.y)
        ..lineTo(seatTL.x, seatTL.y)
        ..close();

      // Rickshaw Crimson Red & Gold base
      canvas.drawPath(artPlate, Paint()..color = const Color(0xFFD32F2F));
      canvas.drawPath(artPlate, Paint()..color = Colors.amberAccent..style = PaintingStyle.stroke..strokeWidth = 3);

      // Inner floral medallion
      double centerX = (seatBL.x + seatBR.x) * 0.5;
      double centerY = (seatBL.y + seatTL.y) * 0.5;
      canvas.drawCircle(Offset(centerX, centerY), 12, Paint()..color = const Color(0xFF00E5FF));
      canvas.drawCircle(Offset(centerX, centerY), 6, Paint()..color = Colors.yellowAccent);
    }

    // --- C. ORNATE FOLDING CANOPY / HOOD ---
    var hoodBL = vproj(-0.54, 0.82, -0.58);
    var hoodBR = vproj(0.54, 0.82, -0.58);
    var hoodPeak = vproj(0.0, 1.65, -0.45);
    var hoodFront = vproj(0.0, 1.45, -0.15);

    if (hoodBL != null && hoodBR != null && hoodPeak != null && hoodFront != null) {
      // Curved hood canopy
      Path hoodPath = Path()
        ..moveTo(hoodBL.x, hoodBL.y)
        ..lineTo(hoodBR.x, hoodBR.y)
        ..lineTo(hoodPeak.x, hoodPeak.y)
        ..close();
      canvas.drawPath(hoodPath, Paint()..color = const Color(0xFF1B5E20)); // Traditional emerald green
      canvas.drawPath(hoodPath, Paint()..color = Colors.amber..style = PaintingStyle.stroke..strokeWidth = 2.5);

      // Decorative stripes
      canvas.drawLine(Offset(hoodBL.x, hoodBL.y), Offset(hoodPeak.x, hoodPeak.y), Paint()..color = Colors.yellow..strokeWidth = 2);
      canvas.drawLine(Offset(hoodBR.x, hoodBR.y), Offset(hoodPeak.x, hoodPeak.y), Paint()..color = Colors.yellow..strokeWidth = 2);
    }

    // --- D. CHASSIS FRAME TUBES & SADDLE ---
    var frameRear = vproj(0.0, 0.45, -0.3);
    var frameFront = vproj(0.0, 0.75, 0.75);
    if (frameRear != null && frameFront != null) {
      canvas.drawLine(
        Offset(frameRear.x, frameRear.y),
        Offset(frameFront.x, frameFront.y),
        Paint()..color = Colors.redAccent..strokeWidth = 5,
      );
    }

    // --- E. DRIVER (PULLER IN FRONT) ---
    var driverSeat = vproj(0.0, 0.72, 0.25);
    var driverHead = vproj(0.0, 1.25, 0.35);
    if (driverSeat != null && driverHead != null) {
      // Driver Body (Shirt)
      canvas.drawRect(
        Rect.fromCenter(center: Offset(driverSeat.x, (driverSeat.y + driverHead.y) * 0.5), width: 20, height: 26),
        Paint()..color = const Color(0xFFECEFF1),
      );
      // Driver Head & Cap
      canvas.drawCircle(Offset(driverHead.x, driverHead.y), 10, Paint()..color = const Color(0xFF8D6E63));
      canvas.drawRect(
        Rect.fromCenter(center: Offset(driverHead.x, driverHead.y - 4), width: 18, height: 7),
        Paint()..color = const Color(0xFF37474F), // Cap
      );
    }

    // Passenger seated in the back (if picked up)
    if (hasPassenger) {
      var passHead = vproj(0.15, 1.05, -0.45);
      if (passHead != null) {
        canvas.drawCircle(Offset(passHead.x, passHead.y), 9, Paint()..color = const Color(0xFFFFCC80));
        canvas.drawRect(
          Rect.fromCenter(center: Offset(passHead.x, passHead.y + 12), width: 18, height: 20),
          Paint()..color = Colors.teal,
        );
      }
    }
  }

  void _drawWheelAndThruster(
    Canvas canvas,
    Point2D? Function(double, double, double) vproj,
    double lx,
    double ly,
    double lz, {
    required bool isSteerable,
  }) {
    var center = vproj(lx, ly, lz);
    var bottom = vproj(lx, 0.05, lz);
    if (center == null || bottom == null) return;

    double radius = (center.y - bottom.y).abs();
    if (radius < 2.0) radius = 8.0;

    // 1. Wheel Rim & Tire
    canvas.drawCircle(
      Offset(center.x, center.y),
      radius,
      Paint()..color = const Color(0xFF212121)..style = PaintingStyle.stroke..strokeWidth = 3,
    );
    canvas.drawCircle(
      Offset(center.x, center.y),
      radius * 0.75,
      Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );

    // Spokes (rotate with speed)
    for (int i = 0; i < 4; i++) {
      double a = wheelRotation + (i * pi / 4.0);
      canvas.drawLine(
        Offset(center.x + cos(a) * radius * 0.7, center.y + sin(a) * radius * 0.7),
        Offset(center.x - cos(a) * radius * 0.7, center.y - sin(a) * radius * 0.7),
        Paint()..color = Colors.white54..strokeWidth = 1.2,
      );
    }

    // 2. Rocket Thruster Nozzle & Cyan Plasma Exhaust
    var nozzle = vproj(lx, -0.05, lz);
    if (nozzle != null) {
      // Chrome Nozzle Cup
      canvas.drawRect(
        Rect.fromCenter(center: Offset(nozzle.x, nozzle.y), width: radius * 0.65, height: 6),
        Paint()..color = Colors.grey.shade400,
      );

      // Cyan Rocket Plasma Thrust Beam (firing downwards towards the street)
      if (isRocketBoost || thrusterGlow > 0.05) {
        double flameHeight = (30.0 + sin(wheelRotation * 4.0) * 8.0) * thrusterGlow;
        Path flame = Path()
          ..moveTo(nozzle.x - radius * 0.35, nozzle.y + 3)
          ..lineTo(nozzle.x + radius * 0.35, nozzle.y + 3)
          ..lineTo(nozzle.x, nozzle.y + 3 + flameHeight)
          ..close();

        // Intense Cyan Plasma Core with outer glow
        canvas.drawPath(
          flame,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                const Color(0xFF00E5FF),
                const Color(0xFF00E5FF).withValues(alpha: 0.0),
              ],
            ).createShader(Rect.fromLTWH(nozzle.x - 15, nozzle.y, 30, flameHeight)),
        );

        // Ground plasma burn circle on road
        var groundHit = vproj(lx, -0.4, lz);
        if (groundHit != null) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(groundHit.x, groundHit.y), width: radius * 1.4, height: 6),
            Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.45 * thrusterGlow),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant World3DRenderer oldDelegate) => true;
}

class Point2D {
  final double x;
  final double y;
  final double depth;
  Point2D(this.x, this.y, this.depth);
}
