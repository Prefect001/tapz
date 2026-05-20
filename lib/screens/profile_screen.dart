import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/shared_prefs.dart';
import '../utils/constants.dart';
import 'main_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool returnToPayment;

  const ProfileScreen({Key? key, this.returnToPayment = false})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipcodeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mobileCtrl.text = SharedPrefs.mobileNumber;
    _nameCtrl.text = SharedPrefs.userName;
    _cityCtrl.text = SharedPrefs.userCity;
    _zipcodeCtrl.text = SharedPrefs.userZipcode;
    _emailCtrl.text = SharedPrefs.userEmail;

    if (widget.returnToPayment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Please complete your profile to continue with payment')));
      });
    }
  }

  Future<void> _createProfile() async {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final zipcode = _zipcodeCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();

    if (name.isEmpty || city.isEmpty || zipcode.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill all details')));
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid email address')));
      return;
    }

    setState(() => _isLoading = true);
    final firebaseId = SharedPrefs.userFirebaseId;

    if (firebaseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User not authenticated. Please login again.')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final user = User(
          uid: firebaseId,
          name: name,
          mobileNumber: mobile,
          city: city,
          zipcode: zipcode,
          email: email);
      await _authService.createUserProfile(user, firebaseId);
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (widget.returnToPayment) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainScreen()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating profile: $e')));
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.returnToPayment) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Please complete your profile to continue with payment')));
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Name'),
                  _field(_nameCtrl, hintText: 'Enter your name'),
                  const SizedBox(height: 16),
                  _label('Mobile Number'),
                  _field(_mobileCtrl, enabled: false),
                  const SizedBox(height: 16),
                  _label('Email'),
                  _field(_emailCtrl,
                      hintText: 'Enter email',
                      type: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _label('City'),
                  _field(_cityCtrl, hintText: 'Enter city'),
                  const SizedBox(height: 16),
                  _label('Zipcode'),
                  _field(_zipcodeCtrl,
                      hintText: 'Enter zipcode',
                      type: TextInputType.number),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createProfile,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25))),
                      child: const Text('Create Profile',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25))),
                      child: const Text('Logout',
                          style: TextStyle(fontSize: 16)),
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
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      );

  Widget _field(
    TextEditingController ctrl, {
    String hintText = '',
    bool enabled = true,
    TextInputType type = TextInputType.text,
  }) =>
      TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _cityCtrl.dispose();
    _zipcodeCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }
}