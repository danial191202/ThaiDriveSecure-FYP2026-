import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thaidrivesecure/payment/payment_page.dart';

class CompInsSubmit extends StatefulWidget {
  final Map<String, dynamic> formData;
  final String vehicleGrantPath;
  final List<String> passportPaths;

  const CompInsSubmit({
    super.key,
    required this.formData,
    required this.vehicleGrantPath,
    required this.passportPaths,
  });

  @override
  State<CompInsSubmit> createState() => _CompInsSubmitState();
}

class _CompInsSubmitState extends State<CompInsSubmit> {
  String selectedDelivery = "Take Away";
  bool isSubmitting = false;

  // ================= DATA =================
  String get fullName => widget.formData['name'] ?? "-";
  String get phone => widget.formData['phone'] ?? "-";
  String get borderRoute => widget.formData['where'] ?? "-";

  DateTime get departDate =>
      widget.formData['departDate'] ?? DateTime.now();

  DateTime get returnDate =>
      widget.formData['returnDate'] ??
      DateTime.now().add(const Duration(days: 1));

  int get passengers => widget.formData['passengers'] ?? 1;
  String get durationLabel => widget.formData['duration'] ?? "9 Days";
  String get vehicleType => widget.formData['vehicleType'] ?? 'Sedan';

  // ================= PRICE =================
  int get insurancePrice => 25;
  int get tdacPrice => passengers * 2;
  int get tm23Price => 8;

  double get totalPrice =>
      (insurancePrice + tdacPrice + tm23Price).toDouble();

  // ================= CHECKOUT =================
  Future<void> checkout() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final orderRef =
          FirebaseFirestore.instance.collection('orders').doc();

      final orderId = orderRef.id;
      final now = Timestamp.now();

      await orderRef.set({
        "orderId": orderId,

        "customer": {
          "name": fullName,
          "phone": phone,
          "userId": user.uid,
        },

        "trip": {
          "vehicleType": vehicleType,
          "borderRoute": borderRoute,
          "travelDay":
              "${_formatDate(departDate)} - ${_formatDate(returnDate)} ($durationLabel)",
          "passengers": passengers,
        },

        "package": {
          "selected": ["Insurance Compulsory", "TM2/3", "TDAC"],
        },

        "pricing": {
          "insurancePrice": insurancePrice,
          "tdacPrice": tdacPrice,
          "tm23Price": tm23Price,
          "totalPrice": totalPrice,
        },

        "documents": {
          "passportUrls": widget.passportPaths,
          "vehicleGrantUrl": widget.vehicleGrantPath,
        },

        "payment": {
          "method": "QR / Receipt Upload",
          "status": "Pending",
          "receiptUrl": null,
          "receiptFileName": null,
          "uploadedAt": null,
          "confirmedAt": null,
        },

        "delivery": {
          "method": selectedDelivery,
        },

        "status": {
          "current": "Order Pending",
          "history": [
            {
              "step": "Order Pending",
              "completed": true,
              "time": now,
            },
            {
              "step": "Order Received",
              "completed": false,
            },
            {
              "step": "In Process",
              "completed": false,
            },
            {
              "step": "On The Way",
              "completed": false,
            },
            {
              "step": "Already Pickup",
              "completed": false,
            }
          ]
        },

        "createdAt": now,
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            vehicleType: vehicleType,
            packageType: "Compulsory",
            orderId: orderId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Order Review",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _orderReviewCard(),
            const Spacer(),

            // ✅ FIXED BUTTON STYLE
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF163B6D),
                ),
                onPressed: isSubmitting ? null : checkout,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Checkout >",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CARD =================
  Widget _orderReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("Name", fullName),
          _infoRow("Phone", phone),
          _infoRow("Where", borderRoute),
          _infoRow("Vehicle", vehicleType),
          _infoRow(
            "When",
            "${_formatDate(departDate)} - ${_formatDate(returnDate)} ($durationLabel)",
          ),
          _infoRow("Passengers", passengers.toString()),

          const Divider(height: 24),

          const Text(
            "1. Insurance Compulsory\n2. TM2/3\n3. TDAC",
          ),

          const Divider(height: 24),

          _priceRow("Insurance Compulsory", insurancePrice),
          _priceRow("TM2/3", tm23Price),
          _priceRow("TDAC", tdacPrice),

          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Price",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                "RM $totalPrice",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, int price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text("RM $price")],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}