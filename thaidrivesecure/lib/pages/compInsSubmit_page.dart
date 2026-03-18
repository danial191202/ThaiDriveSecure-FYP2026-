import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:thaidrivesecure/payment/payment_page.dart';

class CompInsSubmitPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final String vehicleGrantPath;
  final List<String> passportPaths;

  const CompInsSubmitPage({
    super.key,
    required this.formData,
    required this.vehicleGrantPath,
    required this.passportPaths,
  });

  @override
  State<CompInsSubmitPage> createState() => _CompInsSubmitPageState();
}

class _CompInsSubmitPageState extends State<CompInsSubmitPage> {
  String selectedDelivery = "Take Away";
  bool isSubmitting = false;

  // ================= PRICE CALCULATION =================
  int get insurancePrice => widget.formData['insurancePrice'] ?? 25;
  int get tdacPrice => widget.formData['tdacPrice'] ?? 2;
  int get tm23Price => 8;

  int get totalPrice => insurancePrice + tdacPrice + tm23Price;

  // ================= DATE FORMATTER =================
  String formatWhenDisplay(String raw) {
    try {
      final parts = raw.split('|');

      final inPart = parts[0].replaceAll("In:", "").trim();
      final outPart =
          parts[1].split('(')[0].replaceAll("Out:", "").trim();

      DateTime inDate = _parseDate(inPart);
      DateTime outDate = _parseDate(outPart);

      return "${_formatDate(inDate)} – ${_formatDate(outDate, withYear: true)}";
    } catch (_) {
      return raw;
    }
  }

  DateTime _parseDate(String date) {
    final parts = date.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  String _formatDate(DateTime date, {bool withYear = false}) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];

    return withYear
        ? "${date.day} ${months[date.month - 1]} ${date.year}"
        : "${date.day} ${months[date.month - 1]}";
  }

  // ================= IMAGE UPLOAD =================
  Future<String> _uploadImage(File file, String storagePath) async {
    final ref = FirebaseStorage.instance.ref().child(storagePath);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // ================= CHECKOUT =================
  Future<void> checkout() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final orderRef =
          FirebaseFirestore.instance.collection('insurance_orders').doc();

      final orderId = orderRef.id;

      final vehicleGrantUrl = await _uploadImage(
        File(widget.vehicleGrantPath),
        "insurance_orders/$orderId/vehicle_grant.jpg",
      );

      List<String> passportUrls = [];

      for (int i = 0; i < widget.passportPaths.length; i++) {
        final url = await _uploadImage(
          File(widget.passportPaths[i]),
          "insurance_orders/$orderId/passport_${i + 1}.jpg",
        );
        passportUrls.add(url);
      }

      await orderRef.set({
        'orderId': orderId,
        'userId': user.uid,
        ...widget.formData,
        'insurancePrice': insurancePrice,
        'tdacPrice': tdacPrice,
        'tm23Price': tm23Price,
        'totalPrice': totalPrice,
        'deliveryMethod': selectedDelivery,
        'documents': {
          'vehicleGrantUrl': vehicleGrantUrl,
          'passportUrls': passportUrls,
        },
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaymentPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Submission failed: $e")));
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

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF163B6D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting ? null : checkout,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Checkout >",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ORDER REVIEW CARD =================
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

          _infoRow("Name", widget.formData['name']),
          _infoRow("No.Telephone", widget.formData['phone']),
          _infoRow("Where", widget.formData['where']),
          _infoRow("When", widget.formData['when']),
          _infoRow(
              "Passenger", widget.formData['passengers'].toString()),

          const Divider(height: 24),

          Text(
            "1. Insurance Compulsory (${widget.formData['duration']})\n"
            "2. TM2/3\n"
            "3. TDAC",
          ),

          const Divider(height: 24),

          _priceRow(
            "Insurance Compulsory (${widget.formData['duration']})",
            insurancePrice,
          ),

          _priceRow("TM2/3", tm23Price),

          _priceRow(
            "TDAC (RM2 × ${widget.formData['passengers']})",
            tdacPrice,
          ),

          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Price",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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

  // ================= HELPERS =================
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
        children: [
          Text(label),
          Text("RM $price"),
        ],
      ),
    );
  }
}