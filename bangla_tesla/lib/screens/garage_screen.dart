import 'package:flutter/material.dart';

/// Garage and Upgrades Shop for Bangla Tesla.
/// Allows upgrading thrusters, battery capacity, horn, and selecting Rickshaw Art paint styles.
class GarageScreen extends StatefulWidget {
  final int totalFares;
  final Function(int cost) onSpendFare;

  const GarageScreen({
    super.key,
    required this.totalFares,
    required this.onSpendFare,
  });

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  int thrusterLevel = 1;
  int batteryLevel = 1;
  int bellLevel = 1;
  String selectedSkin = "ঐতিহ্যবাহী লাল-সবুজ (Classic Dhaka)";

  final List<String> availableSkins = [
    "ঐতিহ্যবাহী লাল-সবুজ (Classic Dhaka)",
    "সাইবারপাঙ্ক নিয়ন ব্লু (Cyber Neon)",
    "পদ্মা রূপালী ইলিশ (Padma Silver)",
    "সোনার বাংলা গোল্ডেন (Golden Bengal)",
  ];

  void _upgrade(String item, int cost, VoidCallback onSuccess) {
    if (widget.totalFares >= cost) {
      widget.onSpendFare(cost);
      setState(onSuccess);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("🎉 $item সফলভাবে আপগ্রেড করা হয়েছে! (-৳$cost)"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("❌ পর্যাপ্ত ভাড়া নেই! আরো যাত্রী আনা-নেওয়া করুন। (প্রয়োজন: ৳$cost)"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161F2E),
        elevation: 0,
        title: const Text(
          "বাংলা টেসলা গ্যারেজ (GARAGE & UPGRADES)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF003B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  "৳ ${widget.totalFares}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3D Model Asset Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2A3C), Color(0xFF101722)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyan.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/reference/bangla_tesla_concept.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "বাংলা টেসলা ৩-হুইলার রকেট",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "• ট্রিপল সায়ান প্লাজমা থ্রাস্টার\n• আসল হাতে আঁকা রিকশা আর্ট\n• ইউনিটি ৩ডি ফিজিক্স রেডি",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "গাড়ির পারফরম্যান্স আপগ্রেড",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 1. Rocket Thruster Boost
            _buildUpgradeCard(
              title: "সায়ান প্লাজমা রকেট থ্রাস্টার",
              subtitle: "হভার স্পিড: ${65 + thrusterLevel * 15} km/h (লেভেল $thrusterLevel/5)",
              icon: Icons.rocket_launch,
              iconColor: const Color(0xFF00E5FF),
              cost: 150 * thrusterLevel,
              onUpgrade: () {
                _upgrade("রকেট থ্রাস্টার", 150 * thrusterLevel, () {
                  thrusterLevel++;
                });
              },
            ),

            // 2. Battery Capacity
            _buildUpgradeCard(
              title: "টেসলা লিথিয়াম আয়ন ব্যাটারি",
              subtitle: "হভার ডিউরেশন: ${30 + batteryLevel * 10} সেকেন্ড (লেভেল $batteryLevel/5)",
              icon: Icons.battery_charging_full,
              iconColor: Colors.greenAccent,
              cost: 100 * batteryLevel,
              onUpgrade: () {
                _upgrade("ব্যাটারি", 100 * batteryLevel, () {
                  batteryLevel++;
                });
              },
            ),

            // 3. Melodic Bell
            _buildUpgradeCard(
              title: "ট্রিং ট্রিং সুপার হর্ন",
              subtitle: "রাস্তার ট্রাফিক সাইড করার ক্ষমতা (লেভেল $bellLevel/3)",
              icon: Icons.notifications_active,
              iconColor: Colors.amberAccent,
              cost: 50 * bellLevel,
              onUpgrade: () {
                _upgrade("হর্ন", 50 * bellLevel, () {
                  bellLevel++;
                });
              },
            ),

            const SizedBox(height: 24),
            const Text(
              "রিকশা আর্ট পেইন্ট ও ডিজাইন",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Rickshaw Art selector
            ...availableSkins.map((skin) {
              bool isSelected = selectedSkin == skin;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E3A3A) : const Color(0xFF141C28),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.cyanAccent : Colors.white12,
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.palette,
                    color: isSelected ? Colors.cyanAccent : Colors.white54,
                  ),
                  title: Text(
                    skin,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.cyanAccent)
                      : const Text("প্রয়োগ করুন", style: TextStyle(color: Colors.white38, fontSize: 12)),
                  onTap: () {
                    setState(() => selectedSkin = skin);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required int cost,
    required VoidCallback onUpgrade,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141C28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onUpgrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              "৳ $cost",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
