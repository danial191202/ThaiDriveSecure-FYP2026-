import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class ReceiptHistoryPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const ReceiptHistoryPage({super.key, required this.order});

  @override
  State<ReceiptHistoryPage> createState() => _ReceiptHistoryPageState();
}

class _ReceiptHistoryPageState extends State<ReceiptHistoryPage> {
  final GlobalKey _receiptCaptureKey = GlobalKey();
  bool _downloading = false;

  String _fmt(double v) => "RM ${v.toStringAsFixed(2)}";

  String _formatDate(dynamic raw) {
    if (raw == null) return "-";
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    if (raw is DateTime) dt = raw;
    if (dt == null) return raw.toString();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return "$d/$m/${dt.year}";
  }

  double _toDouble(dynamic v) =>
      double.tryParse((v ?? 0).toString()) ?? 0.0;

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

      final receiptId = widget.order['orderId'] ?? "TDS-000";
      final safeId = receiptId.toString().replaceAll(RegExp(r'[^\w\-]+'), '_');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/receipt_$safeId.png');
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

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final receiptId = order['orderId'] ?? "TDS-000";
    final name = order['customer']?['name'] ?? order['fullName'] ?? "-";
    final phone = order['customer']?['phone'] ?? order['phone'] ?? "-";
    final dateText = _formatDate(order['createdAt']);
    final delivery =
        order['deliveryMethod'] ?? order['delivery']?['method'] ?? "Via PDF";

    final packageType =
        (order['packageType'] ?? "Compulsory").toString().replaceFirst(
              RegExp(r'^Insurance\s*'),
              '',
            );
    final vehicleType =
        (order['vehicleType'] ?? order['trip']?['vehicleType'] ?? "").toString();
    final duration = order['duration'] ?? order['travel']?['days'] ?? 0;
    final passengers =
        order['passengerCount'] ?? order['trip']?['passengers'] ?? 1;

    final insurancePrice = _toDouble(order['insurancePrice']);
    final tmPrice =
        _toDouble(order['tmPrice'] ?? order['pricing']?['tmPrice'] ?? 8);
    final tdacPrice = _toDouble(order['tdacPrice']);
    final totalPrice =
        _toDouble(order['totalPrice'] ?? order['pricing']?['totalPrice']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3F70),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Receipt",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── scrollable receipt card ──────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: RepaintBoundary(
                key: _receiptCaptureKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                  children: [
                    // ── HEADER ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Column(
                        children: [
                          // logo + brand
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/logo.png",
                                height: 52,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.directions_car,
                                  size: 52,
                                  color: Color(0xFF1D3F70),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "ThaiDriveSecure",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1D3F70),
                                    ),
                                  ),
                                  Text(
                                    "by cnt enterprise",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF36A9A6),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "Receipt",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Receipt ID : $receiptId",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEF0F5)),

                    // ── INFO SECTION ──────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow("Name", name),
                          _infoRow("No.Phone", phone),
                          _infoRow("Date", dateText),
                          _infoRow("Delivery Method", delivery),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFEEF0F5)),

                    // ── ITEMS ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      child: Column(
                        children: [
                          _itemRow(
                            number: "1.",
                            label:
                                "Insurance $packageType ($duration Days)",
                            subtitle: vehicleType.isNotEmpty
                                ? vehicleType
                                : null,
                            price: insurancePrice,
                          ),
                          const SizedBox(height: 14),
                          _itemRow(
                            number: "2.",
                            label: "TM2/3",
                            subtitle: null,
                            price: tmPrice,
                          ),
                          const SizedBox(height: 14),
                          _itemRow(
                            number: "3.",
                            label: "TDAC",
                            subtitle: "Person x$passengers",
                            price: tdacPrice,
                          ),
                        ],
                      ),
                    ),

                    // ── TOTAL ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: const Divider(color: Color(0xFFDDE3EC)),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _fmt(totalPrice),
                            style: const TextStyle(
                              fontSize: 22,
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

          // ── DOWNLOAD BUTTON ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Saving…",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        "Download Receipt",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── info row ──────────────────────────────────────────────
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
              text: "$label : ",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // ── item row ──────────────────────────────────────────────
  Widget _itemRow({
    required String number,
    required String label,
    required String? subtitle,
    required double price,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D3F70),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          _fmt(price),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

