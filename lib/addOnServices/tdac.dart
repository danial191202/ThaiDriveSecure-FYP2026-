import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thaidrivesecure/addOnServices/reviewSummary_page.dart';

class Tdac extends StatefulWidget {
  const Tdac({super.key});

  @override
  State<Tdac> createState() => _TdacState();
}

class _TdacState extends State<Tdac> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  int quantity = 1;
  String? deliveryMethod = 'Delivery';
  int passengerCount = 1;
  List<File?> passportFiles = [null];
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
        centerTitle: true,
        title: const Text(
          'Add On Services',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
            _label('DELIVERY METHOD'),
            _deliveryDropdown(),
            const SizedBox(height: 8),
            _label('PASSENGER'),
            _passengerDropdown(),
            const SizedBox(height: 6),
            const Text(
              '* incorrect details may delay processing',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9AA3AE),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(passengerCount, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _uploadCard(
                  index: index,
                  imageFile: passportFiles[index],
                  onTap: () async {
                    final file = await _pickImageSource();
                    if (file == null) return;
                    setState(() {
                      passportFiles[index] = file;
                    });
                  },
                ),
              );
            }),
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
                final bool hasMissingUpload = passportFiles.any((file) => file == null);
                if (hasMissingUpload) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please upload required document'),
                    ),
                  );
                  return;
                }
                final double totalPrice = quantity * 2.0;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewSummaryPage(
                      fullName: _fullNameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      deliveryMethod: deliveryMethod ?? 'Delivery',
                      serviceName: 'TDAC',
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

  Widget _serviceCard() {
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
            width: 90,
            child: Image.asset('assets/TDAC.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TDAC',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'RM 2.00',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Complete your Thailand Digital Arrival Card quickly and hassle-free.',
                  style: TextStyle(
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

  Widget _passengerDropdown() {
    return DropdownButtonFormField<int>(
      value: passengerCount,
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
        DropdownMenuItem(value: 1, child: Text('1 Person')),
        DropdownMenuItem(value: 2, child: Text('2 Person')),
        DropdownMenuItem(value: 3, child: Text('3 Person')),
        DropdownMenuItem(value: 4, child: Text('4 Person')),
        DropdownMenuItem(value: 5, child: Text('5 Person')),
      ],
      validator: (value) {
        if (value == null) return 'Please select passenger';
        return null;
      },
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          passengerCount = value;
          if (passportFiles.length < passengerCount) {
            passportFiles.addAll(
              List.generate(passengerCount - passportFiles.length, (_) => null),
            );
          } else if (passportFiles.length > passengerCount) {
            passportFiles = passportFiles.sublist(0, passengerCount);
          }
        });
      },
    );
  }

  Widget _uploadCard({
    required int index,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    final bool uploaded = imageFile != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: uploaded ? const Color(0xFF5AC8BE) : const Color(0xFFE1E7F2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge, color: Color(0xFF254C80), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identification Card or Passport',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF254C80),
                      ),
                    ),
                    Text(
                      'Passenger ${index + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5B6A7B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (uploaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            onTap: onTap,
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
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80);
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
