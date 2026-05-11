import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

/// Printable add-on receipt from [orderData] (history or post-payment).
class AddReceiptPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const AddReceiptPage({super.key, required this.orderData});

  @override
  State<AddReceiptPage> createState() => _AddReceiptPageState();
}

class _AddReceiptPageState extends State<AddReceiptPage> {
  final GlobalKey _receiptCaptureKey = GlobalKey();
  bool _downloading = false;

  String _fmtRm(double v) => 'RM${v.toStringAsFixed(2)}';

  double _toDouble(dynamic v) =>
      double.tryParse((v ?? 0).toString()) ?? 0.0;

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    if (raw is DateTime) dt = raw;
    if (dt == null) {
      final s = raw.toString().trim();
      return s.isEmpty ? '-' : s;
    }
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  List<Map<String, dynamic>> _addonLines() {
    final o = widget.orderData;
    final list = o['addonServices'];
    if (list is List && list.isNotEmpty) {
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    final name = (o['serviceName'] ?? 'Add-on').toString();
    final qty = o['quantity'] is int
        ? o['quantity'] as int
        : int.tryParse('${o['quantity'] ?? 1}') ?? 1;
    final price = _toDouble(o['totalPrice']);
    return [
      {'name': name, 'quantity': qty, 'price': price},
    ];
  }

  Future<void> _downloadReceipt() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;

      final boundary = _receiptCaptureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        _snack('Could not capture receipt');
        return;
      }

      final dpr = MediaQuery.devicePixelRatioOf(context);
      final image = await boundary.toImage(pixelRatio: dpr);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) {
        _snack('Could not encode receipt image');
        return;
      }

      final receiptId = widget.orderData['orderId'] ?? 'ADS-000';
      final safeId = receiptId.toString().replaceAll(RegExp(r'[^\w\-]+'), '_');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/addon_receipt_$safeId.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      final saved = await GallerySaver.saveImage(file.path);
      if (!mounted) return;
      if (saved == true) {
        _snack('Receipt saved to your gallery');
      } else {
        _snack('Could not save. Allow Photos / Storage access in settings.');
      }
    } catch (e) {
      if (mounted) _snack('Download failed: $e');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _customerName(Map<String, dynamic> order) {
    final direct = order['customerName']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final c = order['customer'];
    if (c is Map && c['name'] != null) {
      final s = c['name'].toString().trim();
      if (s.isNotEmpty) return s;
    }
    final fn = order['fullName']?.toString().trim();
    if (fn != null && fn.isNotEmpty) return fn;
    return '-';
  }

  String _customerPhone(Map<String, dynamic> order) {
    final direct = order['phoneNumber']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final c = order['customer'];
    if (c is Map && c['phone'] != null) {
      final s = c['phone'].toString().trim();
      if (s.isNotEmpty) return s;
    }
    final p = order['phone']?.toString().trim();
    if (p != null && p.isNotEmpty) return p;
    return '-';
  }

  String _receiptDateLine(Map<String, dynamic> order) {
    final s = (order['selectedDate'] ?? '').toString().trim();
    if (s.isNotEmpty) return s;
    final p = (order['pickupDate'] ?? '').toString().trim();
    if (p.isNotEmpty) return p;
    return _formatDate(order['createdAt']);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.orderData;
    final receiptId = order['orderId'] ?? 'ADS-000';
    final name = _customerName(order);
    final phone = _customerPhone(order);
    final dateLine = _receiptDateLine(order);
    final delivery =
        (order['deliveryMethod'] ?? order['delivery']?['method'] ?? '-')
            .toString();
    final totalPrice = _toDouble(
      order['totalPrice'] ??
          order['totalAmount'] ??
          order['pricing']?['totalPrice'],
    );
    final lines = _addonLines();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3F70),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Receipt',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: RepaintBoundary(
                key: _receiptCaptureKey,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              height: 52,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.shield_outlined,
                                size: 48,
                                color: Color(0xFF1D3F70),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ThaiDriveSecure',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1D3F70),
                                  ),
                                ),
                                Text(
                                  'by cnt enterprise',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF36A9A6),
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Receipt',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Receipt ID : $receiptId',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFE0E4EB)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('Name', name),
                            _infoRow('No.Phone', phone),
                            _infoRow('Date', dateLine),
                            _infoRow('Delivery Method', delivery),
                          ],
                        ),
                      ),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFE0E4EB)),
                      Padding(
                        padding: const EdgeInsets.only(top: 18, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(lines.length, (i) {
                            final row = lines[i];
                            final label = row['name']?.toString() ?? 'Item';
                            final qty = row['quantity'] is int
                                ? row['quantity'] as int
                                : int.tryParse('${row['quantity'] ?? 1}') ?? 1;
                            final price = _toDouble(row['price']);
                            final title =
                                qty == 1 ? label : '$label x$qty';
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: i == lines.length - 1 ? 0 : 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${i + 1}. $title',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1D3F70),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _fmtRm(price),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D3F70),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              _fmtRm(totalPrice),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF36A9A6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFEAF3F8),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D3F70),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _downloading ? null : _downloadReceipt,
                  child: _downloading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Download Receipt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
