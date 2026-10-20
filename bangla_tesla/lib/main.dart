import 'package:flutter/material.dart';
import 'screens/game_screen.dart';
import 'screens/garage_screen.dart';

void main() {
  runApp(const BanglaTeslaApp());
}

class BanglaTeslaApp extends StatelessWidget {
  const BanglaTeslaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bangla Tesla 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Colors.amber,
          surface: Color(0xFF141C28),
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  int _totalFares = 350; // Starting virtual Taka

  void _addFare(int amount) {
    setState(() {
      _totalFares += amount;
    });
  }

  void _spendFare(int cost) {
    setState(() {
      _totalFares -= cost;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      GameScreen(onFareEarned: _addFare),
      GarageScreen(totalFares: _totalFares, onSpendFare: _spendFare),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF101722),
        indicatorColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports, color: Color(0xFF00E5FF)),
            label: 'ড্রাইভিং মোড (Drive)',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build, color: Colors.amberAccent),
            label: 'গ্যারেজ (Garage)',
          ),
        ],
      ),
    );
  }
}
