import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/shared_prefs.dart';
import '../utils/constants.dart';
import 'otp_verification_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  final Function(bool profileDone) onLoginSuccess;

  const PhoneLoginScreen({Key? key, required this.onLoginSuccess})
      : super(key: key);

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String _selectedCountryCode = '+27'; // South Africa default

  final List<Map<String, String>> _countryCodes = [
    {'code': '+27', 'name': 'South Africa', 'flag': '🇿🇦'},
    {'code': '+91', 'name': 'India', 'flag': '🇮🇳'},
    {'code': '+1', 'name': 'USA', 'flag': '🇺🇸'},
    {'code': '+44', 'name': 'UK', 'flag': '🇬🇧'},
    {'code': '+61', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': '+65', 'name': 'Singapore', 'flag': '🇸🇬'},
  ];

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Please enter your phone number');
      return;
    }

    setState(() => _isLoading = true);
    final fullNumber = '$_selectedCountryCode$phone';

    await _authService.verifyPhoneNumber(
      phoneNumber: fullNumber,
      onCodeSent: (verificationId) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              phoneNumber: fullNumber,
              verificationId: verificationId,
              onVerified: _handleVerified,
            ),
          ),
        );
      },
      onVerificationCompleted: (_) => setState(() => _isLoading = false),
      onVerificationFailed: (e) {
        setState(() => _isLoading = false);
        _showSnack('Verification failed: ${e.message}');
      },
      onCodeAutoRetrievalTimeout: (_) => setState(() => _isLoading = false),
    );
  }

  Future<void> _handleVerified(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await SharedPrefs.setUserData(
      firebaseId: uid,
      mobileNumber: user.phoneNumber ?? '',
      isLoggedIn: true,
    );

    final exists = await _authService.checkIfUserExists(uid);
    if (!mounted) return;

    widget.onLoginSuccess(exists && SharedPrefs.isProfileDone);
    Navigator.pop(context);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login with Phone')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Enter your phone number',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'We will send you a verification code',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              right: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            items: _countryCodes
                                .map((c) => DropdownMenuItem(
                                      value: c['code'],
                                      child: Text('${c['flag']} ${c['code']}'),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCountryCode = v!),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
                            hintText: 'Phone number',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Continue', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}