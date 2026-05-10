import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/shared_prefs.dart';
import 'login_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipcodeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _authService = AuthService();

  bool _editMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = SharedPrefs.userName;
    _mobileCtrl.text = SharedPrefs.mobileNumber;
    _cityCtrl.text = SharedPrefs.userCity;
    _zipcodeCtrl.text = SharedPrefs.userZipcode;
    _emailCtrl.text = SharedPrefs.userEmail;
  }

  Future<void> _updateProfile() async {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final zipcode = _zipcodeCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (name.isEmpty || city.isEmpty || zipcode.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill all details')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseId = SharedPrefs.userFirebaseId;
      final user = User(
        uid: firebaseId,
        name: name,
        mobileNumber: _mobileCtrl.text,
        city: city,
        zipcode: zipcode,
        email: email,
      );
      await _authService.createUserProfile(user, firebaseId);

      setState(() {
        _editMode = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Name'),
                _field(_nameCtrl, enabled: _editMode),
                const SizedBox(height: 16),
                _label('Mobile Number'),
                _field(_mobileCtrl, enabled: false),
                const SizedBox(height: 16),
                _label('Email'),
                _field(_emailCtrl,
                    enabled: _editMode,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _label('City'),
                _field(_cityCtrl, enabled: _editMode),
                const SizedBox(height: 16),
                _label('Pincode'),
                _field(_zipcodeCtrl,
                    enabled: _editMode,
                    type: TextInputType.number),
                const SizedBox(height: 32),

                if (!_editMode)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _editMode = true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25))),
                      child: const Text('Edit Profile',
                          style: TextStyle(fontSize: 16)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25))),
                      child: const Text('Update Profile',
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
                    child:
                        const Text('Logout', style: TextStyle(fontSize: 16)),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      );

  Widget _field(TextEditingController ctrl,
      {bool enabled = true, TextInputType type = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: type,
        decoration: InputDecoration(
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
}