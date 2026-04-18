// 🔥 FULL CLEAN VERSION

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'receipt_page.dart';
import 'package:thaidrivesecure/screens/home_page.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final File vehicleGrantFile;
  final List<File> passportFiles;

  const PaymentPage({
    super.key,
    required this.formData,
    required this.vehicleGrantFile,
    required this.passportFiles,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  File? _receiptFile;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  bool _receiptSubmitted = false;

  // ================= PRICE =================
  double get totalAmount => 75.00;

  // ================= QR DOWNLOAD =================
  Future<void> downloadQrCode() async {
    final byteData = await rootBundle.load('assets/qr.png');
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/qr.png');

    await file.writeAsBytes(byteData.buffer.asUint8List());
    await GallerySaver.saveImage(file.path);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("QR saved")),
    );
  }

  // ================= PICK RECEIPT =================
  Future<void> pickReceipt(StateSetter setDialogState) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        _receiptFile = File(file.path);
        _receiptSubmitted = false;
      });
      setDialogState(() {});
    }
  }

  // ================= FIREBASE UPLOAD =================
  Future<String> uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // ================= FINAL SUBMIT =================
  Future<void> confirmPayment() async {
    if (_receiptFile == null) return;

    try {
      setState(() => _isUploading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // 🔥 Upload vehicle grant
      final vehicleUrl = await uploadFile(
        widget.vehicleGrantFile,
        'orders/$orderId/vehicle_grant.jpg',
      );

      // 🔥 Upload passports
      List<String> passportUrls = [];
      for (int i = 0; i < widget.passportFiles.length; i++) {
        final url = await uploadFile(
          widget.passportFiles[i],
          'orders/$orderId/passport_${i + 1}.jpg',
        );
        passportUrls.add(url);
      }

      // 🔥 Upload receipt
      final receiptUrl = await uploadFile(
        _receiptFile!,
        'orders/$orderId/receipt.jpg',
      );

      // 🔥 SAVE EVERYTHING
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        "orderId": orderId,

        "customer": {
          "name": widget.formData['name'],
          "phone": widget.formData['phone'],
          "userId": user.uid,
        },

        "trip": {
          "vehicleType": widget.formData['vehicleType'],
          "borderRoute": widget.formData['where'],
          "passengers": widget.formData['passengers'],
        },

        "documents": {
          "vehicleGrantUrl": vehicleUrl,
          "passportUrls": passportUrls,
        },

        "payment": {
          "method": "QR",
          "status": "Submitted",
          "receiptUrl": receiptUrl,
          "submittedAt": Timestamp.now(),
        },

        "pricing": {
          "totalPrice": totalAmount,
        },

        "status": "Order Pending",
        "createdAt": Timestamp.now(),
      });

      // ✅ SUCCESS
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptPage(
            totalAmount: totalAmount,
            orderId: orderId,
            selectedItems: ["Insurance"],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final canConfirm = _receiptSubmitted;

    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("RM $totalAmount"),

            ElevatedButton(
              onPressed: downloadQrCode,
              child: const Text("Download QR"),
            ),

            ElevatedButton(
              onPressed: _showUploadDialog,
              child: const Text("Upload Receipt"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: canConfirm ? confirmPayment : null,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text("Confirm Payment"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DIALOG =================
  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Upload Receipt"),
              content: GestureDetector(
                onTap: () => pickReceipt(setDialogState),
                child: Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: _receiptFile == null
                      ? const Icon(Icons.add)
                      : Image.file(_receiptFile!, fit: BoxFit.cover),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_receiptFile != null) {
                      setState(() => _receiptSubmitted = true);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Submit"),
                )
              ],
            );
          },
        );
      },
    );
  }
}