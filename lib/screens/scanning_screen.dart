import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/store.dart';
import '../utils/constants.dart';
import '../utils/shared_prefs.dart';

class ScanningScreen extends StatefulWidget {
  final bool isCartActive;

  const ScanningScreen({Key? key, required this.isCartActive})
      : super(key: key);

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isLoading = false;
  bool _hasScanned = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    _hasScanned = true;
    _processStoreScan(rawValue);
  }

  Future<void> _processStoreScan(String rawData) async {
    setState(() => _isLoading = true);

    String storeId = rawData;

    // Handle JSON format: {"storeId": "..."}
    if (rawData.trim().startsWith('{')) {
      try {
        final json = jsonDecode(rawData);
        if (json['storeId'] != null) {
          storeId = json['storeId'];
        } else {
          _showInfoDialog();
          return;
        }
      } catch (_) {
        _showInfoDialog();
        return;
      }
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection(Constants.storesBaseUrl)
          .doc(storeId)
          .get();

      setState(() => _isLoading = false);

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['storeId'] = doc.id;
        final store = Store.fromMap(data);
        _showScanResultDialog(store);
      } else {
        _showInfoDialog();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showInfoDialog();
    }
  }

  void _showScanResultDialog(Store store) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Text(
          store.storeName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _hasScanned = false;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveDetails(store);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _saveDetails(Store store) async {
    await SharedPrefs.setStoreData(
      storeId: store.storeId,
      storeName: store.storeName,
      storeImageUrl: store.imageUrl,
      isCartActive: true,
      payfastMerchantId: store.payfastMerchantId,
    );

    if (!mounted) return;
    // Return store details to calling screen
    Navigator.pop(context, {
      'storeId': store.storeId,
      'storeName': store.storeName,
    });
  }

  void _showInfoDialog() {
    setState(() {
      _isLoading = false;
      _hasScanned = true;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text(
          'This QR code is not recognised. Please scan a valid store QR code.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _hasScanned = false);
              Navigator.pop(context);
            },
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),
          // Scan rectangle overlay
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}