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
  final double totalAmount;
  final String orderId;
  final List<String> selectedItems;

  const PaymentPage({
    super.key,
    required this.totalAmount,
    required this.orderId,
    required this.selectedItems,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  File? _receiptFile;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  String? _receiptUrl;
  bool _receiptSubmitted = false;

  /// =========================
  /// DOWNLOAD QR CODE
  /// =========================
  Future<void> downloadQrCode() async {
    try {
      final byteData = await rootBundle.load('assets/qr.png');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/thaidrive_qr.png');

      await file.writeAsBytes(byteData.buffer.asUint8List());
      await GallerySaver.saveImage(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR Code saved to gallery")),
        );
      }
    } catch (e) {
      debugPrint("Download QR error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save QR Code")),
        );
      }
    }
  }

  /// =========================
  /// PICK RECEIPT IMAGE
  /// =========================
  Future<void> pickReceipt(StateSetter setDialogState) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file != null) {
      setState(() {
        _receiptFile = File(file.path);
        _receiptSubmitted = false;
        _receiptUrl = null;
      });
      setDialogState(() {});
    }
  }

  /// =========================
  /// UPLOAD TO FIREBASE STORAGE
  /// DIRECTLY INTO receipt/ FOLDER
  /// =========================
  Future<void> uploadReceiptToFirebase() async {
    if (_receiptFile == null) return;

    try {
      setState(() {
        _isUploading = true;
      });

      /// Unique filename
      final fileName =
          'receipt_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      /// IMPORTANT:
      /// This uploads directly into Firebase Storage -> receipt/
      final storageRef = FirebaseStorage.instance.ref('receipt/$fileName');

      await storageRef.putFile(_receiptFile!);

      final downloadUrl = await storageRef.getDownloadURL();

      /// Save reference in Firestore
      await FirebaseFirestore.instance
          .collection('insurance_orders')
          .doc(widget.orderId)
          .set({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'totalAmount': widget.totalAmount,
        'selectedItems': widget.selectedItems,
        'receiptUrl': downloadUrl,
        'receiptFileName': fileName,
        'paymentStatus': 'Pending Verification',
        'receiptUploadedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _receiptUrl = downloadUrl;
        _receiptSubmitted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Receipt uploaded into receipt folder successfully"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Upload receipt error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to upload receipt: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// =========================
  /// CONFIRM PAYMENT
  /// =========================
  Future<void> confirmPayment() async {
    try {
      await FirebaseFirestore.instance
          .collection('insurance_orders')
          .doc(widget.orderId)
          .set({
        'paymentStatus': 'Payment Submitted',
        'paymentConfirmedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptPage(
              totalAmount: widget.totalAmount,
              orderId: widget.orderId,
              selectedItems: widget.selectedItems,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Confirm payment error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to confirm payment: $e")),
        );
      }
    }
  }

  /// =========================
  /// UPLOAD RECEIPT DIALOG
  /// =========================
  void _showUploadReceiptDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Upload Payment\nReceipt",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF163B6D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Upload your bank confirmation slip here to verify your transaction",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () => pickReceipt(setDialogState),
                      child: Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5F4),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFF42C4B7),
                            width: 1.6,
                          ),
                        ),
                        child: _receiptFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.upload_rounded,
                                      size: 38,
                                      color: Color(0xFF18B7A8),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    "Tap to select image",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "JPG OR PNG ONLY",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.file(
                                      _receiptFile!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _receiptFile = null;
                                          _receiptSubmitted = false;
                                          _receiptUrl = null;
                                        });
                                        setDialogState(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        "Tap to change",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _receiptFile != null
                              ? const Color(0xFF18B7A8)
                              : const Color(0xFFE3E3E3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        onPressed: (_receiptFile != null && !_isUploading)
                            ? () async {
                                await uploadReceiptToFirebase();
                                if (mounted && _receiptSubmitted) {
                                  Navigator.pop(context);
                                }
                              }
                            : null,
                        child: _isUploading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Submit Receipt",
                                style: TextStyle(
                                  fontSize: 22,
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

  @override
  Widget build(BuildContext context) {
    final bool canConfirm = _receiptSubmitted && _receiptUrl != null;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163B6D),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Payment",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
        child: Column(
          children: [
            const SizedBox(height: 8),

            const Text(
              "TOTAL PAYABLE",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "RM ${widget.totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 26),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Image.asset(
                "assets/qr.png",
                height: 258,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Scan via your preferred banking app",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: 216,
              height: 36,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8CCEC),
                  foregroundColor: const Color(0xFF163B6D),
                  elevation: 3,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: downloadQrCode,
                icon: const Icon(Icons.download_rounded),
                label: const Text(
                  "Download QR Code",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              "CNT ENTERPRISE CHANGLUN TOURS",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Image.asset(
              "assets/pbank.png",
              height: 34,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: 216,
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF163B6D),
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: _showUploadReceiptDialog,
                child: const Text(
                  "Upload Payment Receipt",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_receiptSubmitted) ...[
              const Text(
                "Receipt uploaded successfully",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 10),

            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF5E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: Color(0xFF35B56A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pay with Cash",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Pay in person at our local branch (CNT ENTERPRISE)",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canConfirm
                      ? const Color(0xFF18B7A8)
                      : const Color(0xFF9EDDD6),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: canConfirm
                    ? () async {
                        await confirmPayment();
                      }
                    : null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Confirm Payment",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}