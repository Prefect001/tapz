import 'package:flutter/material.dart';
import 'profile_edit_screen.dart';
import 'purchase_history_screen.dart';
import 'customer_care_screen.dart';
import 'terms_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _optionButton(context, 'Profile', () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()))),
          const SizedBox(height: 8),
          _optionButton(context, 'Tipping History', () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen()))),
          const SizedBox(height: 8),
          _optionButton(context, 'Customer Care', () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerCareScreen()))),
          const SizedBox(height: 8),
          _optionButton(context, 'Terms and Conditions', () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsScreen()))),
          const SizedBox(height: 24),
          // App version card — mirrors fragment_account.xml
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('App Version',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('1.0.0',
                      style: TextStyle(
                          fontSize: 16, color: Colors.blue[700])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionButton(
      BuildContext context, String label, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}