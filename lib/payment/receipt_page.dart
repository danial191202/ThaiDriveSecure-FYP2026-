import 'package:flutter/material.dart';
import 'package:thaidrivesecure/screens/home_page.dart';

class ReceiptPage extends StatelessWidget {
  final double totalAmount;
  final String orderId;
  final List<String> selectedItems;

  const ReceiptPage({
    super.key,
    required this.totalAmount,
    required this.orderId,
    required this.selectedItems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Receipt",
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// Success Icon
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 90,
            ),

            const SizedBox(height: 10),

            /// Order ID
            Text(
              orderId,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Payment is completed",
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 24),

            /// Selected Packages / Items
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: selectedItems.map((item) {
                    return ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(item),
                      trailing: const Text("Included"),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Total Amount
            const Text(
              "Total Amount",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "RM ${totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            /// Finish Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF163B6D),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
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
                  "Finish",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}