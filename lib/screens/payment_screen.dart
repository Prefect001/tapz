import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../utils/shared_prefs.dart';
import '../utils/constants.dart';
import '../utils/network_utils.dart';
import '../services/cloud_functions_service.dart';
import 'payfast_web_screen.dart';
import 'saved_cards_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double totalPrice;
  final int totalQuantity;
  final String? orderId;

  const PaymentScreen({
    Key? key,
    this.totalPrice = Constants.tipAmount,
    this.totalQuantity = 1,
    this.orderId,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final String _orderId;
  bool _isLoading = false;
  bool _saveCard = false;
  bool _doubleTheTip = false;
  bool _tripleTheTip = false;
  bool _tokenizationRequested = false;
  int _initialCardCount = 0;
  bool _isCheckingCards = false;

  // Saved-cards UI state
  bool _hasSavedCards = false;
  int _cardCount = 0;
  String _savedCardsHeader = 'Checking for saved cards...';

  @override
  void initState() {
    super.initState();
    _orderId = widget.orderId ??
        '${100000 + Random().nextInt(900000)}';

    Future.delayed(
        const Duration(seconds: 1), _checkForSavedCards);
    _trackInitialCardCount();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String get _effectiveTipAmountString {
    if (_tripleTheTip) return Constants.tripleTipAmountString;
    if (_doubleTheTip) return Constants.doubleTipAmountString;
    return Constants.tipAmountString;
  }

  // ── mirrors checkForSavedCards() ──────────────────────────────────────────

  Future<void> _checkForSavedCards() async {
    if (_isCheckingCards) return;
    _isCheckingCards = true;

    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      setState(() {
        _hasSavedCards = false;
        _savedCardsHeader = '';
      });
      _isCheckingCards = false;
      return;
    }

    try {
      final snap =
          await _db.collection('customers').doc(uid).get();
      int count = 0;
      bool has = false;

      if (snap.exists &&
          snap.data()?.containsKey('paymentTokens') == true) {
        final raw = snap.get('paymentTokens');
        if (raw is List) {
          count = raw.length;
          has = count > 0;
        }
      }

      if (mounted) {
        setState(() {
          _hasSavedCards = has;
          _cardCount = count;
          _savedCardsHeader =
              has ? 'Pay with a Saved Card' : 'No Saved Cards';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _savedCardsHeader = 'Saved Cards (unavailable)');
      }
    } finally {
      _isCheckingCards = false;
    }
  }

  Future<void> _trackInitialCardCount() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    try {
      final snap =
          await _db.collection('customers').doc(uid).get();
      if (snap.exists &&
          snap.data()?.containsKey('paymentTokens') == true) {
        final raw = snap.get('paymentTokens');
        _initialCardCount = raw is List ? raw.length : 0;
      }
    } catch (_) {}
  }

  // ── mirrors initiatePayfastPayment() ──────────────────────────────────────

  Future<void> _initiatePayfastPayment() async {
    if (!await NetworkUtils.isConnected()) {
      _showSnack('No internet connection');
      return;
    }

    _tokenizationRequested = _saveCard;

    final storeId = SharedPrefs.storeId;
    final email = SharedPrefs.userEmail;
    final name = SharedPrefs.userName;
    final uid = _uid;

    if (storeId.isEmpty) { _showSnack('Store information missing'); return; }
    if (email.isEmpty || name.isEmpty) { _showSnack('User details missing'); return; }
    if (uid == null || uid.isEmpty) { _showSnack('User not authenticated'); return; }

    setState(() => _isLoading = true);

    final result = await CloudFunctionsService.initiatePayfastPayment(
      amount: _effectiveTipAmountString,
      orderId: _orderId,
      email: email,
      name: name,
      storeId: storeId,
      customerUid: uid,
      tokenize: _saveCard,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success'] == true && result['paymentToken'] != null) {
      final webResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PayfastWebScreen(
            paymentToken: result['paymentToken'] as String,
          ),
        ),
      );
      _onPayfastResult(webResult);
    } else {
      _showSnack(result['error'] ?? 'Payment initialization failed');
    }
  }

  // ── mirrors initiatePaymentWithSavedToken() ────────────────────────────────

  Future<void> _initiatePaymentWithSavedToken(String token) async {
    if (!await NetworkUtils.isConnected()) {
      _showSnack('No internet connection');
      return;
    }

    final storeId = SharedPrefs.storeId;
    final email = SharedPrefs.userEmail;
    final name = SharedPrefs.userName;
    final uid = _uid;

    if (storeId.isEmpty) { _showSnack('Store information missing'); return; }
    if (email.isEmpty || name.isEmpty) { _showSnack('User details missing'); return; }
    if (uid == null || uid.isEmpty) { _showSnack('User not authenticated'); return; }

    setState(() => _isLoading = true);

    final result = await CloudFunctionsService.processSavedCardPayment(
      amount: _effectiveTipAmountString,
      orderId: _orderId,
      email: email,
      name: name,
      storeId: storeId,
      customerUid: uid,
      token: token,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success'] == true && result['paymentToken'] != null) {
      // Open WebView like new-card payments
      final webResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PayfastWebScreen(
            paymentToken: result['paymentToken'] as String,
          ),
        ),
      );
      _onPayfastResult(webResult);
    } else if (result['success'] == true) {
      _returnPaymentSuccess(
          'TXN${DateTime.now().millisecondsSinceEpoch}');
    } else {
      _showSnack(result['error'] ?? 'Payment failed');
    }
  }

  // ── PayFast WebView result handler ────────────────────────────────────────

  void _onPayfastResult(bool? webResult) {
    if (webResult == true) {
      if (_tokenizationRequested) {
        _checkIfCardWasSavedAfterPayment();
      }
      _isCheckingCards = false;
      _checkForSavedCards();
      _trackInitialCardCount();

      _returnPaymentSuccess(
          'TXN${DateTime.now().millisecondsSinceEpoch}');
    } else {
      _showSnack('Payment cancelled');
      Navigator.pop(context, null);
    }
  }

  void _returnPaymentSuccess(String txnNumber) {
    Navigator.pop(context, {
      'success': true,
      'orderId': _orderId,
      'transactionNumber': txnNumber,
    });
  }

  // ── mirrors checkIfCardWasSavedAfterPayment() ─────────────────────────────

  Future<void> _checkIfCardWasSavedAfterPayment() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;

    await Future.delayed(const Duration(seconds: 5));
    try {
      final snap =
          await _db.collection('customers').doc(uid).get();
      if (snap.exists &&
          snap.data()?.containsKey('paymentTokens') == true) {
        final raw = snap.get('paymentTokens');
        final count = raw is List ? raw.length : 0;
        if (count > _initialCardCount && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('✓ Card saved for future payments')));
          _checkForSavedCards();
        } else {
          _checkAgainAfterDelay(uid);
        }
      }
    } catch (_) {}
  }

  Future<void> _checkAgainAfterDelay(String uid) async {
    await Future.delayed(const Duration(seconds: 5));
    try {
      final snap =
          await _db.collection('customers').doc(uid).get();
      if (snap.exists &&
          snap.data()?.containsKey('paymentTokens') == true) {
        final raw = snap.get('paymentTokens');
        final count = raw is List ? raw.length : 0;
        if (count > _initialCardCount && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('✓ Card saved for future payments')));
          _checkForSavedCards();
        }
      }
    } catch (_) {}
  }

  // ── mirrors onResume() re-checking ────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isCheckingCards = false;
    Future.delayed(
        const Duration(milliseconds: 500), _checkForSavedCards);
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
    final storeName = SharedPrefs.storeName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            SharedPrefs.setBool(Constants.isCartActive, false);
            Navigator.pop(context, null);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16, 16, 16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Order Summary Card ───────────────────────────────────
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _summaryRow('Merchant:', storeName),
                        const SizedBox(height: 8),
                        _summaryRow('Transaction ID:', _orderId),
                        const SizedBox(height: 8),
                        _summaryRow(
                            'Quantity:', '${widget.totalQuantity}'),
                        const SizedBox(height: 8),
                        _summaryRow(
                            'Amount:', 'R $_effectiveTipAmountString'),
                        const SizedBox(height: 8),
                        _summaryRow('Date:', now),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Double the Tip ───────────────────────────────────────
                Card(
                  elevation: 2,
                  child: CheckboxListTile(
                    title: const Text(
                      'Double the tip (R44)',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Show extra appreciation — increase your tip from R22 to R44',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _doubleTheTip,
                    onChanged: (v) => setState(() {
                      _doubleTheTip = v ?? false;
                      if (_doubleTheTip) _tripleTheTip = false;
                    }),
                    activeColor: Colors.purple,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Triple the Tip ───────────────────────────────────────
                Card(
                  elevation: 2,
                  child: CheckboxListTile(
                    title: const Text(
                      'Triple the tip (R66)',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Go above and beyond — increase your tip from R22 to R66',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _tripleTheTip,
                    onChanged: (v) => setState(() {
                      _tripleTheTip = v ?? false;
                      if (_tripleTheTip) _doubleTheTip = false;
                    }),
                    activeColor: Colors.purple,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                ),
                Text(_savedCardsHeader,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_hasSavedCards)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple),
                      onPressed: () async {
                        final res = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SavedCardsScreen()),
                        );
                        if (res != null &&
                            res['selectedToken'] != null) {
                          _initiatePaymentWithSavedToken(
                              res['selectedToken'] as String);
                        }
                      },
                      child: Text(
                        _cardCount > 0
                            ? 'Pay with Saved Card ($_cardCount)'
                            : 'Pay with Saved Card',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // ── New Card Section ─────────────────────────────────────
                const Text('Pay with a New Card',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text(
                      'Save this card for future payments'),
                  value: _saveCard,
                  onChanged: (v) =>
                      setState(() => _saveCard = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16)),
                    onPressed:
                        _isLoading ? null : _initiatePayfastPayment,
                    child: const Text('Proceed to Pay',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      SharedPrefs.setBool(
                          Constants.isCartActive, false);
                      Navigator.pop(context, null);
                    },
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.black)),
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

  Widget _summaryRow(String label, String value) => Row(
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