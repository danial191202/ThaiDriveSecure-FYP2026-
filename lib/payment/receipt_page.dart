import 'package:flutter/material.dart';
import 'dart:io';
import 'package:thaidrivesecure/screens/home_page.dart';

class ReceiptPage extends StatefulWidget {
  final double totalAmount;
  final String orderId;
  final List<String> selectedItems;
  final dynamic receiptImage;
  final DateTime createdAt;
  final int receiptCounter;

  const ReceiptPage({
    super.key,
    required this.totalAmount,
    required this.orderId,
    required this.selectedItems,
    required this.receiptImage,
    required this.createdAt,
    required this.receiptCounter,
  });

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  bool _showTick = false;

  String generateReceiptId(int counter) {
    final normalized = ((counter - 1) % 999) + 1;
    return 'TDS-${normalized.toString().padLeft(3, '0')}';
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day/$month/$year';
  }

  String _formatTime(DateTime dt) {
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showTick = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3F70),
        elevation: 0,
        title: const Text(
          'Upload Success',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSuccessHeader(theme),
              const SizedBox(height: 18),
              _buildReceiptCard(),
              const SizedBox(height: 16),
              _buildWhatsNext(),
              const SizedBox(height: 16),
              _buildButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Column(
        children: [
          AnimatedScale(
            scale: _showTick ? 1 : 0,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutBack,
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF3CB54A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3CB54A).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 46),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Receipt Submitted\nSuccessfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 31 / 1.35,
              fontWeight: FontWeight.w700,
              color: Color(0xFF131A28),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your payment receipt has been received and is being verified by our staffs. This usually takes less than 2 hours.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7D8896),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A4C6A95),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receipt ID: ${generateReceiptId(widget.receiptCounter)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Date: ${_formatDate(widget.createdAt)}    Time: ${_formatTime(widget.createdAt)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8A94A3),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE6EAF0)),
          const SizedBox(height: 10),
          const Text(
            'DOCUMENT UPLOADED',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.4,
              color: Color(0xFF97A1AF),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Color(0xFF3CB54A)),
                SizedBox(width: 8),
                Text(
                  'bank_slip.pdf',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CustomPaint(
            painter: _DashedBorderPainter(
              color: const Color(0xFFB7C0CE),
              strokeWidth: 1,
              dashWidth: 6,
              dashSpace: 4,
              radius: 10,
            ),
            child: Container(
              height: 100,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildPreviewImage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsNext() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F1FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4E2F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "WHAT'S NEXT?",
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.5,
              color: Color(0xFF72839A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildStepItem(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF3CB54A),
            title: 'Payment Received',
          ),
          const SizedBox(height: 10),
          _buildStepItem(
            icon: Icons.pending,
            iconColor: const Color(0xFFF2B01E),
            title: 'Next: Application Review',
            subtitle:
                'Our staffs will review your coverage details once payment is cleared',
          ),
          const SizedBox(height: 10),
          _buildStepItem(
            icon: Icons.radio_button_unchecked,
            iconColor: const Color(0xFFBDC5D2),
            title: 'Insurance Issued',
            subtitle: 'Your insurance package will be sent to email',
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 19, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.4,
                  color: Color(0xFF1A2433),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.2,
                    height: 1.35,
                    color: Color(0xFF7D8896),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF45C2B8), Color(0xFF2EA7A0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2EA7A0),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          },
          icon: const Text(
            'Back to Home',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          label: const Icon(Icons.arrow_forward, color: Colors.white, size: 19),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewImage() {
    final image = widget.receiptImage;

    if (image is File) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          image,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (image is String && image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          image,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPreviewPlaceholder(),
        ),
      );
    }

    return _buildPreviewPlaceholder();
  }

  Widget _buildPreviewPlaceholder() {
    return const Row(
      children: [
        Icon(Icons.image_outlined, color: Color(0xFF96A1AF), size: 28),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Receipt preview placeholder',
            style: TextStyle(
              color: Color(0xFF8D97A5),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.radius != radius;
  }
}