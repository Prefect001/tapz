import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/complaint.dart';
import '../utils/constants.dart';
import '../utils/shared_prefs.dart';

class CustomerCareScreen extends StatefulWidget {
  const CustomerCareScreen({Key? key}) : super(key: key);

  @override
  State<CustomerCareScreen> createState() => _CustomerCareScreenState();
}

class _CustomerCareScreenState extends State<CustomerCareScreen> {
  final _descCtrl = TextEditingController();
  final _db = FirebaseFirestore.instance;
  bool _isLoading = false;

  // Mirrors complaints_list in Java
  final List<String> _categories = [
    'General',
    'Payment Issues',
    'Technical Problems',
    'Product Quality',
    'Delivery Issues',
    'Other',
  ];
  String _selectedCategory = 'General';

  Future<void> _uploadData() async {
    final description = _descCtrl.text.trim();
    if (_selectedCategory.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    final ticketNumber =
        '${100000 + Random().nextInt(900000)}';
    final userId = SharedPrefs.userFirebaseId;

    final complaint = Complaint(
      category: _selectedCategory,
      description: description,
      userId: userId,
      ticketNumber: ticketNumber,
    );

    try {
      await _db
          .collection(Constants.complaintsBaseUrl)
          .add(complaint.toMap());

      setState(() => _isLoading = false);
      _showInfoDialog(ticketNumber);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error uploading data')));
    }
  }

  void _showInfoDialog(String ticketNumber) {
    _descCtrl.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Your complaint has been submitted. Our team will reach out to you within 24 hours.'),
            const SizedBox(height: 12),
            Text('Ticket Number: $ticketNumber',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // screen
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
      appBar: AppBar(title: const Text('Customer Care')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Category',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCategory = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Description',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  maxLines: 10,
                  maxLength: 360,
                  decoration: InputDecoration(
                    hintText:
                        'Describe your issue here (Max 360 characters)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _uploadData,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25))),
                    child: const Text('Submit',
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
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }
}