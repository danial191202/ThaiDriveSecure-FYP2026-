import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:thaidrivesecure/addOn/map_launcher.dart';
import 'package:thaidrivesecure/screens/home_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cash payment instructions + order summary. Data is merged in [PaymentPage]
/// so this works for compulsory (orderData) and voluntary flows (formData only).
class CashPaymentPage extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final double totalPrice;
  final File? vehicleGrantFile;
  final List<File>? passportFiles;

  const CashPaymentPage({
    super.key,
    required this.orderData,
    required this.totalPrice,
    this.vehicleGrantFile,
    this.passportFiles,
  });

  @override
  State<CashPaymentPage> createState() => _CashPaymentPageState();
}

class _CashPaymentPageState extends State<CashPaymentPage> {
  static const String _locationCounterName = 'Changlun CNT Enterprise';
  static const String _address =
      'Changlun, 06010 Bukit Kayu Hitam, Kedah';
  static const String _contactDisplay = '+60 12-345 6789';
  static final Uri _whatsappUri = Uri.parse('https://wa.me/60123456789');

  bool _submitting = false;

  int _nextCounter(int current) => current >= 999 ? 1 : current + 1;

  String _formatCashOrderId(int n) =>
      'CDS-${n.toString().padLeft(3, '0')}';

  String _str(dynamic v, [String fallback = '—']) {
    if (v == null) return fallback;
    final s = v.toString();
    return s.isEmpty ? fallback : s;
  }

  double _toDouble(dynamic v) =>
      double.tryParse((v ?? 0).toString()) ?? 0.0;

  String _formatPrice(double v) => 'RM ${v.toStringAsFixed(2)}';

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    if (raw is DateTime) dt = raw;
    if (dt == null) return raw.toString();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Map<String, dynamic> get _m => widget.orderData;

  int _travelDaysForFirestore() {
    final td = _m['travelDays'];
    if (td is int) return td;
    final d = _m['duration'];
    if (d is int) return d;
    return int.tryParse((td ?? d ?? 0).toString()) ?? 0;
  }

  String _durationLabelForFirestore() {
    final a = _m['durationLabel']?.toString();
    if (a != null && a.isNotEmpty) return a;
    final b = _m['duration']?.toString();
    if (b != null && b.isNotEmpty && int.tryParse(b) == null) return b;
    return '';
  }

  Future<String> _uploadFile(File file, String storagePath) async {
    final ref = FirebaseStorage.instance.ref().child(storagePath);
    await ref.putFile(file);
    return ref.getDownloadURL();
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
          db.collection('counters').doc('cash_order_counter');

      late String orderId;

      await db.runTransaction((tx) async {
        final snap = await tx.get(counterRef);
        final next = _nextCounter((snap.data()?['value'] as int?) ?? 0);
        tx.set(counterRef, {'value': next});
        orderId = _formatCashOrderId(next);
      });

      final name = _str(
        _m['fullName'] ?? _m['name'] ?? _m['customer']?['name'],
        '-',
      );
      final phone = _str(
        _m['phone'] ?? _m['customer']?['phone'],
        '-',
      );
      final where = _str(
        _m['where'] ?? _m['destination'] ?? _m['trip']?['borderRoute'],
        '-',
      );
      final vehicleType = _str(_m['vehicleType'], '');
      final packageType = _str(_m['packageType'], '');
      final passengers = _m['passengers'] ??
          _m['passengerCount'] ??
          _m['trip']?['passengers'] ??
          0;
      final passengerCount =
          _m['passengerCount'] ?? passengers ?? 0;

      final startDate = _m['departDate'] ??
          _m['startDate'] ??
          _m['travel']?['departDate'];
      final endDate = _m['returnDate'] ??
          _m['endDate'] ??
          _m['travel']?['returnDate'];

      final durationLabel = _durationLabelForFirestore();
      final travelDays = _travelDaysForFirestore();

      final paxForPricing = int.tryParse(
            (passengerCount != 0 ? passengerCount : passengers).toString(),
          ) ??
          1;
      final paxTd = paxForPricing < 1 ? 1 : paxForPricing;

      var insurancePrice = _toDouble(_m['insurancePrice']);
      var tmPrice = _toDouble(_m['tmPrice'] ?? _m['tm23Price']);
      var tdacPrice = _toDouble(_m['tdacPrice']);
      if (tmPrice <= 0) tmPrice = 8.0;
      if (tdacPrice <= 0) tdacPrice = paxTd * 2.0;
      if (insurancePrice <= 0 && widget.totalPrice > 0) {
        final inferred = widget.totalPrice - tmPrice - tdacPrice;
        if (inferred >= 0) insurancePrice = inferred;
      }

      final deliveryMethod =
          _m['deliveryMethod'] ?? _m['delivery']?['method'] ?? 'Via PDF';

      final packages = (_m['packages'] as List?)?.isNotEmpty == true
          ? List<dynamic>.from(_m['packages'] as List)
          : [
              if (packageType.isNotEmpty) packageType,
              'TM2/3',
              'TDAC',
            ];

      String? vehicleUrl;
      if (widget.vehicleGrantFile != null) {
        vehicleUrl = await _uploadFile(
          widget.vehicleGrantFile!,
          'orders/$orderId/vehicle_grant.jpg',
        );
      }

      final passportUrls = <String>[];
      final files = widget.passportFiles;
      if (files != null) {
        for (var i = 0; i < files.length; i++) {
          final url = await _uploadFile(
            files[i],
            'orders/$orderId/passport_${i + 1}.jpg',
          );
          passportUrls.add(url);
        }
      }

      await db.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': user.uid,
        'paymentType': 'Cash',
        'paymentMethod': 'Cash',
        'customer': {
          'name': name,
          'phone': phone,
          'userId': user.uid,
        },
        'trip': {
          'vehicleType': vehicleType,
          'borderRoute': where,
          'passengers': passengers,
        },
        'documents': {
          'vehicleGrantUrl': vehicleUrl,
          'passportUrls': passportUrls,
        },
        'payment': {
          'method': 'Cash',
          'type': 'Cash',
          'status': 'Pending',
        },
        'travel': {
          'departDate': startDate,
          'returnDate': endDate,
          'days': travelDays,
          'duration': durationLabel,
        },
        'vehicleType': vehicleType,
        'packageType': packageType,
        'duration': travelDays,
        'durationLabel': durationLabel,
        'deliveryMethod': deliveryMethod,
        'insurancePrice': insurancePrice,
        'tmPrice': tmPrice,
        'tdacPrice': tdacPrice,
        'passengerCount': passengerCount,
        'startDate': startDate is DateTime
            ? Timestamp.fromDate(startDate)
            : startDate,
        'endDate': endDate is DateTime
            ? Timestamp.fromDate(endDate)
            : endDate,
        'packages': packages,
        'delivery': {
          'method': deliveryMethod,
        },
        'pricing': {
          'totalPrice': widget.totalPrice,
          'insurancePrice': insurancePrice,
          'tmPrice': tmPrice,
          'tdacPrice': tdacPrice,
        },
        'totalPrice': widget.totalPrice,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
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

  @override
  Widget build(BuildContext context) {
    final packageType = _str(
      _m['packageType'],
      'Insurance Package',
    );
    final vehicleType = _str(_m['vehicleType']);
    final durationLabel = _str(
      _m['durationLabel'] ?? _m['duration'],
      '—',
    );
    final passengers = _m['passengerCount'] ??
        _m['passengers'] ??
        _m['trip']?['passengers'] ??
        1;
    final passengerText = '$passengers Person${passengers == 1 ? '' : 's'}';
    final delivery = _str(
      _m['deliveryMethod'] ?? _m['delivery']?['method'],
      'Via PDF',
    );
    final customerName = _str(
      _m['fullName'] ?? _m['name'] ?? _m['customer']?['name'],
    );
    final receiptId = _str(
      _m['orderId'],
      '—',
    );
    final where = _str(
      _m['destination'] ?? _m['where'] ?? _m['trip']?['borderRoute'],
    );
    final start = _m['startDate'] ??
        _m['departDate'] ??
        _m['travel']?['departDate'];
    final end = _m['endDate'] ??
        _m['returnDate'] ??
        _m['travel']?['returnDate'];

    var insurancePrice = _toDouble(_m['insurancePrice']);
    var tmPrice = _toDouble(
      _m['tmPrice'] ?? _m['tm23Price'],
    );
    var tdacPrice = _toDouble(_m['tdacPrice']);
    final total = widget.totalPrice;
    final hasBreakdown = insurancePrice > 0 || tmPrice > 0 || tdacPrice > 0;
    if (!hasBreakdown && total > 0) {
      insurancePrice = total;
      tmPrice = 0;
      tdacPrice = 0;
    }

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
                  _orderSummaryCard(
                    packageType: packageType,
                    vehicleType: vehicleType,
                    customerName: customerName,
                    receiptId: receiptId,
                    where: where,
                    start: start,
                    end: end,
                    durationLabel: durationLabel,
                    passengerText: passengerText,
                    delivery: delivery,
                    insurancePrice: insurancePrice,
                    tmPrice: tmPrice,
                    tdacPrice: tdacPrice,
                    total: total,
                    showFullBreakdown: hasBreakdown,
                  ),
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

  Widget _orderSummaryCard({
    required String packageType,
    required String vehicleType,
    required String customerName,
    required String receiptId,
    required String where,
    required dynamic start,
    required dynamic end,
    required String durationLabel,
    required String passengerText,
    required String delivery,
    required double insurancePrice,
    required double tmPrice,
    required double tdacPrice,
    required double total,
    required bool showFullBreakdown,
  }) {
    final pax = _m['passengerCount'] ??
        _m['passengers'] ??
        _m['trip']?['passengers'] ??
        1;
    final paxInt = pax is int ? pax : int.tryParse(pax.toString()) ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  packageType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3D72),
                  ),
                ),
              ),
              const Icon(Icons.directions_car_outlined,
                  color: Colors.grey, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5ECEA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  vehicleType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3D72),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                receiptId,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3D72),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summaryRow('Name', customerName),
          _summaryRow('Location', where),
          _summaryRow(
            'Travel',
            '${_formatDate(start)} - ${_formatDate(end)} ($durationLabel)',
          ),
          _summaryRow('Passengers', passengerText),
          _summaryRow('Delivery', delivery),
          const Divider(height: 24),
          if (showFullBreakdown) ...[
            Text(
              '1. $packageType ($durationLabel)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text('2. TM2/3'),
            const Text('3. TDAC'),
            const Divider(height: 24),
            _priceRow(
              '$packageType ($durationLabel)',
              insurancePrice,
            ),
            _priceRow('TM2/3', tmPrice),
            _priceRow('TDAC (RM2 × $paxInt)', tdacPrice),
          ] else
            _priceRow('Amount due', insurancePrice),
          const Divider(),
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
                _formatPrice(total),
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

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF6D7785),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(
            _formatPrice(amount),
            style: const TextStyle(fontWeight: FontWeight.w600),
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
}
