import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Receipt view for add-on orders from history (read-only + download).
class AddReceiptHistoryPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const AddReceiptHistoryPage({super.key, required this.orderData});

  @override
  State<AddReceiptHistoryPage> createState() => _AddReceiptHistoryPageState();
}

class _AddReceiptHistoryPageState extends State<AddReceiptHistoryPage> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isSaving = false;

  static const Color _darkBlue = Color(0xFF1D3567);
  static const Color _teal = Color(0xFF4DB6AC);
  static const Color _itemBlue = Color(0xFF3F51B5);
  static const Color _footerBg = Color(0xFFEBF2F8);

  String _customerName() {
    final d = widget.orderData;
    final n = d['customerName'] ?? d['name'] ?? d['fullName'];
    if (n != null && n.toString().trim().isNotEmpty) return n.toString();
    return '—';
  }

  String _phone() {
    final d = widget.orderData;
    final p = d['phoneNumber'] ?? d['phone'] ?? d['contactPhone'];
    if (p != null && p.toString().trim().isNotEmpty) return p.toString();
    return '—';
  }

  String _deliveryMethod() {
    final d = widget.orderData;
    final m = d['deliveryMethod'] ?? d['delivery'] ?? d['pickupMethod'];
    if (m != null && m.toString().trim().isNotEmpty) return m.toString();
    return 'Pickup';
  }

  String _receiptId() {
    final d = widget.orderData;
    final id = d['receiptId'] ?? d['orderId'] ?? d['id'];
    if (id != null && id.toString().trim().isNotEmpty) return id.toString();
    return 'TDS-—';
  }

  String _dateLine() {
    final d = widget.orderData;
    final raw = d['createdAt'] ?? d['date'] ?? d['orderDate'];
    if (raw is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(raw.toDate());
    }
    if (raw is DateTime) {
      return DateFormat('dd/MM/yyyy').format(raw);
    }
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString();
    }
    return DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  String _fmtMoney(dynamic v) {
    if (v == null) return 'RM0.00';
    if (v is num) return 'RM${v.toDouble().toStringAsFixed(2)}';
    final s = v.toString().trim();
    if (s.isEmpty) return 'RM0.00';
    if (s.toUpperCase().startsWith('RM')) return s;
    final parsed = double.tryParse(s);
    if (parsed != null) return 'RM${parsed.toStringAsFixed(2)}';
    return s;
  }

  List<Map<String, dynamic>> _addonLines() {
    final d = widget.orderData;
    final list = d['addonServices'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final name = d['serviceName']?.toString();
    if (name != null && name.isNotEmpty) {
      return [
        {
          'name': name,
          'quantity': d['quantity'] ?? 1,
          'totalPrice': d['totalPrice'] ?? d['price'] ?? 0,
        },
      ];
    }
    return [];
  }

  double _grandTotal() {
    final d = widget.orderData;
    final t = d['totalAmount'] ?? d['total'] ?? d['amount'];
    if (t is num) return t.toDouble();
    if (t != null) {
      final parsed = double.tryParse(t.toString());
      if (parsed != null) return parsed;
    }
    double sum = 0;
    for (final line in _addonLines()) {
      final p = line['totalPrice'] ?? line['price'];
      if (p is num) sum += p.toDouble();
      else {
        final parsed = double.tryParse(p?.toString() ?? '');
        if (parsed != null) sum += parsed;
      }
    }
    return sum;
  }

  Future<void> _downloadReceipt() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      final boundary =
          _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not capture receipt.')),
          );
        }
        return;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not encode receipt image.')),
          );
        }
        return;
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      final ok = await GallerySaver.saveImage(path, albumName: 'ThaiDriveSecure');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok == true ? 'Receipt saved to gallery.' : 'Save failed.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = _addonLines();
    final totalStr = _fmtMoney(_grandTotal());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Receipt'),
        backgroundColor: _darkBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: RepaintBoundary(
                key: _receiptKey,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            height: 56,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shield_outlined,
                              size: 48,
                              color: _darkBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ThaiDriveSecure',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _darkBlue,
                                  ),
                                ),
                                Text(
                                  'by cnt enterprise',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _teal,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Receipt',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Receipt ID : ${_receiptId()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(height: 28, thickness: 1),
                      _detailRow('Name :', _customerName()),
                      _detailRow('No.Phone :', _phone()),
                      _detailRow('Date :', _dateLine()),
                      _detailRow('Delivery Method :', _deliveryMethod()),
                      const Divider(height: 28, thickness: 1),
                      if (lines.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No line items',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      else
                        ...List.generate(lines.length, (i) {
                          final line = lines[i];
                          final name = line['name']?.toString() ?? 'Item';
                          final qty = line['quantity'];
                          final label = qty != null
                              ? '${i + 1}. $name (x$qty)'
                              : '${i + 1}. $name';
                          final price = _fmtMoney(
                            line['totalPrice'] ?? line['price'],
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _itemBlue,
                                    ),
                                  ),
                                ),
                                Text(
                                  price,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _itemBlue,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const Divider(height: 28, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            totalStr,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _teal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: _footerBg,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _downloadReceipt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black26,
                    shape: const StadiumBorder(),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Download Receipt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          children: [
            TextSpan(text: label),
            TextSpan(
              text: ' $value',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
