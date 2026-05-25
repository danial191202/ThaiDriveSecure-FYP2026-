import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thaidrivesecure/addOnServices/reviewSummary_page.dart';

class Sim extends StatefulWidget {
  const Sim({super.key});

  @override
  State<Sim> createState() => _SimState();
}

class _SimState extends State<Sim> {
  final _formKey = GlobalKey<FormState>();
  int quantity = 1;
  String? deliveryMethod = 'Delivery';
  String pickupDate = '';
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE5EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF173F75),
        foregroundColor: Colors.white,
        title: const Text(
          'Add On Services',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          buildStepper(1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            _serviceCard(
              iconPath: 'assets/simCard.png',
              name: 'SIM',
              price: 'RM 29.00',
              description:
                  'Stay connected in Thailand with fast and reliable mobile data.',
            ),
            const SizedBox(height: 14),
            const Text(
              'Fill the requirement needed :',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _label('FULL NAME (As per official documents)'),
            _textField(
              hint: 'John Doe',
              icon: Icons.person,
              controller: _fullNameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter full name';
                }
                if (value.trim().length < 3) {
                  return 'Full name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            _label('NO. TELEPHONE'),
            _textField(
              hint: '0123 456 7890',
              icon: Icons.phone,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                if (value.length < 10) {
                  return 'Invalid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            _label('PICKUP DATE'),
            _datePickerField(),
            const SizedBox(height: 8),
            _label('DELIVERY METHOD'),
            _deliveryDropdown(),
            const SizedBox(height: 12),
            const Text(
              'SIM Examples:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _simExamplesGallery(),
                  const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                final double totalPrice = quantity * 29.0;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewSummaryPage(
                      fullName: _fullNameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      pickupDate: pickupDate,
                      deliveryMethod: deliveryMethod ?? 'Delivery',
                      serviceName: 'SIM',
                      quantity: quantity,
                      totalPrice: totalPrice,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF183F74),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _serviceCard({
    required String iconPath,
    required String name,
    required String price,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFC8D4F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            height: 88,
            child: Image.asset(iconPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4F5A69),
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 32, // adjust pill height
                  padding: const EdgeInsets.symmetric(horizontal: 3), // adjust spacing
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30), // adjust roundness
                    border: Border.all(
                      color: Colors.black,
                      width: 1.5, // adjust stroke thickness
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove),
                        iconSize: 20, // adjust icon size
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 6), // adjust spacing
                      Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6), // adjust spacing
                      IconButton(
                        onPressed: () => setState(() => quantity++),
                        icon: const Icon(Icons.add),
                        iconSize: 20, // adjust icon size
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6D7580),
      ),
    );
  }

  Widget _textField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFECEFF4),
        prefixIcon: Icon(icon, color: const Color(0xFF9BA2AE), size: 16),
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9BA2AE),
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D7E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D7E0)),
        ),
      ),
    );
  }

  Widget _deliveryDropdown() {
    return DropdownButtonFormField<String>(
      value: deliveryMethod,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFECEFF4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D7E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D7E0)),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF737B87)),
      items: const [
        DropdownMenuItem(value: 'Delivery', child: Text('Delivery')),
        DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select delivery method';
        }
        return null;
      },
      onChanged: (value) => setState(() => deliveryMethod = value),
    );
  }

  Future<void> _selectPickupDate() async {
    final DateTime now = DateTime.now();
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );

    if (selectedDate == null) return;
    setState(() {
      pickupDate =
          '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
    });
  }

  Widget _datePickerField() {
    return GestureDetector(
      onTap: _selectPickupDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFECEFF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1D7E0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF9BA2AE),
              size: 16,
            ),
            const SizedBox(width: 10),
            Text(
              pickupDate.isEmpty ? 'DD/MM/YYYY' : pickupDate,
              style: TextStyle(
                color: pickupDate.isEmpty
                    ? const Color(0xFF9BA2AE)
                    : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// sim2 (portrait) + sim3 (landscape) — same row height, sized to fit sim3.
  Widget _simExamplesGallery() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D7E0)),
      ),
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 6.0;
          // Full-width 16:9 height so both images render larger in the row.
          final rowHeight = constraints.maxWidth * (1125 / 2000);

          return SizedBox(
            height: rowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/sim2.png',
                      height: rowHeight,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  flex: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/sim3.png',
                      height: rowHeight,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
