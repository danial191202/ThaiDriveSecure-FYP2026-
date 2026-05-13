import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thaidrivesecure/addOnServices/reviewSummary_page.dart';

class Towing extends StatefulWidget {
  const Towing({super.key});

  @override
  State<Towing> createState() => _TowingState();
}

class _TowingState extends State<Towing> {
  static const Map<String, double> towingPrices = {
    '1 Day': 19,
    '3 Days': 39,
    '7 Days': 59,
    '14 Days': 89,
    '30 Days': 149,
  };

  static const List<String> _durationKeys = [
    '1 Day',
    '3 Days',
    '7 Days',
    '14 Days',
    '30 Days',
  ];

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  int quantity = 1;
  String selectedDuration = '1 Day';
  String? deliveryMethod = 'Delivery';
  String pickupDate = '';

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  File? vehicleRegistrationFile;
  File? idPassportFile;

  double get _unitPrice => towingPrices[selectedDuration] ?? 19;

  double get _lineTotal => quantity * _unitPrice;

  String _formatRm(double v) => 'RM ${v.toStringAsFixed(2)}';

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
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
          buildStepper(2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _serviceCard(),
                    const SizedBox(height: 14),
                    _towingDetailsCard(),
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    _label('Destination Location'),
                    _textField(
                      hint: 'Hotel',
                      icon: Icons.location_on_outlined,
                      controller: _destinationController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter destination';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _label('Duration'),
                    _durationDropdown(),
                    const SizedBox(height: 12),
                    _label('Pickup Date'),
                    _pickupDateField(),
                    const SizedBox(height: 12),
                    _label('DELIVERY METHOD'),
                    _deliveryDropdown(),
                    const SizedBox(height: 14),
                    _vehicleRegistrationCard(),
                    const SizedBox(height: 10),
                    _idPassportCard(),
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
                if (pickupDate.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select pickup date')),
                  );
                  return;
                }
                if (vehicleRegistrationFile == null || idPassportFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please upload required documents'),
                    ),
                  );
                  return;
                }
                final double totalPrice = _lineTotal;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewSummaryPage(
                      fullName: _fullNameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      pickupDate: pickupDate,
                      deliveryMethod: deliveryMethod ?? 'Delivery',
                      serviceName: 'Towing',
                      quantity: quantity,
                      totalPrice: totalPrice,
                      durationLabel: selectedDuration,
                      destinationLocation:
                          _destinationController.text.trim(),
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

  Widget _serviceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE2EEF8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Image.asset('assets/towing.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Towing',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'From ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      TextSpan(
                        text: _formatRm(_unitPrice),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Drive with confidence knowing emergency towing assistance is available.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4F5A69),
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove),
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => setState(() => quantity++),
                        icon: const Icon(Icons.add),
                        iconSize: 20,
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

  Widget _towingDetailsCard() {
    const titleStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: Color(0xFF173F75),
    );
    const sectionStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Color(0xFF1A2433),
    );
    const bulletStyle = TextStyle(
      fontSize: 12.5,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: Color(0xFF4F5A69),
    );

    Widget bulletLine(String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: bulletStyle),
            Expanded(child: Text(text, style: bulletStyle)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EDF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC5D6EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Towing Details', style: titleStyle),
          const SizedBox(height: 12),
          const Text('Includes', style: sectionStyle),
          bulletLine('10–20KM towing'),
          bulletLine('Sedan support'),
          bulletLine('Emergency assistance'),
          bulletLine('Tyre assistance'),
          bulletLine('Workshop delivery'),
          const SizedBox(height: 10),
          const Text('Suitable For', style: sectionStyle),
          bulletLine('Minor breakdown'),
          bulletLine('Nearby towing'),
          bulletLine('Family travel'),
          bulletLine('Cross-border driving'),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6D7580),
        ),
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
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: const Color(0xFF9BA2AE), size: 16),
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9BA2AE),
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  Widget _durationDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedDuration,
      decoration: _dropdownDecoration(
        prefix: const Icon(
          Icons.calendar_today_outlined,
          color: Color(0xFF9BA2AE),
          size: 16,
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF737B87)),
      items: _durationKeys
          .map(
            (k) => DropdownMenuItem<String>(
              value: k,
              child: Text(k),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => selectedDuration = value);
      },
      validator: (v) => v == null || v.isEmpty ? 'Please select duration' : null,
    );
  }

  Widget _deliveryDropdown() {
    return DropdownButtonFormField<String>(
      value: deliveryMethod,
      decoration: _dropdownDecoration(
        prefix: const Icon(
          Icons.local_shipping_outlined,
          color: Color(0xFF9BA2AE),
          size: 16,
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

  InputDecoration _dropdownDecoration({required Widget prefix}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D7E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D7E0)),
      ),
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

  Widget _pickupDateField() {
    return GestureDetector(
      onTap: _selectPickupDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1D7E0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                pickupDate.isEmpty ? 'DD/MM/YYYY' : pickupDate,
                style: TextStyle(
                  color: pickupDate.isEmpty
                      ? const Color(0xFF9BA2AE)
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF737B87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleRegistrationCard() {
    final bool uploaded = vehicleRegistrationFile != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE37474), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car,
                  color: Color(0xFF254C80), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Registration',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF254C80),
                      ),
                    ),
                    Text(
                      'Grant/VOC',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5B6A7B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE8EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'REQUIRED',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final file = await _pickImageSource();
              if (file == null) return;
              setState(() => vehicleRegistrationFile = file);
            },
            child: uploaded
                ? _uploadedPreview(vehicleRegistrationFile!)
                : _emptyUploadBox(),
          ),
        ],
      ),
    );
  }

  Widget _idPassportCard() {
    final File? imageFile = idPassportFile;
    final bool uploaded = imageFile != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5AC8BE), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge, color: Color(0xFF254C80), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Identification Card or Passport',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF254C80),
                  ),
                ),
              ),
              if (uploaded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9F5EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'UPLOADED',
                    style: TextStyle(
                      color: Color(0xFF26B39E),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final file = await _pickImageSource();
              if (file == null) return;
              setState(() => idPassportFile = file);
            },
            child: uploaded ? _uploadedPreview(imageFile) : _emptyUploadBox(),
          ),
        ],
      ),
    );
  }

  Widget _emptyUploadBox() {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: const Color(0xFF8FC1FF),
        radius: 12,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: const Column(
          children: [
            Icon(Icons.camera_alt, color: Color(0xFF3C5A84), size: 28),
            SizedBox(height: 6),
            Text(
              'Tap to upload',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2A3950),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'PDF, JPG OR PNG (MAX 10MB)',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8B95A3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadedPreview(File file) {
    final String fileName = file.path.split(Platform.pathSeparator).last;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: double.infinity,
            height: 138,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<File?> _pickImageSource() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return null;
    final XFile? picked =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return null;
    return File(picked.path);
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 6;
    const double dashSpace = 4;
    final rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final Path path = Path()..addRRect(rRect);
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
