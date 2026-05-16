import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool isPasswordVisible = false;

  String _authErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return _messageForAuthCode(error.code);
    }
    final text = error.toString().toLowerCase();
    for (final code in const [
      'invalid-email',
      'user-not-found',
      'wrong-password',
      'invalid-credential',
      'too-many-requests',
      'network-request-failed',
    ]) {
      if (text.contains(code)) return _messageForAuthCode(code);
    }
    return 'Login failed. Please try again.';
  }

  String _messageForAuthCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email format';
      case 'user-not-found':
        return 'Account not found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Email or password is incorrect';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return 'Login failed. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final user = await _authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      _showError(_authErrorMessage(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFEAF6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      /// ✅ SCROLLABLE BODY
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// Title
              const Text(
                "Welcome to ThaiDriveSecure",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 40),

              /// Email
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: inputStyle("Email"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Password
              TextFormField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: inputStyle("Password").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// Sign up text
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Don’t have an account yet? ",
                      style: TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: "Start here",
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              /// Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Log in",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 250),

              /// Footer Logo
              Center(
                child: Image.asset(
                  'assets/tsdLogoPjg.png',
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
