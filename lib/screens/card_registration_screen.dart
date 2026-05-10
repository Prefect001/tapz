import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import '../utils/shared_prefs.dart';
import '../utils/network_utils.dart';
import '../services/cloud_functions_service.dart';
import 'payfast_web_screen.dart';

class CardRegistrationScreen extends StatefulWidget {
  const CardRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<CardRegistrationScreen> createState() =>
      _CardRegistrationScreenState();
}

class _CardRegistrationScreenState extends State<CardRegistrationScreen> {
  static const int _maxPollRetries = 3;
  static const String _authAmount = '5.00';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;

  late final String _orderId;

  @override
  void initState() {
    super.initState();
    _orderId = 'CARD_${100000 + Random().nextInt(900000)}';
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _initiateCardRegistration() async {
    if (!await NetworkUtils.isConnected()) {
      _showSnack('No internet connection');
      return;
    }

    final storeId = SharedPrefs.storeId;
    final email = SharedPrefs.userEmail;
    final name = SharedPrefs.userName;
    final uid = _uid;

    if (storeId.isEmpty) {
      _showSnack('Store information missing');
      return;
    }
    if (email.isEmpty || name.isEmpty) {
      _showSnack('User details missing — please complete your profile');
      return;
    }
    if (uid == null || uid.isEmpty) {
      _showSnack('User not authenticated');
      return;
    }

    setState(() => _isLoading = true);

    final result = await CloudFunctionsService.initiatePayfastPayment(
      amount: _authAmount,
      orderId: _orderId,
      email: email,
      name: name,
      storeId: storeId,
      customerUid: uid,
      tokenize: true,
      cardRegistration: true,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true && result['paymentToken'] != null) {
      final paymentToken = result['paymentToken'] as String;
      final webResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PayfastWebScreen(
            paymentToken: paymentToken,
            isCardRegistration: true,
          ),
        ),
      );

      if (webResult == true) {
        _showSnack('Checking if card was saved…');
        _checkForSavedCardAfterRegistration();
      } else {
        _showSnack('Card registration cancelled');
        Navigator.pop(context, false);
      }
    } else {
      final error = result['error'] ?? 'Card registration failed';
      _showSnack('Card registration failed: $error');
    }
  }

  void _checkForSavedCardAfterRegistration() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      _showSnack('Cannot verify card — user not logged in');
      Navigator.pop(context, true);
      return;
    }

    // Initial 3-second delay before first poll — mirrors Java
    Future.delayed(const Duration(seconds: 3), () => _pollForToken(uid, 0));
  }

  Future<void> _pollForToken(String uid, int retryCount) async {
    try {
      final snap = await _db.collection('customers').doc(uid).get();

      if (snap.exists && snap.data()?.containsKey('paymentTokens') == true) {
        final raw = snap.get('paymentTokens');
        if (raw is List) {
          for (final t in raw) {
            if (t is Map && t['orderId']?.toString() == _orderId) {
              if (mounted) {
                _showSnack('✓ Card saved successfully!');
                Navigator.pop(context, true);
              }
              return;
            }
          }
        }
      }

      if (retryCount < _maxPollRetries) {
        Future.delayed(const Duration(seconds: 3),
            () => _pollForToken(uid, retryCount + 1));
      } else {
        if (mounted) {
          _showSnack(
              'Card registration completed. The card will appear in your saved cards shortly.');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
            'Card registration completed. Check your saved cards in a moment.');
        Navigator.pop(context, true);
      }
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('dd-MMM-yyyy hh.mm aa').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Card')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Center(
                  child: Text(
                    'Add New Card',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                const SizedBox(height: 24),

                // Store name
                _infoRow('Store:', SharedPrefs.storeName),
                const SizedBox(height: 8),

                // Info message
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'You will be redirected to PayFast to securely add your card details. '
                    'A small authorization charge of R 5.00 will be made and immediately voided.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),

                // Reference
                _infoRow('Reference:', _orderId),
                const SizedBox(height: 8),

                // Date
                _infoRow('Date:', now),
                const SizedBox(height: 32),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _initiateCardRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Add Card Details',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
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

  Widget _infoRow(String label, String value) => Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.black))),
        ],
      );
}