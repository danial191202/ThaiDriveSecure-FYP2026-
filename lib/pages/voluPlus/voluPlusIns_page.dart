import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thaidrivesecure/pages/volu/voluInsUpload_page.dart';

class VoluPlusIns extends StatefulWidget {
  final String vehicleType;

  const VoluPlusIns({super.key, required this.vehicleType});

  @override
  State<VoluPlusIns> createState() => _VoluPlusInsState();
}

class _VoluPlusInsState extends State<VoluPlusIns> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<String> fromPlaces = [
    "Bukit Kayu Hitam",
    "Wang Kelian",
    "Padang Besar",
    "Durian Burung",
  ];

  final List<String> toPlaces = [
    "Hat Yai",
    "Bangkok",
    "Pattani",
    "Krabi",
    "Koh Samui",
    "Phuket",
  ];

  String _from = "Bukit Kayu Hitam";
  String _to = "Hat Yai";

  int _passenger = 1;

  DateTime? _departDate;
  DateTime? _returnDate;

  bool isLoading = false;
  bool isPressed = false;

  String _duration = "9 Days";

  List<String> get durationList {
    if (widget.vehicleType == "Motorcycle") {
      return ["3 Months", "6 Months", "1 Year"];
    }

    return ["9 Days", "19 Days", "1 Month", "3 Months", "6 Months", "1 Year"];
  }

  String formatDate(DateTime? date) {
    if (date == null) return "";
    return "${date.day}/${date.month}/${date.year}";
  }

  int get totalDays {
    if (_departDate == null || _returnDate == null) return 0;
    return _returnDate!.difference(_departDate!).inDays + 1;
  }

  String get vehicleImage {
    switch (widget.vehicleType) {
      case "Pickup/SUV":
        return "assets/suv.png";
      case "MPV":
        return "assets/mpv.png";
      case "Motorcycle":
        return "assets/motorcycle.png";
      case "Sedan":
      default:
        return "assets/sedan1.png";
    }
  }

  @override
  void initState() {
    super.initState();

    // Make sure default duration is valid for selected vehicle
    if (widget.vehicleType == "Motorcycle") {
      _duration = "3 Months";
    } else {
      _duration = "9 Days";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate() ||
        _departDate == null ||
        _returnDate == null ||
        _returnDate!.isBefore(_departDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields correctly")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      isPressed = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      isLoading = false;
      isPressed = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoluInsUpload(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          where: "$_from → $_to",
          whenDate:
              "${formatDate(_departDate)} – ${formatDate(_returnDate)} ($totalDays days)",
          passengerCount: _passenger,
          duration: _duration,
          deliveryMethod: "Take Away",
          vehicleType: widget.vehicleType,
          departDate: _departDate!,
          returnDate: _returnDate!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(color: Color(0xFF163B6D)),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Image.asset(vehicleImage, height: 120),
                  const SizedBox(height: 12),
                  const Text(
                    "Voluntary Package",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(
                    color: Colors.white54,
                    thickness: 1,
                    indent: 40,
                    endIndent: 40,
                  ),
                  Text(
                    "Type of Vehicle: ${widget.vehicleType}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Insurance : Compulsory"),
                    const SizedBox(height: 6),
                    const Text(
                      "TM2/3 : Driver’s Car Information",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    inputField(
                      "Name",
                      _nameController,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Name required" : null,
                    ),

                    inputField(
                      "No. Telephone",
                      _phoneController,
                      keyboard: TextInputType.phone,
                      maxLength: 11,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v == null || v.length < 8
                          ? "Valid phone required"
                          : null,
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: dropdown(
                            "From",
                            _from,
                            fromPlaces,
                            (v) => setState(() => _from = v!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: dropdown(
                            "To",
                            _to,
                            toPlaces,
                            (v) => setState(() => _to = v!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: calendarField(
                            label: "Depart date",
                            value: formatDate(_departDate),
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );

                              if (picked != null) {
                                setState(() {
                                  _departDate = picked;
                                  _returnDate = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: calendarField(
                            label: "Return date",
                            value: formatDate(_returnDate),
                            onTap: _departDate == null
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Select depart date first",
                                        ),
                                      ),
                                    );
                                  }
                                : () async {
                                    DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: _departDate!,
                                      firstDate: _departDate!,
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );

                                    if (picked != null) {
                                      setState(() => _returnDate = picked);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    dropdown(
                      "Passenger",
                      _passenger.toString(),
                      List.generate(7, (i) => (i + 1).toString()),
                      (v) => setState(() => _passenger = int.parse(v!)),
                    ),

                    const SizedBox(height: 15),

                    dropdown(
                      "Insurance Duration",
                      _duration,
                      durationList,
                      (v) => setState(() => _duration = v!),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: AnimatedScale(
                        scale: isPressed ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF163B6D),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 70,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: isLoading ? null : submit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Next",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: validator,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          counterText: "",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget calendarField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value.isEmpty ? "Select date" : value),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}
