import 'package:flutter/material.dart';
import '../utils/shared_prefs.dart';
import '../utils/constants.dart';
import 'main_screen.dart';
import 'profile_screen.dart';
import 'phone_login_screen.dart';
import 'scanning_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isProceedingToPayment = false;

  @override
  void initState() {
    super.initState();
    _checkAlreadyLoggedIn();
  }

  void _checkAlreadyLoggedIn() {
    if (SharedPrefs.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToMain());
    }
  }

  void _navigateToMain() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _onLoginPressed() {
    setState(() => _isProceedingToPayment = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneLoginScreen(
          onLoginSuccess: _handleLoginSuccess,
        ),
      ),
    );
  }

  void _onScanAndTipPressed() async {
    setState(() => _isProceedingToPayment = true);

    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanningScreen(isCartActive: false),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      final storeId = result['storeId'] ?? '';
      final storeName = result['storeName'] ?? '';

      await SharedPrefs.setStoreData(
        storeId: storeId,
        storeName: storeName,
        isCartActive: true,
      );

      if (!mounted) return;

      if (SharedPrefs.isLoggedIn) {
        _goToPayment();
      } else {
        _showLoginRequiredDialog();
      }
    }
  }

  /// Callback invoked by PhoneLoginScreen once both OTP + phone screens
  /// have been popped. At this point LoginScreen is back on top.
  void _handleLoginSuccess(bool profileDone) {
    if (!mounted) return;

    if (profileDone) {
      if (_isProceedingToPayment && SharedPrefs.isCartActive) {
        _goToPayment();
      } else {
        _navigateToMain();
      }
    } else {
      // New user — collect profile details
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  void _goToPayment() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _showLoginRequiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
            'You need to login or create an account to complete the payment. '
            'Would you like to login now?'),
        actions: [
          TextButton(
            onPressed: () {
              SharedPrefs.setBool(Constants.isCartActive, false);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProceedingToPayment = true);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhoneLoginScreen(
                    onLoginSuccess: _handleLoginSuccess,
                  ),
                ),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Welcome'), automaticallyImplyLeading: false),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_parking,
                        size: 80, color: Colors.blue),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Tapz',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tip service workers with ease',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onScanAndTipPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Scan & Tip',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onLoginPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Login / Register',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}