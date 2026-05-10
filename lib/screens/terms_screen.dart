import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms and Conditions')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Terms and Conditions',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to Tapz. By using this application, you agree to the following terms and conditions.\n\n'
              '1. USE OF SERVICE\n'
              'Tapz is a mobile application that facilitates tipping of parking attendants. '
              'You must be 18 years or older to use this service.\n\n'
              '2. PAYMENTS\n'
              'All payments are processed securely through PayFast. Tapz does not store '
              'your card details. A fixed tip amount of R22.00 applies per transaction.\n\n'
              '3. REFUNDS\n'
              'Tips made through Tapz are non-refundable as they are paid directly to the '
              'parking attendant.\n\n'
              '4. USER ACCOUNTS\n'
              'You are responsible for maintaining the confidentiality of your account '
              'credentials and for all activities that occur under your account.\n\n'
              '5. PRIVACY\n'
              'We collect and process your personal data in accordance with our Privacy '
              'Policy. Your data is used solely for the purpose of facilitating payments.\n\n'
              '6. LIMITATIONS\n'
              'Tapz shall not be liable for any indirect, incidental, or consequential '
              'damages arising from the use of this application.\n\n'
              '7. CHANGES TO TERMS\n'
              'Tapz reserves the right to modify these terms at any time. Continued use '
              'of the app constitutes acceptance of updated terms.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}