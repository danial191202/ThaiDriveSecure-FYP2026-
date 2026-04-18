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
            return 65;
          case "19 Days":
            return 85;
          case "1 Month":
            return 120;
          case "3 Months":
            return 180;
          case "6 Months":
            return 260;
          case "1 Year":
            return 400;
          default:
            return 0;
        }

      case "MPV":
        switch (durationLabel) {
          case "9 Days":
            return 65;
          case "19 Days":
            return 85;
          case "1 Month":
            return 120;
          case "3 Months":
            return 180;
          case "6 Months":
            return 260;
          case "1 Year":
            return 400;
          default:
            return 0;
        }

      case "Motorcycle":
        switch (durationLabel) {
          case "3 Months":
            return 55;
          case "6 Months":
            return 80;
          case "1 Year":
            return 140;
          default:
            return 0;
        }

      case "Sedan":
      default:
        switch (durationLabel) {
          case "9 Days":
            return 55;
          case "19 Days":
            return 70;
          case "1 Month":
            return 90;
          case "3 Months":
            return 130;
          case "6 Months":
            return 180;
          case "1 Year":
            return 300;
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
          _infoRow("Name", widget.formData['name'] ?? ''),
          _infoRow("No.Telephone", widget.formData['phone'] ?? ''),
          _infoRow("Where", widget.formData['where'] ?? ''),
          _infoRow("Vehicle Type", vehicleType),
          _infoRow(
            "When",
            "${_formatDate(departDate)} - ${_formatDate(returnDate)} ($durationLabel)",
          ),
          _infoRow("Passenger", passengers.toString()),

          const Divider(height: 24),

          Text(
            "1. Insurance Compulsory ($durationLabel)\n"
            "2. TM2/3\n"
            "3. TDAC",
          ),

          const Divider(height: 24),

          _priceRow("Insurance Voluntary ($durationLabel)", insurancePrice),
          _priceRow("TM2/3", tm23Price),
          _priceRow("TDAC (RM2 × $passengers)", tdacPrice),

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
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
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
