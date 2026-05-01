import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thaidrivesecure/pages/voluPlus/voluPlusInsUpload_page.dart';

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
        builder: (_) => VoluPlusInsUpload(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          where: "$_from → $_to",
          whenDate:
              "${formatDate(_departDate)} – ${formatDate(_returnDate)} ($totalDays days)",
          passengerCount: _passenger,
          duration: _duration,
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
      backgroundColor: const Color(0xFFF0F2F6),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 18),
                child: Column(
                  children: [
                    _stepper(),
                    const SizedBox(height: 12),
                    _packageSection(),
                    const SizedBox(height: 12),
                    _noteBox(),
                    const SizedBox(height: 12),
                    _formCard(),
                  ],
                ),
              ),
            ),
            _bottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      color: const Color(0xFF1E3D72),
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              "Voluntary Plus Insurance Package",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepper() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(child: _step("1", "Personal\nInformations", true)),
          _line(),
          Expanded(child: _step("2", "Upload\nDocuments", false)),
          _line(),
          Expanded(child: _step("3", "Payment\n ", false)),
        ],
      ),
    );
  }

  Widget _step(String num, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF1E3D72) : const Color(0xFFE2E6EC),
            border: Border.all(
              color: active ? const Color(0xFF1E3D72) : const Color(0xFFD3D8E1),
            ),
          ),
          child: Text(
            num,
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

  Widget _line() {
    return Container(
      width: 58,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 26),
      color: const Color(0xFFDCE1E8),
    );
  }

  Widget _packageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 0, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Voluntary Plus\nInsurance Package",
                  style: TextStyle(
                    fontSize: 30,
                    height: 0.9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF143864),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2FA57D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.vehicleType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "INCLUDED ADD-ONS",
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF98A2B3),
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "TM2 / TM3 Form : RM8",
                  style: TextStyle(
                    color: Color(0xFF556070),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "TDAC : RM2 per person",
                  style: TextStyle(
                    color: Color(0xFF556070),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(vehicleImage, height: 120, fit: BoxFit.contain),
        ],
      ),
    );
  }

  Widget _noteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE2A100), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Please ensure the number of passengers is accurate for TDAC processing.",
              style: TextStyle(
                fontSize: 10.5,
                color: Color(0xFFCB2B39),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140D1A2B),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            inputField(
              "FULL NAME (As per official documents)",
              _nameController,
              icon: Icons.person_outline_rounded,
              hint: "John Doe",
              validator: (v) => v == null || v.isEmpty ? "Name required" : null,
            ),
            inputField(
              "NO. TELEPHONE",
              _phoneController,
              hint: "012-34567890",
              icon: Icons.call_outlined,
              keyboard: TextInputType.phone,
              maxLength: 11,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  v == null || v.length < 8 ? "Valid phone required" : null,
            ),
            Row(
              children: [
                Expanded(
                    child: dropdown(
                        "FROM", _from, fromPlaces, (v) => setState(() => _from = v!))),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EDF3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded,
                        size: 15, color: Color(0xFF718096)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        dropdown("TO", _to, toPlaces, (v) => setState(() => _to = v!))),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: calendarField(
                        "DEPARTURE DATE", formatDate(_departDate), () => pickDate(true))),
                const SizedBox(width: 8),
                Expanded(
                    child: calendarField(
                        "RETURN DATE", formatDate(_returnDate), () => pickDate(false))),
              ],
            ),
            dropdown("INSURANCE DURATION", _duration, durationList,
                (v) => setState(() => _duration = v!)),
            dropdown("PASSENGER", _passenger.toString(),
                List.generate(7, (i) => (i + 1).toString()),
                (v) => setState(() => _passenger = int.parse(v!))),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "  * Incorrect details may delay processing",
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFFA0A7B3),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Future<void> pickDate(bool isDepart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isDepart) {
          _departDate = picked;
          _returnDate = null;
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
    IconData? icon,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelText(label),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            inputFormatters: inputFormatters,
            validator: validator,
            maxLength: maxLength,
            style: const TextStyle(
              color: Color(0xFF44505E),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              counterText: "",
              hintText: hint ?? label,
              hintStyle: const TextStyle(
                color: Color(0xFFA9B1BC),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, size: 18, color: const Color(0xFF9AA3AE)),
              filled: true,
              fillColor: const Color(0xFFF1F3F6),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelText(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF818B98),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.25,
      ),
    );
  }

  Widget _dropdownDisplayText(String label, String value) {
    final bool isPassenger = label.toUpperCase() == "PASSENGER";
    final String displayValue = isPassenger ? "$value Person" : value;
    return Text(
      displayValue,
      style: const TextStyle(
        color: Color(0xFF44505E),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _calendarDisplayText(String value) {
    return Text(
      value.isEmpty ? "--/--/----" : value,
      style: TextStyle(
        color: value.isEmpty ? const Color(0xFFA9B1BC) : const Color(0xFF44505E),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _lightDropdownBox({
    required String label,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelText(label),
          const SizedBox(height: 5),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Expanded(child: child),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8C96A3), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return PopupMenuButton<String>(
      onSelected: (v) => onChanged(v),
      itemBuilder: (context) {
        final bool isPassenger = label.toUpperCase() == "PASSENGER";
        return items
            .map((e) => PopupMenuItem<String>(
                  value: e,
                  child: Text(
                    isPassenger ? "$e Person" : e,
                    style: const TextStyle(fontSize: 13),
                  ),
                ))
            .toList();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: IgnorePointer(
        child: _lightDropdownBox(
          label: label,
          child: _dropdownDisplayText(label, value),
        ),
      ),
    );
  }

  Widget calendarField(String label, String value, VoidCallback onTap) {
    return _lightDropdownBox(
      label: label,
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 16, color: Color(0xFF9AA3AE)),
          const SizedBox(width: 8),
          Expanded(child: _calendarDisplayText(value)),
        ],
      ),
    );
  }

  Widget _bottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2BAE9A),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: isLoading ? null : submit,
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Next",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
        ),
      ),
    );
  }
}
