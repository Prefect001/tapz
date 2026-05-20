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
  String _selectedCountryCode = '+27';

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
        if (!mounted) return;
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
      onVerificationCompleted: (_) {
        // Auto-verification (Android only) — just stop the loader.
        // The OTP screen handles the actual sign-in.
        if (mounted) setState(() => _isLoading = false);
      },
      onVerificationFailed: (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnack('Verification failed: ${e.message}');
      },
      onCodeAutoRetrievalTimeout: (_) {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  /// Called by OTPVerificationScreen after Firebase signs the user in.
  ///
  /// Navigation stack at this point:
  ///   LoginScreen → PhoneLoginScreen → OTPVerificationScreen  (top)
  ///
  /// We pop back to the first route (LoginScreen) in one shot, then
  /// call the LoginScreen callback after a short delay so it has a
  /// live context.
  Future<void> _handleVerified(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Save auth state
    await SharedPrefs.setUserData(
      firebaseId: uid,
      mobileNumber: user.phoneNumber ?? '',
      isLoggedIn: true,
    );

    // 2. Check Firestore for existing profile
    final exists = await _authService.checkIfUserExists(uid);
    final profileDone = exists && SharedPrefs.isProfileDone;

    // Capture callback before any pops — widget tree may change
    final onSuccess = widget.onLoginSuccess;

    if (!mounted) return;

    // 3. Pop all screens back to LoginScreen (the first route) in one call
    Navigator.of(context).popUntil((route) => route.isFirst);

    // 4. Wait one frame for the pop to settle, then invoke the callback
    await Future.delayed(const Duration(milliseconds: 100));
    onSuccess(profileDone);
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              right: BorderSide(
                                  color: Colors.grey.shade300)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            items: _countryCodes
                                .map((c) => DropdownMenuItem(
                                      value: c['code'],
                                      child: Text(
                                          '${c['flag']} ${c['code']}'),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(
                                () => _selectedCountryCode = v!),
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
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Text('Continue',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
                color: Colors.black45,
                child:
                    const Center(child: CircularProgressIndicator())),
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