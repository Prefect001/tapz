import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:math';
import '../models/order.dart' as models;  // Add alias for your Order model
import '../models/product_item.dart';
import '../utils/app_database.dart';
import '../utils/shared_prefs.dart';
import '../utils/constants.dart';
import 'payment_screen.dart';
import 'scanning_screen.dart';
import 'main_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Fixed tipping values — mirrors CartActivity.java
  static const double _totalPrice = 22.00;
  static const int _totalQuantity = 1;

  final _db = FirebaseFirestore.instance;
  final _appDb = AppDatabase();

  bool _isLoading = false;
  bool _showSuccess = false;
  models.Order? _currentOrder;  // Use models.Order with alias

  String get _storeName => SharedPrefs.storeName;
  String get _storeId => SharedPrefs.storeId;
  String get _userFirebaseId =>
      FirebaseAuth.instance.currentUser?.uid ?? SharedPrefs.userFirebaseId;
  String get _userName => SharedPrefs.userName;

  // ── mirrors initiatePayment() ──────────────────────────────────────────────

  Future<void> _initiatePayment() async {
    setState(() => _isLoading = true);

    final orderId = '${100000 + Random().nextInt(900000)}';

    // Create order in Firestore BEFORE payment — mirrors Java
    final orderRef =
        _db.collection(Constants.baseOrderUrl).doc(orderId);

    final List<Map<String, Object>> itemsList = [
      {
        'productId': 'TIP001',
        'productName': 'Parking Tip',
        'productPrice': 22.00,
        'productQuantity': 1,
      }
    ];

    final orderData = {
      'orderId': orderId,
      'amount': _totalPrice,
      'status': 'pending',
      'created': FieldValue.serverTimestamp(),
      'items': itemsList,
      'customerId': _userFirebaseId,
      'storeId': _storeId,
      'storeName': _storeName,
      'customerName': _userName,
      'totalQuantity': _totalQuantity,
    };

    try {
      await orderRef.set(orderData);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Failed to create order: $e');
      return;
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    // Navigate to PaymentScreen
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalPrice: _totalPrice,
          totalQuantity: _totalQuantity,
          orderId: orderId,
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      final returnedOrderId = result['orderId'] as String? ?? orderId;
      final txnNumber = result['transactionNumber'] as String? ?? '';
      _processSuccessfulPayment(returnedOrderId, txnNumber);
    }
  }

  // ── mirrors processSuccessfulPayment() ────────────────────────────────────

  Future<void> _processSuccessfulPayment(
      String orderId, String transactionNumber) async {
    setState(() => _isLoading = true);

    final orderRef =
        _db.collection(Constants.baseOrderUrl).doc(orderId);

    try {
      await orderRef.update({
        'status': 'paid',
        'transactionNumber': transactionNumber,
        'paidAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Failed to update order: $e');
      return;
    }

    // Build local Order object using models.Order
    final tipItem = ProductItem(
      productId: 'TIP001',
      productName: 'Parking Tip',
      productPrice: 22.00,
      productQuantity: 1,
    );

    final order = models.Order(  // Use models.Order with alias
      orderId: orderId,
      storeId: _storeId,
      storeName: _storeName,
      userId: _userFirebaseId,
      totalQuantity: _totalQuantity,
      totalPrice: _totalPrice,
      items: [tipItem],
      transactionNumber: transactionNumber,
      userName: _userName,
      date: DateTime.now(),
      paymentMethod: 'card',
    );

    // Save locally — mirrors Java database.appDao().insertOrder(order)
    await _appDb.insertOrder(order);

    setState(() {
      _currentOrder = order;
      _isLoading = false;
      _showSuccess = true;
    });

    // Clear cart state
    await SharedPrefs.clearCart();

    // Auto-navigate home after 5 seconds — mirrors setupPostPaymentNavigation()
    _startAutoReturnCountdown();
  }

  int _countdown = 5;
  Timer? _countdownTimer;

  void _startAutoReturnCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    _countdownTimer?.cancel();
    SharedPrefs.setBool(Constants.isCartActive, false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // mirrors deleteEmptyCart / navigateToHome() in CartActivity.java
  void _cancelTransaction() {
    SharedPrefs.setBool(Constants.isCartActive, false);
    SharedPrefs.setStoreData(
      storeId: '',
      storeName: '',
      storeImageUrl: '',
      isCartActive: false,
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  void _confirmCancel() {
    if (_storeName.isEmpty) {
      _cancelTransaction();
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Transaction'),
        content: const Text(
            'Are you sure you want to cancel this tipping transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _cancelTransaction();
            },
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showSuccess && _currentOrder != null) {
      return _buildSuccessLayout();
    }
    // WillPopScope mirrors onSupportNavigateUp() -> navigateToHome() in Java
    return WillPopScope(
      onWillPop: () async {
        _confirmCancel();
        return false;
      },
      child: _buildTipLayout(),
    );
  }

  // Mirrors the full CartActivity layout including Cancel Transaction button
  Widget _buildTipLayout() {
    return Stack(
      children: [
        Column(
          children: [
            // ── Centre content ─────────────────────────────────────────
            Expanded(
              child: Center(
                child: _storeName.isEmpty
                    // No store yet — show scan prompt
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              "Scan the QR code to start tipping",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              final result =
                                  await Navigator.push<Map<String, String>>(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ScanningScreen(
                                        isCartActive: false)),
                              );
                              if (result != null) setState(() {});
                            },
                            child: const Text("Scan QR Code"),
                          ),
                        ],
                      )
                    // Store selected — show store info + Cancel Transaction
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_parking,
                              size: 80, color: Colors.blue),
                          const SizedBox(height: 16),
                          Text(
                            _storeName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Parking Tip',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 32),
                          // Cancel Transaction — mirrors deleteEmptyCart in Java:
                          //   editor.putBoolean(IS_CART_ACTIVE, false);
                          //   editor.apply();
                          //   finish();
                          TextButton(
                            onPressed: _confirmCancel,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue[800],
                            ),
                            child: const Text(
                              'Cancel Transaction',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // ── Bottom summary bar ─────────────────────────────────────
            // Mirrors activity_cart.xml cart_summary_view
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Amount',
                            style: TextStyle(
                                color: Colors.white, fontSize: 14)),
                        Text(
                          'R ${_totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total: $_totalQuantity',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // Tip Now — only when store is selected
                  if (_storeName.isNotEmpty)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14)),
                      onPressed: _isLoading ? null : _initiatePayment,
                      child: const Text(
                        'Tip Now',
                        style: TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_isLoading)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  // Mirrors layout_qr_display.xml success screen
  Widget _buildSuccessLayout() {
    final order = _currentOrder!;  // This is now models.Order
    return SingleChildScrollView(
      child: Column(
        children: [
          // Green top banner
          Container(
            width: double.infinity,
            color: const Color(0xFF64DD17),
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'R ${order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 50),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tipped Successfully',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // White card overlapping the green banner
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.storeName,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Order Id: ${order.orderId}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        'Your tip of amount R${order.totalPrice.toStringAsFixed(2)} '
                        'with ${order.storeName} has been successfully processed. '
                        'In case of any queries, please contact ${order.storeName} '
                        'with reference number given below.',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reference Number: ${order.transactionNumber ?? ''}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // QR Code
                      Center(
                        child: QrImageView(
                          data: order.orderId,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Back to Home button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue),
                          onPressed: _navigateToHome,
                          child: const Text('Back to Home',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Returning to home in $_countdown seconds...',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}