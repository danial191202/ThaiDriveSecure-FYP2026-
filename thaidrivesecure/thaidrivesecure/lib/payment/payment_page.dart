import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'receipt_page.dart';
import 'package:thaidrivesecure/screens/home_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  File? _receiptImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickReceipt() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _receiptImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _receiptImage != null;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FB),

      /// 🔵 APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xFF163B6D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Payment", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),

      /// 🧾 BODY (SCROLL ENABLED)
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "Scan QR code to payment",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            /// QR IMAGE
            Image.asset("assets/qr.png", height: 300),

            const SizedBox(height: 20),

            const Text(
              "CNT ENTERPRISE CHANGLUN TOURS",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Image.asset("assets/pbank.png", height: 28),

            const SizedBox(height: 24),

            /// UPLOAD PAYMENT BUTTON
            SizedBox(
              width: 200,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF163B6D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: pickReceipt,
                child: const Text(
                  "Upload Payment",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// RECEIPT STATUS / PREVIEW
            _receiptImage == null
                ? const Text(
                    "No receipt selected",
                    style: TextStyle(color: Colors.black54),
                  )
                : Image.file(_receiptImage!, height: 120),

            const SizedBox(height: 16),

            /// CASH BUTTON
            SizedBox(
              width: 200,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF163B6D)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
                child: const Text(
                  "Cash",
                  style: TextStyle(color: Color(0xFF163B6D)),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// DONE PAYMENT BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit
                      ? const Color(0xFF163B6D)
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                onPressed: canSubmit
                    ? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReceiptPage(),
                          ),
                        );
                      }
                    : null,
                child: const Text(
                  "Done Payment",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
