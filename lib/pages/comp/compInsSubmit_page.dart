import 'dart:io';
import 'package:flutter/material.dart';
import 'package:thaidrivesecure/payment/payment_page.dart';

class CompInsSubmit extends StatefulWidget {
  final Map<String, dynamic> formData;
  final File vehicleGrantFile;
  final List<File> passportFiles;

  const CompInsSubmit({
    super.key,
    required this.formData,
    required this.vehicleGrantFile,
    required this.passportFiles,
  });

  @override
  State<CompInsSubmit> createState() => _CompInsSubmitState();
}

class _CompInsSubmitState extends State<CompInsSubmit> {
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

  // ================= NAVIGATE TO PAYMENT =================
  void goToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          formData: widget.formData,
          vehicleGrantFile: widget.vehicleGrantFile,
          passportFiles: widget.passportFiles,
        ),
      ),
    );
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
                ),
                onPressed: isSubmitting ? null : goToPayment,
                child: const Text(
                  "Proceed to Payment >",
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