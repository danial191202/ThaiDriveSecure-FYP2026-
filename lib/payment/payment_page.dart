// 🔥 FINAL VERSION WITH DELIVERY METHOD

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

  double get totalAmount => 120.00;

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

      // 🔥 Upload documents
      final vehicleUrl = await uploadFile(
        widget.vehicleGrantFile,
        'orders/$orderId/vehicle_grant.jpg',
      );

      List<String> passportUrls = [];
      for (int i = 0; i < widget.passportFiles.length; i++) {
        final url = await uploadFile(
          widget.passportFiles[i],
          'orders/$orderId/passport_${i + 1}.jpg',
        );
        passportUrls.add(url);
      }

      final receiptUrl = await uploadFile(
        _receiptFile!,
        'orders/$orderId/receipt.jpg',
      );

      // 🔥 SAVE EVERYTHING (UPDATED HERE)
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

        "travel": {
          "departDate": widget.formData['departDate'],
          "returnDate": widget.formData['returnDate'],
          "days": widget.formData['travelDays'],
          "duration": widget.formData['duration'],
        },

        "packages": widget.formData['packages'] ?? [],
        
        // ✅ NEW DELIVERY FIELD
        "delivery": {
          "method": widget.formData['deliveryMethod'] ?? "Via PDF",
        },

        "pricing": {
          "totalPrice": totalAmount,
        },

        "status": "Order Pending",
        "createdAt": Timestamp.now(),
      });

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
      backgroundColor: const Color(0xFFEAF3F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163B6D),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text("Secure Payment",
            style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _stepCircle("1", false),
                _stepLine(),
                _stepCircle("2", false),
                _stepLine(),
                _stepCircle("3", true),
              ],
            ),

            const SizedBox(height: 25),

            const Text("TOTAL PAYABLE"),
            Text("RM ${totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset("assets/qr.png", height: 220),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _showUploadDialog,
              child: const Text("Upload Payment Receipt"),
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

  Widget _stepCircle(String text, bool active) {
    return CircleAvatar(
      radius: 14,
      backgroundColor:
          active ? const Color(0xFF163B6D) : Colors.grey.shade300,
      child: Text(text,
          style: TextStyle(
              color: active ? Colors.white : Colors.black, fontSize: 12)),
    );
  }

  Widget _stepLine() {
    return const Expanded(child: Divider());
  }

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