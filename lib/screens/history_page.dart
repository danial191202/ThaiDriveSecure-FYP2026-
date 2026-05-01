import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  /// ✅ Default tab = Pending
  String selectedTab = "Pending";

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return "$d/$m/$y";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

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
      body: currentUser == null
          ? const Center(
              child: Text(
                "Please log in to view your order history.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
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
                        buildTab("Pending"),
                        buildTab("Completed"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// FIRESTORE CARD LIST
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders') // ✅ CHANGED
                        .where('userId', isEqualTo: currentUser.uid)
                        .orderBy('createdAt', descending: true) // ✅ NEWEST FIRST
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error loading history:\n${snapshot.error}",
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No previous orders found.",
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      final docs = [...snapshot.data!.docs]
                        ..sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final aCreated = _toDateTime(aData['createdAt']) ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          final bCreated = _toDateTime(bData['createdAt']) ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          return bCreated.compareTo(aCreated);
                        });

                      /// ✅ Filter by selected tab using NEW status field
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status =
                            _mapFirestoreStatusToTab(data['status']);
                        return status == selectedTab;
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Text(
                            "No $selectedTab orders found.",
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final item = filteredDocs[index].data()
                              as Map<String, dynamic>;
                          return buildHistoryCard(item);
                        },
                      );
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

  /// ================= STATUS MAPPER =================
  String _mapFirestoreStatusToTab(String? status) {
    if (status == null) return "Pending";

    switch (status.toLowerCase()) {
      case "order pending":
      case "pending":
      case "pending verification":
      case "payment submitted":
        return "Pending";

      case "already pickup":
      case "completed":
      case "verified":
        return "Completed";

      default:
        return "Pending";
    }
  }

  /// ================= PACKAGE NAME BUILDER =================
  String _buildPackageName(List<dynamic>? selectedItems) {
    if (selectedItems == null || selectedItems.isEmpty) {
      return "Insurance Package";
    }

    return selectedItems.join(", ");
  }

  /// ================= CARD =================
  Widget buildHistoryCard(Map<String, dynamic> item) {
    final String firestoreStatus = item["status"] ?? "Order Pending";
    final String status = _mapFirestoreStatusToTab(firestoreStatus);

    Color badgeColor;
    Color badgeTextColor;

    if (status == "Pending") {
      badgeColor = const Color(0xFFFCE8B2);
      badgeTextColor = const Color(0xFFD39E00);
    } else {
      badgeColor = const Color(0xFFBDEEE8);
      badgeTextColor = const Color(0xFF2C9C8D);
    }

    String buttonText = status == "Pending" ? "View Order" : "View Receipt";

    final List<dynamic> selectedItems = item["selectedItems"] ?? [];
    final String packageName = _buildPackageName(selectedItems);
    final String orderId = item["orderId"] ?? "TDS-000";
    final double totalPrice =
        double.tryParse((item["totalAmount"] ?? item["totalPrice"] ?? 0).toString()) ?? 0.0;
    final int duration = (item["duration"] ?? item["travel"]?["duration"] ?? item["travel"]?["days"] ?? 0) is int
        ? (item["duration"] ?? item["travel"]?["duration"] ?? item["travel"]?["days"] ?? 0) as int
        : int.tryParse((item["duration"] ?? item["travel"]?["duration"] ?? item["travel"]?["days"] ?? 0).toString()) ?? 0;
    final String deliveryMethod = (item["deliveryMethod"] ??
            item["delivery"]?["method"] ??
            "-")
        .toString();
    final DateTime? startDate =
        _toDateTime(item["startDate"] ?? item["travel"]?["departDate"]);
    final DateTime? endDate =
        _toDateTime(item["endDate"] ?? item["travel"]?["returnDate"]);
    final String dateRangeText =
        "${_formatDate(startDate)} - ${_formatDate(endDate)}";

    String dateText = "-";
    final createdAt = item["createdAt"];
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      dateText =
          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
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
                "Order $orderId",
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
                  packageName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                dateText,
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
                "$duration Days",
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(width: 32),
              const Icon(Icons.receipt_long, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                deliveryMethod,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// ICON ROW 2
          Row(
            children: [
              const Icon(Icons.description, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                dateRangeText,
                style: const TextStyle(color: Colors.black54),
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
                "RM ${totalPrice.toStringAsFixed(2)}",
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
                  // TODO: later add navigation
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