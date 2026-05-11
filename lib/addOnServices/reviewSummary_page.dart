import 'package:flutter/material.dart';
import '../payment/payment_page.dart';

class ReviewSummaryPage extends StatelessWidget {
  final String fullName;
  final String phone;
  final String pickupDate;
  final String deliveryMethod;
  final String serviceName;
  final int quantity;
  final double totalPrice;

  const ReviewSummaryPage({
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
  Widget build(BuildContext context) {
    final sharedTotalPrice = totalPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFDCE5EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF173F75),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Add On Services',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: Column(
            children: [
              buildStepper(2),
              const SizedBox(height: 12),
              const Text(
                'Review Summary',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F3B6D),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelValue('Name', fullName),
                    const SizedBox(height: 10),
                    _labelValue('No.Telephone', phone),
                    const SizedBox(height: 10),
                    _labelValue('Pickup Date', pickupDate),
                    const SizedBox(height: 10),
                    _labelValue('Delivery Method', deliveryMethod),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.black54),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Service',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF7A8593),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$serviceName x$quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'RM ${sharedTotalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Colors.black54),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'RM ${sharedTotalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F3B6D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentPage(totalPrice: sharedTotalPrice),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF173F75),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                    child: const Text(
                    'Checkout',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF7A8593),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget buildStepper(int currentStep) {
    Widget step(int number, String label) {
      final bool active = currentStep == number;
      return Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFF1E3D72) : const Color(0xFFE2E6EC),
              border: Border.all(
                color: active
                    ? const Color(0xFF1E3D72)
                    : const Color(0xFFD3D8E1),
              ),
            ),
            child: Text(
              '$number',
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

    Widget connector() {
      return Container(
        width: 70,
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 26),
        color: const Color(0xFFDCE1E8),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(child: step(1, 'Personal\nInformations')),
          connector(),
          Expanded(child: step(2, 'Upload\nDocuments')),
          connector(),
          Expanded(child: step(3, 'Payment\n ')),
        ],
      ),
    );
  }
}