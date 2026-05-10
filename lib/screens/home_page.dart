import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:thaidrivesecure/addOn/map_launcher.dart';
import 'package:thaidrivesecure/addOnServices/Adapter.dart';
import 'package:thaidrivesecure/addOnServices/authorizeLetter.dart';
import 'package:thaidrivesecure/addOnServices/sim.dart';
import 'package:thaidrivesecure/addOnServices/tdac.dart';
import 'package:thaidrivesecure/addOnServices/tm23.dart';
import 'package:thaidrivesecure/addOnServices/towing.dart';

// Pages
import 'package:thaidrivesecure/screens/needs.dart';
import 'package:thaidrivesecure/pages/volu/voluIns_page.dart';
import 'package:thaidrivesecure/pages/comp/compIns_page.dart';
import 'package:thaidrivesecure/screens/status_page.dart';
import 'package:thaidrivesecure/history/history_page.dart';
import 'package:thaidrivesecure/screens/setting_page.dart';
import 'package:thaidrivesecure/pages/voluPlus/voluPlusIns_page.dart';

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
  String? selectedAddon;

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

  static final Uri _learnMoreWebsite = Uri.parse(
    'https://intis2ar-ux.github.io/thaidrivesecure-Website/',
  );

  Future<void> _openLearnMoreWebsite() async {
    try {
      await launchUrl(_learnMoreWebsite, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open website: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          "assets/tsdLogoPjg.png", // 🔥 change to your logo file
          height: 40,
        ),
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

            // ================= ADD ON SERVICES =================
            sectionTitle("Add On Services"),
            const SizedBox(height: 12),
            addOnServicesSlider(),

            const SizedBox(height: 24),

            // ================= INFO =================
            GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WhatWeNeedPage(),
                ),
              );
            },
            child: infoCard(
              title: "What we need?",
              description:
                  "To travel to Thailand from Malaysia, you need a valid passport, vehicle documents and insurance.",
              imagePath: "assets/need.png",
            ),
          ),

            GestureDetector(
              onTap: MapLauncher.openGoogleMaps,
              child: infoCard(
                title: "Where we're located?",
                description:
                    "The map helps you see where we’re located and makes it easy to find us.",
                imagePath: "assets/map.png",
              ),
            ),

            GestureDetector(
              onTap: _openLearnMoreWebsite,
              child: infoCard(
                title: "Learn more about us",
                description:
                    "Learn more about our website, services and how we can help you.",
                imagePath: "assets/web.png",
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= COMPULSORY =================
  Widget packageCompulsorySlider() {
    final packages = [
      {
        "title": "Sedan",
        "vehicleType": "Sedan",
        "image": "assets/1sedan.png",
      },
      {
        "title": "Pickup/SUV",
        "vehicleType": "Pickup/SUV",
        "image": "assets/1suv.png",
      },
      {
        "title": "MPV",
        "vehicleType": "MPV",
        "image": "assets/1mpv.png",
      },
      {
        "title": "Motorcycle",
        "vehicleType": "Motorcycle",
        "image": "assets/1motorcycle.png",
      },
    ];

    return buildVehicleSlider(
      packages: packages,
      borderColor: const Color(0xFF10AAA2), // Teal
      onTapBuilder: (vehicleType) => CompIns(vehicleType: vehicleType),
    );
  }

  // ================= VOLUNTARY =================
  Widget packageCompulsoryVoluntarySlider() {
    final packages = [
      {
        "title": "Sedan",
        "vehicleType": "Sedan",
        "image": "assets/2sedan.png",
      },
      {
        "title": "Pickup/SUV",
        "vehicleType": "Pickup/SUV",
        "image": "assets/2suv.png",
      },
      {
        "title": "MPV",
        "vehicleType": "MPV",
        "image": "assets/2mpv.png",
      },
      {
        "title": "Motorcycle",
        "vehicleType": "Motorcycle",
        "image": "assets/2motorcycle.png",
      },
    ];

    return buildVehicleSlider(
      packages: packages,
      borderColor: const Color(0xFFF5851E), // Orange
      onTapBuilder: (vehicleType) => VoluIns(vehicleType: vehicleType),
    );
  }

  // ================= VOLUNTARY PLUS =================
  Widget packageCompulsoryVoluntaryPlusSlider() {
    final packages = [
      {
        "title": "Sedan",
        "vehicleType": "Sedan",
        "image": "assets/3sedan.png",
      },
      {
        "title": "Pickup/SUV",
        "vehicleType": "Pickup/SUV",
        "image": "assets/3suv.png",
      },
      {
        "title": "MPV",
        "vehicleType": "MPV",
        "image": "assets/3mpv.png",
      },
      {
        "title": "Motorcycle",
        "vehicleType": "Motorcycle",
        "image": "assets/3motorcycle.png",
      },
    ];

    return buildVehicleSlider(
      packages: packages,
      borderColor: const Color(0xFFE63545), // Red
      onTapBuilder: (vehicleType) => VoluPlusIns(vehicleType: vehicleType),
    );
  }

  // ================= ADD ON SERVICES =================
  Widget addOnServicesSlider() {
    final Color lightBlue = const Color(0xFFCBD8F8);
    final services = [
      {
        "title": "Adapter",
        "image": "assets/adapter.png",
        "price": "RM9",
        "page": const Adapter(),
      },
      {
        "title": "Authorize Letter",
        "image": "assets/authorizeLetter.png",
        "price": "RM5",
        "page": const AuthorizeLetter(),
      },
      {
        "title": "SIM",
        "image": "assets/simCard.png",
        "price": "RM29",
        "page": const Sim(),
      },
      {
        "title": "TDAC",
        "image": "assets/TDAC.png",
        "price": "RM2",
        "page": const Tdac(),
      },
      {
        "title": "TM2/3",
        "image": "assets/TM23.png",
        "price": "RM8",
        "page": const Tm23(),
      },
      {
        "title": "Towing",
        "image": "assets/towing.png",
        "price": "RM19",
        "page": const Towing(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.84,
      ),
      itemBuilder: (context, index) {
        final item = services[index];
        final String itemName = item["title"]! as String;
        final bool selected = selectedAddon == itemName;
        final Widget targetPage = item["page"]! as Widget;

        return GestureDetector(
          onTap: () {
            if (selectedAddon == itemName) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => targetPage,
                ),
              );
              return;
            }
            setState(() {
              selectedAddon = itemName;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: selected
                ? Matrix4.translationValues(0, -6, 0)
                : Matrix4.identity(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.green : lightBlue,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 38,
                  child: Image.asset(
                    item["image"]! as String,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  itemName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "from ${item["price"]}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white70 : Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= REUSABLE VEHICLE SLIDER =================
  Widget buildVehicleSlider({
    required List<Map<String, String>> packages,
    required Color borderColor,
    required Widget Function(String vehicleType) onTapBuilder,
  }) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final package = packages[index];
          final vehicleType = package["vehicleType"]!;
          final imagePath = package["image"]!;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => onTapBuilder(vehicleType),
                ),
              );
            },
            child: pictureOnlyVehicleCard(
              imagePath: imagePath,
              borderColor: borderColor,
            ),
          );
        },
      ),
    );
  }

  // ================= PICTURE ONLY CARD =================
  Widget pictureOnlyVehicleCard({
    required String imagePath,
    required Color borderColor,
  }) {
    return Container(
      width: 180,
      height: 110,
      margin: const EdgeInsets.only(right: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  // ================= UI HELPERS =================
  Widget sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
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

// ================= PROMO CARD =================
class PromotionCard extends StatelessWidget {
  final String imagePath;

  const PromotionCard({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }
}