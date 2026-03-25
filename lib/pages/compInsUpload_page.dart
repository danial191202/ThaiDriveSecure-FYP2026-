import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

import 'package:thaidrivesecure/pages/compInsSubmit_page.dart';

class CompInsUploadPage extends StatefulWidget {
  final String name;
  final String phone;
  final String where;
  final String whenDate;
  final int passengerCount;
  final String duration;

  const CompInsUploadPage({
    super.key,
    required this.name,
    required this.phone,
    required this.where,
    required this.whenDate,
    required this.passengerCount,
    required this.duration,
  });

  @override
  State<CompInsUploadPage> createState() => _CompInsUploadPageState();
}

class _CompInsUploadPageState extends State<CompInsUploadPage> {
  final ImagePicker _picker = ImagePicker();

  File? vehicleGrantImage;
  late List<File?> passportImages;

  // ✅ NEW: extracted dates
  DateTime? departDate;
  DateTime? returnDate;

  @override
  void initState() {
    super.initState();
    passportImages = List.generate(widget.passengerCount, (_) => null);

    // ✅ EXTRACT DATE FROM STRING
    _extractDatesFromWhen();
  }

  // ================= EXTRACT DATE =================
  void _extractDatesFromWhen() {
    try {
      String when = widget.whenDate;

      final parts = when.split('-');

      String start = parts[0].trim();
      String end = parts[1].split('(')[0].trim();

      departDate = _parseDate(start);
      returnDate = _parseDate(end);
    } catch (_) {
      departDate = DateTime.now();
      returnDate = DateTime.now().add(const Duration(days: 1));
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

  // ================= SAVE IMAGE =================
  Future<File> _saveImagePermanently(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}";
    final savedImage = await File(
      image.path,
    ).copy('${directory.path}/$fileName');
    return savedImage;
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage({required bool isVehicleGrant, int? index}) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);

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

  // ================= SUBMIT =================
  void submitDocuments() {
    if (vehicleGrantImage == null || passportImages.any((img) => img == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all required documents")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompInsSubmitPage(
          formData: {
            'name': widget.name,
            'phone': widget.phone,
            'where': widget.where,
            'when': widget.whenDate,
            'passengers': widget.passengerCount,
            'vehicleType': 'Sedan',
            'packages': ['Insurance Compulsory', 'TM2/3', 'TDAC'],
            'duration': widget.duration, // ✅ ADD THIS

            // ✅ FIXED (NO MORE NULL)
            'departDate': departDate ?? DateTime.now(),
            'returnDate': returnDate ??
                (departDate ?? DateTime.now()).add(const Duration(days: 1)),
          },
          vehicleGrantPath: vehicleGrantImage!.path,
          passportPaths: passportImages.map((file) => file!.path).toList(),
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
          "Upload Documents",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please upload all required document",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),
            const Text(
              "1. Vehicle Grant",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            uploadBox(
              image: vehicleGrantImage,
              onTap: () => pickImage(isVehicleGrant: true),
            ),

            const SizedBox(height: 20),
            const Text(
              "2. Passport",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              "*Please upload all passengers in the vehicle*",
              style: TextStyle(color: Colors.red),
            ),

            const SizedBox(height: 10),
            ...List.generate(widget.passengerCount, (index) {
              return uploadBox(
                image: passportImages[index],
                label: "Passenger ${index + 1} Passport",
                onTap: () => pickImage(isVehicleGrant: false, index: index),
              );
            }),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF163B6D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 14,
                  ),
                ),
                onPressed: submitDocuments,
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UPLOAD BOX =================
  Widget uploadBox({File? image, String? label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black45),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Center(
          child: image == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 40),
                    if (label != null) Text(label),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
        ),
      ),
    );
  }
}