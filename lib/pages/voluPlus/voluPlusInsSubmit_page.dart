import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:thaidrivesecure/payment/payment_page.dart';

class VoluPlusInsSubmit extends StatefulWidget {
  final Map<String, dynamic> formData;
  final File vehicleGrantFile;
  final List<File> passportFiles;

  const VoluPlusInsSubmit({
    super.key,
    required this.formData,
    required this.vehicleGrantFile,
    required this.passportFiles,
  });

  @override
  State<VoluPlusInsSubmit> createState() => _VoluPlusInsSubmitState();
}

class _VoluPlusInsSubmitState extends State<VoluPlusInsSubmit> {
  String selectedDelivery = "Take Away";
  bool isSubmitting = false;

  String formatPrice(double value) {
    return "RM ${value.toStringAsFixed(2)}";
  }

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
    String get vehicleType => widget.formData['vehicleType'] ?? "Sedan";
/*
  // ================= SAFE DATE =================
  DateTime get departDate {
    final value = widget.formData['departDate'];
    if (value is DateTime) return value;
    return DateTime.now();
  }

  DateTime get returnDate {
    final value = widget.formData['returnDate'];
    if (value is DateTime) return value;
    return DateTime.now().add(const Duration(days: 1));
  }

  int get passengers => widget.formData['passengers'] ?? 1;
  String get durationLabel => widget.formData['duration'] ?? "9 Days";
  String get vehicleType => widget.formData['vehicleType'] ?? 'Sedan';
*/
  int get totalDays => returnDate.difference(departDate).inDays + 1;

  // ================= PRICE TABLE =================
  int get insurancePrice {
    switch (vehicleType) {
      case "Pickup/SUV":
        switch (durationLabel) {
          case "9 Days":
            return 100;
          case "19 Days":
            return 130;
          case "1 Month":
            return 160;
          case "3 Months":
            return 280;
          case "6 Months":
            return 450;
          case "1 Year":
            return 750;
          default:
            return 0;
        }

      case "MPV":
        switch (durationLabel) {
          case "9 Days":
            return 110;
          case "19 Days":
            return 150;
          case "1 Month":
            return 180;
          case "3 Months":
            return 320;
          case "6 Months":
            return 500;
          case "1 Year":
            return 850;
          default:
            return 0;
        }

      case "Motorcycle":
        switch (durationLabel) {
          case "9 Days":
            return 50;
          case "19 Days":
            return 70;
          case "1 Month":
            return 90;
          case "3 Months":
            return 150;
          case "6 Months":
            return 240;
          case "1 Year":
            return 400;
          default:
            return 0;
        }

      case "Sedan":
      default:
        switch (durationLabel) {
          case "9 Days":
            return 85;
          case "19 Days":
            return 110;
          case "1 Month":
            return 135;
          case "3 Months":
            return 240;
          case "6 Months":
            return 400;
          case "1 Year":
            return 650;
          default:
            return 0;
        }
    }
  }

  int get tdacPrice => passengers * 2;
  int get tm23Price => 8;
  double get totalPrice => (insurancePrice + tdacPrice + tm23Price).toDouble();
  // ================= IMAGE UPLOAD =================
  Future<String> _uploadImage(File file, String storagePath) async {
    if (!await file.exists()) {
      throw Exception("File does not exist: ${file.path}");
    }

    final ref = FirebaseStorage.instance.ref().child(storagePath);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // ================= CHECKOUT =================
  Future<void> checkout() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();

      final orderId = orderRef.id;

      final vehicleGrantUrl = await _uploadImage(
        widget.vehicleGrantFile,
        "orders/$orderId/vehicle_grant.jpg",
      );

      List<String> passportUrls = [];

      for (int i = 0; i < widget.passportFiles.length; i++) {
        final url = await _uploadImage(
          widget.passportFiles[i],
          "orders/$orderId/passport_${i + 1}.jpg",
        );
        passportUrls.add(url);
      }

      await orderRef.set({
        'orderId': orderId,
        'userId': user.uid,
        ...widget.formData,
        'durationDays': totalDays,
        'durationLabel': durationLabel,
        'vehicleType': vehicleType,
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
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            totalPrice: totalPrice,
            formData: {
              'name': fullName,
              'phone': phone,
              'where': borderRoute,
              'vehicleType': vehicleType,
              'passengers': passengers,
              'duration': durationLabel,
              'departDate': departDate,
              'returnDate': returnDate,
            },

            // ⚠️ YOU MUST HAVE THESE VARIABLES IN THIS PAGE
            vehicleGrantFile: widget.vehicleGrantFile,
            passportFiles: widget.passportFiles,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      String errorMessage = "Submission failed";

      if (e.plugin == 'firebase_storage' && e.code == 'unauthorized') {
        errorMessage =
            "Storage permission denied. Please check Firebase Storage Rules.";
      } else if (e.plugin == 'cloud_firestore' &&
          e.code == 'permission-denied') {
        errorMessage =
            "Firestore permission denied. Please check Firestore Rules.";
      } else {
        errorMessage = "Submission failed: ${e.message}";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Submission failed: $e")));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _header(),
          _stepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _orderReviewCard(),
            ),
          ),
          _bottomButton(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 16),
      color: const Color(0xFF1F3C68),
      child: const Center(
        child: Text(
          "Order Review",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _stepper() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(child: _step("1", "Personal\nInformations", false)),
          _line(),
          Expanded(child: _step("2", "Upload\nDocuments", true)),
          _line(),
          Expanded(child: _step("3", "Payment\n ", false)),
        ],
      ),
    );
  }

  Widget _step(String num, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF1E3D72) : const Color(0xFFE2E6EC),
            border: Border.all(
              color: active ? const Color(0xFF1E3D72) : const Color(0xFFD3D8E1),
            ),
          ),
          child: Text(
            num,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFFA0A7B3),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: active ? const Color(0xFF1E3D72) : const Color(0xFFB6BDC8),
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _line() {
    return Container(
      width: 70,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 26),
      color: const Color(0xFFDCE1E8),
    );
  }

  Widget _orderReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row("Name:", fullName),
          _row("No.Telephone:", phone),
          const SizedBox(height: 6),
          _row("Where:", borderRoute),
          _row("Vehicle Type:", vehicleType),
          _infoRow(
            "When",
            "${_formatDate(departDate)} - ${_formatDate(returnDate)} ($durationLabel)",
          ),
          _row("Passenger:", passengers.toString()),

          const Divider(height: 24),

          Text("1. Insurance Voluntary Plus ($durationLabel)"),
          const Text("2. TM2/3"),
          const Text("3. TDAC"),

          const Divider(height: 24),

          _price("Insurance Voluntary Plus ($durationLabel)", insurancePrice),
          _price("TM2/3", tm23Price),
          _price("TDAC (RM2 × $passengers)", tdacPrice),

          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Price",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                formatPrice(totalPrice),
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return _row("$label:", value);
  }

  Widget _price(String label, int price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(formatPrice(price.toDouble()))],
      ),
    );
  }

  Widget _bottomButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F3C68),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: isSubmitting ? null : checkout,
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  "Checkout >",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
