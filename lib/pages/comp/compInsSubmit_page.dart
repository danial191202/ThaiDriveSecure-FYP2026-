import 'dart:io';
import 'package:flutter/material.dart';
import 'package:thaidrivesecure/payment/payment_page.dart';

class CompInsSubmit extends StatefulWidget {
  final String fullName;
  final String phone;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int passengerCount;
  final String vehicleType;
  final String packageType;
  final String duration;
  final double totalPrice;
  final String deliveryMethod;
  final File? vehicleGrantFile;
  final List<File> passportFiles;

  const CompInsSubmit({
    super.key,
    required this.fullName,
    required this.phone,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.passengerCount,
    required this.vehicleType,
    required this.packageType,
    required this.duration,
    required this.totalPrice,
    this.deliveryMethod = "Via PDF",
    this.vehicleGrantFile,
    this.passportFiles = const [],
  });

  @override
  State<CompInsSubmit> createState() => _CompInsSubmitState();
}

class _CompInsSubmitState extends State<CompInsSubmit> {
  bool isSubmitting = false;

  String formatPrice(double value) {
    return "RM ${value.toStringAsFixed(2)}";
  }

  // ================= DATA =================
  String get fullName => widget.fullName;
  String get phone => widget.phone;
  String get borderRoute => widget.destination;
  DateTime get departDate => widget.startDate;
  DateTime get returnDate => widget.endDate;
  int get passengers => widget.passengerCount;
  String get durationLabel => widget.duration;
  String get vehicleType => widget.vehicleType;
  int get durationDays => returnDate.difference(departDate).inDays + 1;

  // ================= PRICE =================
  int get insurancePrice {
    switch (vehicleType) {
      case "Pickup/SUV":
        switch (durationLabel) {
          case "9 Days":
            return 45;
          case "19 Days":
            return 60;
          case "1 Month":
            return 80;
          case "3 Months":
            return 140;
          case "6 Months":
            return 230;
          case "1 Year":
            return 400;
          default:
            return 0;
        }
      case "MPV":
        switch (durationLabel) {
          case "9 Days":
            return 50;
          case "19 Days":
            return 70;
          case "1 Month":
            return 90;
          case "3 Months":
            return 160;
          case "6 Months":
            return 260;
          case "1 Year":
            return 450;
          default:
            return 0;
        }
      case "Motorcycle":
        switch (durationLabel) {
          case "9 Days":
            return 20;
          case "19 Days":
            return 30;
          case "1 Month":
            return 40;
          case "3 Months":
            return 70;
          case "6 Months":
            return 120;
          case "1 Year":
            return 200;
          default:
            return 0;
        }
      case "Sedan":
      default:
        switch (durationLabel) {
          case "9 Days":
            return 35;
          case "19 Days":
            return 50;
          case "1 Month":
            return 65;
          case "3 Months":
            return 120;
          case "6 Months":
            return 200;
          case "1 Year":
            return 350;
          default:
            return 0;
        }
    }
  }
  int get tdacPrice => passengers * 2;
  int get tm23Price => 8;

  // ================= NAVIGATE =================
  void _goToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          totalPrice: widget.totalPrice,
          vehicleGrantFile: widget.vehicleGrantFile,
          passportFiles: widget.passportFiles.isEmpty
              ? null
              : widget.passportFiles,
          orderData: {
            "fullName": widget.fullName,
            "phone": widget.phone,
            "destination": widget.destination,
            "vehicleType": widget.vehicleType,
            "packageType": widget.packageType,
            "duration": durationDays,
            "durationLabel": widget.duration,
            "startDate": widget.startDate,
            "endDate": widget.endDate,
            "deliveryMethod": widget.deliveryMethod,
            "insurancePrice": insurancePrice.toDouble(),
            "tmPrice": tm23Price.toDouble(),
            "tdacPrice": tdacPrice.toDouble(),
            "passengerCount": widget.passengerCount,
          },
        ),
      ),
    );
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
              child: _orderCard(),
            ),
          ),

          _bottomButton(),
        ],
      ),
    );
  }

  // 🔵 HEADER
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

  // 🔵 ORDER CARD (MATCHED TO IMAGE)
  Widget _orderCard() {
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
          _row(
            "When:",
            "${_formatDate(departDate)} - ${_formatDate(returnDate)} ($durationDays Days)",
          ),
          _row("Passenger:", passengers.toString()),

          const Divider(height: 24),

          Text("1. ${widget.packageType}"),
          const Text("2. TM2/3"),
          const Text("3. TDAC"),

          const Divider(height: 24),

          _price("${widget.packageType} ($durationLabel)", insurancePrice),
          _price("TM2/3", tm23Price),
          _price("TDAC (RM2 × $passengers)", tdacPrice),

          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Price",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                formatPrice(widget.totalPrice),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 TEXT ROW
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // 🔹 PRICE ROW
  Widget _price(String label, int price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(formatPrice(price.toDouble())),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // 🔵 BUTTON
  Widget _bottomButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F3C68),
            foregroundColor: Colors.white, // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: isSubmitting ? null : _goToPayment,
          child: const Text(
            "Checkout >",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}