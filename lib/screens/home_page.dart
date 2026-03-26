import 'dart:async';
import 'package:flutter/material.dart';

// Pages
import 'package:thaidrivesecure/pages/volu/voluIns_page.dart';
import 'package:thaidrivesecure/pages/comp/compIns_page.dart';
import 'package:thaidrivesecure/screens/status_page.dart';
import 'package:thaidrivesecure/screens/history_page.dart';
import 'package:thaidrivesecure/screens/setting_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentSlide = 0;
  Timer? _timer;

  int _selectedIndex = 0;

  final List<String> promoImages = [
    "assets/promo1.jpg",
    "assets/promo2.jpg",
    "assets/promo3.jpg",
    "assets/promo4.jpg",
  ];

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_pageController.hasClients) return;

      _currentSlide = (_currentSlide + 1) % promoImages.length;

      _pageController.animateToPage(
        _currentSlide,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Home Page", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      bottomNavigationBar: bottomNav(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= PROMOTION =================
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                itemCount: promoImages.length,
                itemBuilder: (context, index) {
                  return PromotionCard(imagePath: promoImages[index]);
                },
              ),
            ),

            const SizedBox(height: 24),

            // ================= COMPULSORY =================
            sectionTitle("Compulsory Package"),
            const SizedBox(height: 12),
            packageCompulsorySlider(),

            const SizedBox(height: 24),

            // ================= COMPULSORY + VOLUNTARY =================
            sectionTitle("Compulsory & Voluntary Package"),
            const SizedBox(height: 12),
            packageCompulsoryVoluntarySlider(),

            const SizedBox(height: 24),

            // ================= VOLUNTARY+ =================
            sectionTitle("Compulsory & Voluntary+ Package"),
            const SizedBox(height: 12),
            packageCompulsoryVoluntaryPlusSlider(),

            const SizedBox(height: 24),

            // ================= INFO =================
            infoCard(
              title: "What we need?",
              description:
                  "To travel to Thailand from Malaysia, you need a valid passport, vehicle documents and insurance.",
              imagePath: "assets/need.png",
            ),

            infoCard(
              title: "Where we're located?",
              description:
                  "The map helps you see where we’re located and makes it easy to find us.",
              imagePath: "assets/map.png",
            ),

            infoCard(
              title: "Learn more about us",
              description:
                  "Learn more about our website, services and how we can help you.",
              imagePath: "assets/web.png",
            ),
          ],
        ),
      ),
    );
  }

  // ================= PACKAGE SLIDER =================

  Widget packageCompulsorySlider() {
    final packages = [
      {"title": "Sedan", "vehicleType": "Sedan"},
      {"title": "Pickup/SUV", "vehicleType": "Pickup/SUV"},
      {"title": "MPV", "vehicleType": "MPV"},
      {"title": "Motorcycle", "vehicleType": "Motorcycle"},
    ];

    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final package = packages[index];
          final title = package["title"]!;
          final vehicleType = package["vehicleType"]!;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompIns(vehicleType: vehicleType),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    getVehicleIcon(title),
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget packageCompulsoryVoluntarySlider() {
    final packages = [
      {"title": "Sedan", "vehicleType": "Sedan"},
      {"title": "Pickup/SUV", "vehicleType": "Pickup/SUV"},
      {"title": "MPV", "vehicleType": "MPV"},
      {"title": "Motorcycle", "vehicleType": "Motorcycle"},
    ];

    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final package = packages[index];
          final title = package["title"]!;
          final vehicleType = package["vehicleType"]!;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VoluIns(vehicleType: vehicleType),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    getVehicleIcon(title),
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget packageCompulsoryVoluntaryPlusSlider() {
    final packages = [
      {"title": "Sedan", "vehicleType": "Sedan"},
      {"title": "Pickup/SUV", "vehicleType": "Pickup/SUV"},
      {"title": "MPV", "vehicleType": "MPV"},
      {"title": "Motorcycle", "vehicleType": "Motorcycle"},
    ];

    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final package = packages[index];
          final title = package["title"]!;
          final vehicleType = package["vehicleType"]!;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompIns(vehicleType: vehicleType),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    getVehicleIcon(title),
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= ICON =================

  String getVehicleIcon(String type) {
    switch (type) {
      case "Sedan":
        return "assets/sedan1.png";
      case "Pickup/SUV":
        return "assets/suv.png";
      case "MPV":
        return "assets/mpv.png";
      case "Motorcycle":
        return "assets/motorcycle.png";
      default:
        return "assets/sedan1.png";
    }
  }

  // ================= UI HELPERS =================

  Widget sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget infoCard({
    required String title,
    required String description,
    required String imagePath,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black26),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(imagePath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  // ================= BOTTOM NAV =================

  Widget bottomNav() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF163B6D),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (index == _selectedIndex) return;

        setState(() {
          _selectedIndex = index;
        });

        switch (index) {
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatusPage()),
            );
            break;

          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            );
            break;

          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle),
          label: "Status",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Setting"),
      ],
    );
  }
}

class PromotionCard extends StatelessWidget {
  final String imagePath;

  const PromotionCard({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
    );
  }
}
