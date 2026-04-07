import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedTab = "Applied";

  final List<Map<String, dynamic>> historyData = [
    {
      "orderId": "#001",
      "package": "Package Compulsory (Sedan)",
      "date": "26/06/2026",
      "duration": "7 Days",
      "hasTDAC": true,
      "hasTM": true,
      "price": "RM35",
      "status": "Applied",
    },
    {
      "orderId": "#002",
      "package": "Package Compulsory (Sedan)",
      "date": "30/06/2026",
      "duration": "10 Days",
      "hasTDAC": true,
      "hasTM": true,
      "price": "RM45",
      "status": "Applied",
    },
    {
      "orderId": "#003",
      "package": "Package Compulsory (Sedan)",
      "date": "26/06/2026",
      "duration": "7 Days",
      "hasTDAC": true,
      "hasTM": true,
      "price": "RM35",
      "status": "Pending",
    },
    {
      "orderId": "#004",
      "package": "Package Compulsory (Sedan)",
      "date": "26/06/2026",
      "duration": "7 Days",
      "hasTDAC": true,
      "hasTM": true,
      "price": "RM35",
      "status": "Completed",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredData = historyData
        .where((item) => item["status"] == selectedTab)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163B6D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Application History",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 14),

          /// TOP TAB BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  buildTab("Applied"),
                  buildTab("Pending"),
                  buildTab("Completed"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          /// CARD LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                final item = filteredData[index];
                return buildHistoryCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= TAB =================
  Widget buildTab(String label) {
    final bool isSelected = selectedTab == label;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = label;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF163B6D) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= CARD =================
  Widget buildHistoryCard(Map<String, dynamic> item) {
    final String status = item["status"];
    Color badgeColor;
    Color badgeTextColor;

    if (status == "Applied") {
      badgeColor = const Color(0xFFF8CACA);
      badgeTextColor = const Color(0xFFD9534F);
    } else if (status == "Pending") {
      badgeColor = const Color(0xFFFCE8B2);
      badgeTextColor = const Color(0xFFD39E00);
    } else {
      badgeColor = const Color(0xFFBDEEE8);
      badgeTextColor = const Color(0xFF2C9C8D);
    }

    String buttonText;
    if (status == "Applied") {
      buttonText = "Complete Payment";
    } else if (status == "Pending") {
      buttonText = "View Order";
    } else {
      buttonText = "View Receipt";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.red.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order ${item["orderId"]}",
                style: const TextStyle(
                  color: Color(0xFF163B6D),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// PACKAGE + DATE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item["package"],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                item["date"],
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// ICON ROW 1
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                item["duration"],
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(width: 32),
              const Icon(Icons.receipt_long, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                "TDAC",
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// ICON ROW 2
          const Row(
            children: [
              Icon(Icons.description, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                "TM2/TM3 Documents",
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),

          /// PRICE + BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item["price"],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF163B6D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // TODO: later add action
                },
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}