import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

import 'package:thaidrivesecure/pages/comp/compInsSubmit_page.dart';

class CompInsUpload extends StatefulWidget {
  final String name;
  final String phone;
  final String where;
  final String whenDate;
  final int passengerCount;
  final String duration;
  final String vehicleType;
  final DateTime departDate;
  final DateTime returnDate;
  final String deliveryMethod;

  const CompInsUpload({
    super.key,
    required this.name,
    required this.phone,
    required this.where,
    required this.whenDate,
    required this.passengerCount,
    required this.duration,
    required this.vehicleType,
    required this.departDate,
    required this.returnDate,
    required this.deliveryMethod,
  });

  @override
  State<CompInsUpload> createState() => _CompInsUploadState();
}

class _CompInsUploadState extends State<CompInsUpload> {
  final ImagePicker _picker = ImagePicker();

  File? vehicleGrantImage;
  late List<File?> passportImages;

  @override
  void initState() {
    super.initState();
    vehicleGrantImage = null;
    passportImages = List.generate(widget.passengerCount, (_) => null);
  }

  Future<File> _saveImagePermanently(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}";

    return File(image.path).copy('${directory.path}/$fileName');
  }

  Future<void> pickImage({required bool isVehicleGrant, int? index}) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      final savedFile = await _saveImagePermanently(picked);

      setState(() {
        if (isVehicleGrant) {
          vehicleGrantImage = savedFile;
        } else if (index != null) {
          passportImages[index] = savedFile;
        }
      });
    }
  }

  Future<void> submitDocuments() async {
    if (vehicleGrantImage == null ||
        passportImages.any((img) => img == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all required documents")),
      );
      return;
    }

    final int totalPrice = _calculateTotalPrice();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompInsSubmit(
          fullName: widget.name,
          phone: widget.phone,
          destination: widget.where,
          startDate: widget.departDate,
          endDate: widget.returnDate,
          passengerCount: widget.passengerCount,
          vehicleType: widget.vehicleType,
          packageType: "Insurance Compulsory",
          duration: widget.duration,
          totalPrice: totalPrice.toDouble(),
          deliveryMethod: widget.deliveryMethod,
          vehicleGrantFile: vehicleGrantImage,
          passportFiles: passportImages.whereType<File>().toList(),
        ),
      ),
    );
  }

  int _calculateTotalPrice() {
    int insurancePrice = 0;

    switch (widget.vehicleType) {
      case "Pickup/SUV":
        switch (widget.duration) {
          case "9 Days":
            insurancePrice = 50;
            break;
          case "19 Days":
            insurancePrice = 65;
            break;
          case "1 Month":
            insurancePrice = 90;
            break;
          case "3 Months":
            insurancePrice = 150;
            break;
          case "6 Months":
            insurancePrice = 240;
            break;
          case "1 Year":
            insurancePrice = 420;
            break;
        }
        break;
      case "MPV":
        switch (widget.duration) {
          case "9 Days":
            insurancePrice = 55;
            break;
          case "19 Days":
            insurancePrice = 75;
            break;
          case "1 Month":
            insurancePrice = 100;
            break;
          case "3 Months":
            insurancePrice = 170;
            break;
          case "6 Months":
            insurancePrice = 280;
            break;
          case "1 Year":
            insurancePrice = 480;
            break;
        }
        break;
      case "Motorcycle":
        switch (widget.duration) {
          case "9 Days":
            insurancePrice = 25;
            break;
          case "19 Days":
            insurancePrice = 35;
            break;
          case "1 Month":
            insurancePrice = 50;
            break;
          case "3 Months":
            insurancePrice = 80;
            break;
          case "6 Months":
            insurancePrice = 130;
            break;
          case "1 Year":
            insurancePrice = 220;
            break;
        }
        break;
      case "Sedan":
      default:
        switch (widget.duration) {
          case "9 Days":
            insurancePrice = 40;
            break;
          case "19 Days":
            insurancePrice = 55;
            break;
          case "1 Month":
            insurancePrice = 75;
            break;
          case "3 Months":
            insurancePrice = 130;
            break;
          case "6 Months":
            insurancePrice = 210;
            break;
          case "1 Year":
            insurancePrice = 370;
            break;
        }
        break;
    }

    final int tdacPrice = widget.passengerCount * 2;
    const int tm23Price = 8;
    return insurancePrice + tdacPrice + tm23Price;
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
              child: Column(
                children: [
                  _infoBox(),
                  const SizedBox(height: 16),

                  _uploadCard(
                    title: "Vehicle Registration",
                    subtitle: "Grant/VOC",
                    image: vehicleGrantImage,
                    onTap: () => pickImage(isVehicleGrant: true),
                  ),

                  const SizedBox(height: 16),

                  ...List.generate(widget.passengerCount, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _uploadCard(
                        title: "Identification Card or Passport",
                        subtitle: "Passenger ${index + 1}",
                        image: passportImages[index],
                        onTap: () =>
                            pickImage(isVehicleGrant: false, index: index),
                      ),
                    );
                  }),
                ],
              ),
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
          "Upload Documents",
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

  // 🔵 INFO BOX
  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info, color: Colors.blue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Please upload clear, legible photos. Ensure all text is readable.",
            ),
          ),
        ],
      ),
    );
  }

  // 🔵 UPLOAD CARD
  Widget _uploadCard({
    required String title,
    required String subtitle,
    required File? image,
    required VoidCallback onTap,
  }) {
    final isUploaded = image != null;
    final color = isUploaded ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isUploaded ? "UPLOADED" : "REQUIRED",
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: image == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 30),
                          SizedBox(height: 6),
                          Text("Tap to upload"),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(image, fit: BoxFit.cover),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔵 BUTTON
Widget _bottomButton() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white, // ✅ ADD THIS
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: submitDocuments,
        child: const Text("Next"),
      ),
    ),
  );
}
}