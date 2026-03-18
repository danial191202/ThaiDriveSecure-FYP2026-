import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Widget _buildCard({
    required String title,
    required String description,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildCard(
              title: "Package Compulsory (Sedan)",
              description:
                  "- Insurance Compulsory Sedan (7 Days)\n- TM2/3\n- TDAC\nAdd On: Towing",
              status: "Completed",
              statusColor: Colors.green,
            ),
            _buildCard(
              title: "Package Compulsory (Motorcycle)",
              description:
                  "- Insurance Compulsory Motorcycle (3 Months)\n- TM2/3\n- TDAC\nAdd On: Authorize Letter",
              status: "Pending",
              statusColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}
