import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/scanning_screen.dart';

import '../models/store.dart';
import '../utils/constants.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({Key? key}) : super(key: key);

  @override
  _StoresScreenState createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  List<Store> _stores = [];
  bool _isLoading = true;
  String _userZipcode = '263139';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    final prefs = await SharedPreferences.getInstance();
    final zipcode = prefs.getString(Constants.userZipcode) ?? '263139';
    
    setState(() => _userZipcode = zipcode);

    try {
      final querySnapshot = await _firestore
          .collection(Constants.storesBaseUrl) // Changed from STORES_BASE_URL
          .where(Constants.keyStoreZipcode, isEqualTo: zipcode) // Changed from KEY_STORE_ZIPCODE
          .get();

      final stores = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['storeId'] = doc.id;
        return Store.fromMap(data);
      }).toList();

      setState(() {
        _stores = stores;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stores: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scanStore() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanningScreen(isCartActive: false),
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store scanned successfully')),
      );
      _loadStores();
    }
  }

  void _viewStoreDetails(Store store) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.storeName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (store.imageUrl != null && store.imageUrl!.isNotEmpty)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(store.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text('Store ID: ${store.storeId}'),
              if (store.zipcode != null) Text('Zipcode: ${store.zipcode}'),
              Text('Location: ${store.latitude.toStringAsFixed(4)}, ${store.longitude.toStringAsFixed(4)}'),
              if (store.payfastMerchantId != null) 
                Text('PayFast Merchant: ${store.payfastMerchantId}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _selectStore(store);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Select Store'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectStore(Store store) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(Constants.storeId, store.storeId); // Changed from STORE_ID
    await prefs.setString(Constants.storeName, store.storeName); // Changed from STORE_NAME
    await prefs.setString(Constants.storeImageUrl, store.imageUrl ?? ''); // Changed from STORE_IMAGE_URL
    await prefs.setBool(Constants.isCartActive, true);
    
    if (store.payfastMerchantId != null && store.payfastMerchantId!.isNotEmpty) {
      await prefs.setString(Constants.payfastMerchantId, store.payfastMerchantId!); // Changed from PAYFAST_MERCHANT_ID
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${store.storeName} selected'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStores,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No stores found in your area',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Zipcode: $_userZipcode',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _scanStore,
                        child: const Text('Scan Store QR'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Change Zipcode'),
                              content: TextFormField(
                                initialValue: _userZipcode,
                                decoration: const InputDecoration(
                                  labelText: 'Enter new zipcode',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  _userZipcode = value;
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await prefs.setString(Constants.userZipcode, _userZipcode);
                                    Navigator.pop(context);
                                    _loadStores();
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Change Zipcode'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Stores in: $_userZipcode',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Change Zipcode'),
                                      content: TextFormField(
                                        initialValue: _userZipcode,
                                        decoration: const InputDecoration(
                                          labelText: 'Enter new zipcode',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          _userZipcode = value;
                                        },
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await prefs.setString(Constants.userZipcode, _userZipcode);
                                            Navigator.pop(context);
                                            _loadStores();
                                          },
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _stores.length,
                        itemBuilder: (context, index) {
                          final store = _stores[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: store.imageUrl != null && store.imageUrl!.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(store.imageUrl!),
                                      radius: 24,
                                    )
                                  : const CircleAvatar(
                                      radius: 24,
                                      child: Icon(Icons.store),
                                    ),
                              title: Text(
                                store.storeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (store.zipcode != null)
                                    Text('Zipcode: ${store.zipcode}'),
                                  Text(
                                    'ID: ${store.storeId}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () => _viewStoreDetails(store),
                                    tooltip: 'Store Details',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    onPressed: _scanStore,
                                    tooltip: 'Scan QR',
                                  ),
                                ],
                              ),
                              onTap: () => _viewStoreDetails(store),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanStore,
        tooltip: 'Scan Store QR',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}