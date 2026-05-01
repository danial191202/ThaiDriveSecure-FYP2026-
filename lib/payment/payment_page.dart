// 🔥 UI UPDATED ONLY (LOGIC 100% PRESERVED)

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
  final Map<String, dynamic>? formData;
  final File? vehicleGrantFile;
  final List<File>? passportFiles;
  final double? totalPrice;
  final Map<String, dynamic>? orderData;

  const PaymentPage({
    super.key,
    this.formData,
    this.vehicleGrantFile,
    this.passportFiles,
    this.totalPrice,
    this.orderData,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  File? _receiptFile;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  bool _receiptSubmitted = false;

  Map<String, dynamic> get _resolvedFormData {
    if (widget.formData != null) return widget.formData!;
    return {
      "name": widget.orderData?["fullName"] ?? "-",
      "phone": widget.orderData?["phone"] ?? "-",
      "where": widget.orderData?["destination"] ?? "-",
      "vehicleType": "",
      "passengers": 0,
      "departDate": null,
      "returnDate": null,
      "travelDays": 0,
      "duration": "",
      "deliveryMethod": "Via PDF",
      "packages": const <String>[],
    };
  }

  double get totalAmount => widget.totalPrice ?? 120.00;

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

  Future<String> uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> confirmPayment() async {
    if (_receiptFile == null) return;

    try {
      setState(() => _isUploading = true);

      final formData = _resolvedFormData;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final orderId = DateTime.now().millisecondsSinceEpoch.toString();

      String? vehicleUrl;
      if (widget.vehicleGrantFile != null) {
        vehicleUrl = await uploadFile(
          widget.vehicleGrantFile!,
          'orders/$orderId/vehicle_grant.jpg',
        );
      }

      List<String> passportUrls = [];
      if (widget.passportFiles != null) {
        for (int i = 0; i < widget.passportFiles!.length; i++) {
          final url = await uploadFile(
            widget.passportFiles![i],
            'orders/$orderId/passport_${i + 1}.jpg',
          );
          passportUrls.add(url);
        }
      }

      final receiptUrl = await uploadFile(
        _receiptFile!,
        'orders/$orderId/receipt.jpg',
      );

      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        "orderId": orderId,
        "userId": user.uid,
        "customer": {
          "name": formData['name'],
          "phone": formData['phone'],
          "userId": user.uid,
        },
        "trip": {
          "vehicleType": formData['vehicleType'],
          "borderRoute": formData['where'],
          "passengers": formData['passengers'],
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
          "departDate": formData['departDate'],
          "returnDate": formData['returnDate'],
          "days": formData['travelDays'],
          "duration": formData['duration'],
        },
        "duration": (formData['duration'] ?? formData['travelDays'] ?? 0),
        "deliveryMethod": formData['deliveryMethod'] ?? "Via PDF",
        "startDate": formData['departDate'],
        "endDate": formData['returnDate'],
        "packages": formData['packages'] ?? [],
        "delivery": {
          "method": formData['deliveryMethod'] ?? "Via PDF",
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
          receiptImage: _receiptFile ?? receiptUrl,
          createdAt: DateTime.now(),
          receiptCounter: 1, // replace with your real counter source if available
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
                  const Text("TOTAL PAYABLE",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text("RM ${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 20),

                  _qrCard(),

                  const SizedBox(height: 16),

                  const Text("CNT ENTERPRISE CHANGLUN TOURS",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 6),

                  Image.asset("assets/pbank.png", height: 30),

                  const SizedBox(height: 20),

                  _uploadButton(),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("or"),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _cashCard(),

                  if (canConfirm) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF36A9A6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isUploading ? null : confirmPayment,
                        child: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Confirm Payment",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
        child: Text("Secure Payment",
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  // 🔵 STEPPER
    Widget _stepper() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(child: _step("1", "Personal\nInformations", false)),
          _line(),
          Expanded(child: _step("2", "Upload\nDocuments", false)),
          _line(),
          Expanded(child: _step("3", "Payment\n ", true)),
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

  // 🔵 QR CARD
  Widget _qrCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text("DuitNow",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Image.asset("assets/qr.png", height: 180),
          const SizedBox(height: 8),
          const Text("Scan via your preferred banking app",
              style: TextStyle(fontSize: 12)),
          TextButton(
            onPressed: downloadQrCode,
            child: const Text("Download QR Code"),
          ),
        ],
      ),
    );
  }

  // 🔵 UPLOAD BUTTON
Widget _uploadButton() {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _receiptSubmitted
            ? const Color(0xFF36A9A6)
            : const Color(0xFF1F3C68),
        foregroundColor: Colors.white, // ✅ ADD THIS
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: _showUploadDialog,
      child: Text(
        _receiptSubmitted ? "Receipt Uploaded" : "Upload Payment Receipt",
      ),
    ),
  );
}

  // 🔵 CASH CARD
  Widget _cashCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.attach_money, color: Colors.green),
          SizedBox(width: 10),
          Expanded(
            child: Text("Pay with Cash\nPay in person at our local branch"),
          ),
          Icon(Icons.arrow_forward_ios, size: 14),
        ],
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
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Upload Payment Receipt",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1E3D72),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Upload your bank confirmation slip here to verify your transaction",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8A94A2),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => pickReceipt(setDialogState),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5ECEA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF48BDB5),
                            width: 1.2,
                          ),
                        ),
                        child: _receiptFile == null
                            ? const Column(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Color(0xFFEAF2F2),
                                    child: Icon(Icons.upload_rounded,
                                        size: 30, color: Color(0xFF45BE79)),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Tap to select images",
                                    style: TextStyle(
                                      color: Color(0xFF131A22),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "PDF, JPG OR PNG (MAX 10MB)",
                                    style: TextStyle(
                                      color: Color(0xFF6D7785),
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _receiptFile!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF39ADA7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () {
                          if (_receiptFile != null) {
                            setState(() => _receiptSubmitted = true);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          "Submit Receipt",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}