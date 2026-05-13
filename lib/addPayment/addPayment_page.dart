import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';

import 'package:thaidrivesecure/addPayment/addCashPayment_page.dart';
import 'package:thaidrivesecure/addPayment/addReceipt_page.dart';

/// Add-on services only: QR / receipt upload + cash entry (does not use [PaymentPage]).
class AddPaymentPage extends StatefulWidget {
  final String fullName;
  final String phone;
  final String pickupDate;
  final String deliveryMethod;
  final String serviceName;
  final int quantity;
  final double totalPrice;
  final String durationLabel;
  final String destinationLocation;

  const AddPaymentPage({
    super.key,
    required this.fullName,
    required this.phone,
    required this.pickupDate,
    required this.deliveryMethod,
    required this.serviceName,
    required this.quantity,
    required this.totalPrice,
    this.durationLabel = '',
    this.destinationLocation = '',
  });

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  File? _receiptFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _receiptSubmitted = false;

  int _nextCounter(int current) => current >= 999 ? 1 : current + 1;

  String _formatAddonOrderId(int n) => 'ADS-${n.toString().padLeft(3, '0')}';

  String _fmt(double v) => 'RM ${v.toStringAsFixed(2)}';

  String _displayDate() {
    final p = widget.pickupDate.trim();
    if (p.isNotEmpty) return p;
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  Future<void> downloadQrCode() async {
    final byteData = await rootBundle.load('assets/qr.png');
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/qr.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    await GallerySaver.saveImage(file.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR saved')),
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
    return ref.getDownloadURL();
  }

  Future<String> _allocateAddonOrderId() async {
    final db = FirebaseFirestore.instance;
    final counterRef =
        db.collection('counters').doc('addOnOrders');
    late String orderId;
    await db.runTransaction((tx) async {
      final snap = await tx.get(counterRef);
      final next = _nextCounter((snap.data()?['value'] as int?) ?? 0);
      tx.set(counterRef, {'value': next});
      orderId = _formatAddonOrderId(next);
    });
    return orderId;
  }

  String _addonLineName() {
    final d = widget.durationLabel.trim();
    if (d.isNotEmpty) {
      return '${widget.serviceName} ($d)';
    }
    return widget.serviceName;
  }

  Map<String, dynamic> _buildOrderMap({
    required String orderId,
    required String paymentMethod,
    required String paymentStatus,
    String? receiptUrl,
  }) {
    final selectedDate = widget.pickupDate.trim().isNotEmpty
        ? widget.pickupDate
        : _displayDate();

    final dest = widget.destinationLocation.trim();
    final dur = widget.durationLabel.trim();

    return <String, dynamic>{
      'orderId': orderId,
      // Keep same key structure as the previous `orders` add-on schema
      // so existing security rules & UI logic continue to work.
      'type': 'addon',
      'serviceName': widget.serviceName,
      'totalPrice': widget.totalPrice,
      'quantity': widget.quantity,
      'customerName': widget.fullName,
      'phoneNumber': widget.phone,
      'fullName': widget.fullName,
      'phone': widget.phone,
      'deliveryMethod': widget.deliveryMethod,
      'selectedDate': selectedDate,
      'pickupDate': widget.pickupDate,
      if (dur.isNotEmpty) 'durationLabel': dur,
      if (dest.isNotEmpty) 'destinationLocation': dest,
      'customer': {
        'name': widget.fullName,
        'phone': widget.phone,
      },
      'addonServices': [
        {
          'name': _addonLineName(),
          'quantity': widget.quantity,
          'price': widget.totalPrice,
        },
      ],
      'pricing': {'totalPrice': widget.totalPrice},
      'payment': {
        'method': paymentMethod,
        'status': paymentStatus,
        if (receiptUrl != null) 'receiptUrl': receiptUrl,
        if (receiptUrl != null) 'submittedAt': Timestamp.now(),
      },
      // Keep status stable for history card mapping.
      'status': 'Pending',
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.now(),
    };
  }

  Future<void> confirmPayment() async {
    if (_receiptFile == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final orderId = await _allocateAddonOrderId();
      final receiptUrl = await uploadFile(
        _receiptFile!,
        'addOnOrder/$orderId/addon_receipt.jpg',
      );

      final order = _buildOrderMap(
        orderId: orderId,
        paymentMethod: 'QR',
        paymentStatus: 'Submitted',
        receiptUrl: receiptUrl,
      );
      order['userId'] = user.uid;

      await FirebaseFirestore.instance
          .collection('addOnOrder')
          .doc(orderId)
          .set(order);

      if (!mounted) return;
      final Map<String, dynamic> savedOrderData =
          Map<String, dynamic>.from(order);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => AddReceiptPage(orderData: savedOrderData),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _receiptSubmitted = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _openCashPayment() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddCashPaymentPage(
          fullName: widget.fullName,
          phone: widget.phone,
          pickupDate: widget.pickupDate,
          deliveryMethod: widget.deliveryMethod,
          serviceName: widget.serviceName,
          quantity: widget.quantity,
          totalPrice: widget.totalPrice,
          durationLabel: widget.durationLabel,
          destinationLocation: widget.destinationLocation,
        ),
      ),
    );
  }

  void _showUploadDialog() {
    showDialog<void>(
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
                      'Upload Payment Receipt',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1E3D72),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Upload your bank confirmation slip here to verify your transaction',
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
                                    'Tap to select images',
                                    style: TextStyle(
                                      color: Color(0xFF131A22),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'PDF, JPG OR PNG (MAX 10MB)',
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
                          if (_receiptFile == null) return;
                          setState(() => _receiptSubmitted = true);
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Submit Receipt',
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

  @override
  Widget build(BuildContext context) {
    final canConfirm = _receiptSubmitted;

    return Stack(
      children: [
        Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _header(),
          _stepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'TOTAL PAYABLE',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fmt(widget.totalPrice),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _qrCard(),
                  const SizedBox(height: 16),
                  const Text(
                    'CNT ENTERPRISE CHANGLUN TOURS',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Image.asset('assets/pbank.png', height: 30),
                  const SizedBox(height: 20),
                  _uploadButton(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or'),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _cashCard(),
                  ),
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
                                'Confirm Payment',
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
    ),
        if (_isUploading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withOpacity(0.25),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 16),
      color: const Color(0xFF1F3C68),
      child: const Center(
        child: Text(
          'Secure Payment',
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
          Expanded(child: _step('1', 'Personal\nInformations', false)),
          _line(),
          Expanded(child: _step('2', 'Upload\nDocuments', false)),
          _line(),
          Expanded(child: _step('3', 'Payment\n ', true)),
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

  Widget _qrCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'DuitNow',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Image.asset('assets/qr.png', height: 180),
          const SizedBox(height: 8),
          const Text(
            'Scan via your preferred banking app',
            style: TextStyle(fontSize: 12),
          ),
          TextButton(
            onPressed: downloadQrCode,
            child: const Text('Download QR Code'),
          ),
        ],
      ),
    );
  }

  Widget _uploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _receiptSubmitted
              ? const Color(0xFF36A9A6)
              : const Color(0xFF1F3C68),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _showUploadDialog,
        child: Text(
          _receiptSubmitted ? 'Receipt Uploaded' : 'Upload Payment Receipt',
        ),
      ),
    );
  }

  Widget _cashCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openCashPayment,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.green),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pay with Cash\nPay in person at our local branch',
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
