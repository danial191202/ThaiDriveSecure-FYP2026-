import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    passportImages = List.generate(widget.passengerCount, (_) => null);
  }

  // ================= FIREBASE UPLOAD =================
  Future<String?> uploadToFirebase(File file, String path) async {
    try {
      print("Uploading file: ${file.path}");

      if (!file.existsSync()) {
        throw Exception("File does not exist locally");
      }

      final ref = FirebaseStorage.instance.ref().child(path);

      final snapshot = await ref.putFile(file);

      if (snapshot.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        print("Download URL: $url");
        return url;
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
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

  // ================= SUBMIT =================
  Future<void> submitDocuments() async {
    if (vehicleGrantImage == null || passportImages.any((img) => img == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all required documents")),
      );
      return;
    }

    try {
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // 🔥 UPLOAD VEHICLE GRANT
      final vehicleGrantUrl = await uploadToFirebase(
        vehicleGrantImage!,
        'orders/$orderId/vehicle_grant.jpg',
      );

      if (vehicleGrantUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vehicle grant upload failed")),
        );
        return;
      }

      // 🔥 UPLOAD PASSPORTS
      List<Map<String, dynamic>> passportDocs = [];

      for (int i = 0; i < passportImages.length; i++) {
        final file = passportImages[i]!;

        final url = await uploadToFirebase(
          file,
          'orders/$orderId/passport_${i + 1}.jpg',
        );

        if (url == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Passport ${i + 1} upload failed")),
          );
          return;
        }

        passportDocs.add({"name": "Passport ${i + 1}", "url": url});
      }

      // 🔥 SAVE TO FIRESTORE
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        "orderId": orderId,

        "fullName": widget.name,
        "phoneNumber": widget.phone,

        "vehicleType": widget.vehicleType,
        "passengers": widget.passengerCount,

        "borderRoute": widget.where,
        "travelDayLabel": widget.whenDate,

        "packages": ['Insurance Compulsory', 'TM2/3', 'TDAC'],

        "documents": {
          "passportDocuments": passportDocs,
          "vehicleGrant": {"name": "Vehicle Grant", "url": vehicleGrantUrl},
        },

        "pricing": {"totalPrice": 75.00},

        "status": "Order Pending",
        "createdAt": Timestamp.now(),
      });

      // ✅ SUCCESS
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload successful")));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompInsSubmit(
            formData: {
              'name': widget.name,
              'phone': widget.phone,
              'where': widget.where,
            },
            vehicleGrantPath: vehicleGrantUrl,
            passportPaths: passportDocs.map((e) => e['url'] as String).toList(),
          ),
        ),
      );
    } catch (e) {
      print("Submit error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload failed")));
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
