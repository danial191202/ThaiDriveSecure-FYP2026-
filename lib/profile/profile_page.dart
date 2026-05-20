import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thaidrivesecure/profile/notification_page.dart';
import 'package:thaidrivesecure/screens/welcome_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _navy = Color(0xFF1D3F70);
  static const Color _pageBg = Color(0xFFF0F4F8);
  static const Color _iconBg = Color(0xFFE8B88C);

  String _displayName = '';
  String _email = '';
  String _phoneNumber = '';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }

    var name = user.displayName ?? '';
    var phone = '';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        name = (data?['fullName'] ?? name).toString();
        phone = (data?['phone'] ?? '').toString();
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _displayName = name.isNotEmpty ? name : 'User';
      _email = user.email ?? '';
      _phoneNumber = phone;
      _isLoadingProfile = false;
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _navy,
      ),
    );
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return 'Phone number must be 10-11 digits';
    }
    if (phone.length < 10 || phone.length > 11) {
      return 'Phone number must be 10-11 digits';
    }
    return null;
  }

  Future<void> _saveProfile(String name, String phone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Not logged in',
      );
    }

    final uid = user.uid;

    // Refresh auth token so Firestore sees a valid signed-in user.
    await user.getIdToken(true);

    final profileRef =
        FirebaseFirestore.instance.collection('users').doc(uid);
    final profileData = {
      'fullName': name,
      'phone': phone,
      'email': user.email,
      'userId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final existing = await profileRef.get();
    if (existing.exists) {
      await profileRef.update(profileData);
    } else {
      await profileRef.set({
        ...profileData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    try {
      if (user.displayName != name) {
        await user.updateDisplayName(name);
        await user.reload();
      }
    } catch (_) {
      // Firestore profile is saved; Auth displayName is best-effort.
    }

    if (!mounted) return;
    setState(() {
      _displayName = name;
      _phoneNumber = phone;
    });
  }

  void _openManageUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _displayName);
    final phoneController = TextEditingController(text: _phoneNumber);
    var isSaving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Manage User',
                style: TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        validator: _validateFullName,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: _navy, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: _validatePhone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '0112279869',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: _navy, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: _navy)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();

                          setDialogState(() => isSaving = true);
                          try {
                            await _saveProfile(name, phone);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              _showSnack('Profile updated successfully');
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() => isSaving = false);
                            _showSnack(
                              e.message ?? 'Failed to update profile',
                              isError: true,
                            );
                          } on FirebaseException catch (e) {
                            setDialogState(() => isSaving = false);
                            final message = e.code == 'permission-denied'
                                ? 'Permission denied. Deploy Firestore rules or sign in again.'
                                : (e.message ?? 'Failed to update profile');
                            _showSnack(message, isError: true);
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            _showSnack(
                              'Failed to update profile',
                              isError: true,
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _dialogFieldDecoration({
    required String label,
    String? errorText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      errorText: errorText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _navy, width: 2),
      ),
    );
  }

  void _openChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? currentError;
    String? newError;
    String? confirmError;
    var isSaving = false;
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Change Password',
                style: TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentController,
                      obscureText: obscureCurrent,
                      decoration: _dialogFieldDecoration(
                        label: 'Current Password',
                        errorText: currentError,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (currentError != null) {
                          setDialogState(() => currentError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newController,
                      obscureText: obscureNew,
                      decoration: _dialogFieldDecoration(
                        label: 'New Password',
                        errorText: newError,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      onChanged: (_) {
                        if (newError != null) {
                          setDialogState(() => newError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: _dialogFieldDecoration(
                        label: 'Confirm New Password',
                        errorText: confirmError,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (confirmError != null) {
                          setDialogState(() => confirmError = null);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: _navy)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final current = currentController.text;
                          final newPass = newController.text;
                          final confirm = confirmController.text;
                          var hasError = false;

                          if (current.isEmpty) {
                            setDialogState(
                              () => currentError = 'Current password is required',
                            );
                            hasError = true;
                          }
                          if (newPass.isEmpty) {
                            setDialogState(
                              () => newError = 'New password is required',
                            );
                            hasError = true;
                          } else if (newPass.length < 6) {
                            setDialogState(
                              () => newError =
                                  'Password must be at least 6 characters',
                            );
                            hasError = true;
                          }
                          if (confirm.isEmpty) {
                            setDialogState(
                              () =>
                                  confirmError = 'Please confirm your password',
                            );
                            hasError = true;
                          } else if (confirm != newPass) {
                            setDialogState(
                              () => confirmError = 'Passwords do not match',
                            );
                            hasError = true;
                          }

                          if (hasError) return;

                          final user = FirebaseAuth.instance.currentUser;
                          final email = user?.email;
                          if (user == null || email == null) {
                            _showSnack('Not logged in', isError: true);
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            final credential = EmailAuthProvider.credential(
                              email: email,
                              password: current,
                            );
                            await user.reauthenticateWithCredential(credential);
                            await user.updatePassword(newPass);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              _showSnack('Password updated successfully');
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() => isSaving = false);
                            final message = switch (e.code) {
                              'wrong-password' ||
                              'invalid-credential' =>
                                'Current password is incorrect',
                              'weak-password' =>
                                'New password is too weak',
                              _ => e.message ?? 'Failed to update password',
                            };
                            _showSnack(message, isError: true);
                          } catch (_) {
                            setDialogState(() => isSaving = false);
                            _showSnack(
                              'Failed to update password',
                              isError: true,
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static final Uri _customerSupportWhatsApp =
      Uri.parse('https://wa.me/601111349976');

  Future<void> _openCustomerSupportWhatsApp() async {
    try {
      final launched = await launchUrl(
        _customerSupportWhatsApp,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showSnack('Could not open WhatsApp', isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Could not open WhatsApp', isError: true);
      }
    }
  }

  void _openInfoDialog({required String title, required String content}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close', style: TextStyle(color: _navy)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: _navy),
        title: const Text(
          'Profile',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Settings'),
                      _menuItem(
                        icon: Icons.person_outline,
                        title: 'Manage User',
                        onTap: _openManageUserDialog,
                      ),
                      _menuItem(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: _openChangePasswordDialog,
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('Support'),
                      _menuItem(
                        icon: Icons.headset_mic_outlined,
                        title: 'Customer Support',
                        onTap: _openCustomerSupportWhatsApp,
                      ),
                      _menuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notification',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('Application'),
                      _menuItem(
                        icon: Icons.info_outline,
                        title: 'App Version',
                        trailing: '1.0.0',
                        showChevron: false,
                        onTap: () {},
                      ),
                      _menuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => _openInfoDialog(
                          title: 'Privacy Policy',
                          content:
                              'ThaiDriveSecure collects user information such as name, phone number, passport, and vehicle documents only for insurance and travel processing purposes. User information is securely stored and will not be shared with unauthorized parties.',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.red.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_isLoadingProfile) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: _navy)),
      );
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFFD9D9D9),
          child: Icon(Icons.person, size: 40, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              if (_phoneNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _phoneNumber,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? trailing,
    bool showChevron = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.black, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                if (showChevron) ...[
                  if (trailing != null) const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.black),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
