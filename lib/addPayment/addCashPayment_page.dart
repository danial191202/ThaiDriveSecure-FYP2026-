import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:thaidrivesecure/addOn/map_launcher.dart';
import 'package:thaidrivesecure/screens/home_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cash payment for add-on orders only (separate from [CashPaymentPage]).
class AddCashPaymentPage extends StatefulWidget {
  final String fullName;
  final String phone;
  final String pickupDate;
  final String deliveryMethod;
  final String serviceName;
  final int quantity;
  final double totalPrice;

  const AddCashPaymentPage({
    super.key,
    required this.fullName,
    required this.phone,
    required this.pickupDate,
    required this.deliveryMethod,
    required this.serviceName,
    required this.quantity,
    required this.totalPrice,
  });

  @override
  State<AddCashPaymentPage> createState() => _AddCashPaymentPageState();
}

class _AddCashPaymentPageState extends State<AddCashPaymentPage> {
  static const String _locationCounterName = 'Changlun CNT Enterprise';
  static const String _address = 'Changlun, 06010 Bukit Kayu Hitam, Kedah';
  static const String _contactDisplay = '+60 12-345 6789';
  static final Uri _whatsappUri = Uri.parse('https://wa.me/60123456789');

  bool _submitting = false;

  int _nextCounter(int current) => current >= 999 ? 1 : current + 1;

  String _formatAddonOrderId(int n) => 'ADS-${n.toString().padLeft(3, '0')}';

  String _fmt(double v) => 'RM ${v.toStringAsFixed(2)}';

  String _displayDate() {
    final p = widget.pickupDate.trim();
    if (p.isNotEmpty) return p;
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  Future<void> _submitCashOrder() async {
    if (_submitting) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to complete this order.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
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

      final lineTotal = widget.totalPrice;
      final selectedDate = widget.pickupDate.trim().isNotEmpty
          ? widget.pickupDate
          : _displayDate();
      final order = <String, dynamic>{
        'orderId': orderId,
        'userId': user.uid,
        'type': 'addon',
        'fullName': widget.fullName,
        'phone': widget.phone,
        'customerName': widget.fullName,
        'phoneNumber': widget.phone,
        'deliveryMethod': widget.deliveryMethod,
        'selectedDate': selectedDate,
        'pickupDate': widget.pickupDate,
        'customer': {
          'name': widget.fullName,
          'phone': widget.phone,
          'userId': user.uid,
        },
        'serviceName': widget.serviceName,
        'quantity': widget.quantity,
        'totalPrice': lineTotal,
        'addonServices': [
          {
            'name': widget.serviceName,
            'quantity': widget.quantity,
            'price': lineTotal,
          },
        ],
        'pricing': {'totalPrice': lineTotal},
        'paymentMethod': 'Cash',
        'payment': {
          'method': 'Cash',
          'status': 'Pending',
        },
        'status': 'Pending',
        'createdAt': Timestamp.now(),
      };

      await db.collection('addOnOrder').doc(orderId).set(order);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _addonSummaryCard() {
    final linePrice = widget.totalPrice;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.serviceName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3D72),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      color: Colors.grey, size: 22),
                  const SizedBox(height: 4),
                  const Text(
                    '—',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3D72),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryKV('Name', widget.fullName),
          _summaryKV('No.Telephone', widget.phone),
          _summaryKV('Date', _displayDate()),
          _summaryKV('Delivery Method', widget.deliveryMethod),
          const Divider(height: 22),
          const Text(
            'Your Order',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E3D72),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '1. ${widget.serviceName} x${widget.quantity}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              Text(
                _fmt(linePrice),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL PRICE',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3D72),
                ),
              ),
              Text(
                _fmt(widget.totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF36A9A6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryKV(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF1E3D72),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5A6570),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _howToPaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3D72),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'HOW TO PAY',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E3D72),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _stepCard(
          icon: Icons.storefront_outlined,
          title: 'STEP 1',
          body: 'Visit our payment counter',
        ),
        const SizedBox(height: 10),
        _stepCard(
          icon: Icons.payments_outlined,
          title: 'STEP 2',
          body: 'Pay the total amount in cash',
        ),
        const SizedBox(height: 10),
        _stepCard(
          icon: Icons.receipt_long_outlined,
          title: 'STEP 3',
          body: 'Keep your receipt',
        ),
      ],
    );
  }

  Widget _stepCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E3D72), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2D3748),
                  height: 1.25,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F3C68),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Payment Location',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _locationField('COUNTER', _locationCounterName),
          _locationField('ADDRESS', _address),
          _locationField('CONTACT', _contactDisplay),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => MapLauncher.openGoogleMaps(),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('View Map'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    try {
                      await launchUrl(
                        _whatsappUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _header(context),
          _stepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complete your payment manually and upload proof for verification',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6D7785),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _addonSummaryCard(),
                  const SizedBox(height: 24),
                  _howToPaySection(),
                  const SizedBox(height: 16),
                  _locationCard(context),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F3C68),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _submitting ? null : _submitCashOrder,
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 16),
      color: const Color(0xFF1F3C68),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            ),
          ),
          const Text(
            'Cash Payment',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
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
}
