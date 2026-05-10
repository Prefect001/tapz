import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'card_registration_screen.dart';

class SavedCardsScreen extends StatefulWidget {
  const SavedCardsScreen({Key? key}) : super(key: key);

  @override
  State<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _savedTokens = [];
  bool _isLoading = false;

  // Mirrors the cardSelected flag in Java
  bool _cardSelected = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _loadSavedCards() async {
    final uid = _uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view saved cards')));
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final snap = await _db.collection('customers').doc(uid).get();
      final List<Map<String, dynamic>> tokens = [];

      if (snap.exists && snap.data()?.containsKey('paymentTokens') == true) {
        final raw = snap.get('paymentTokens');
        if (raw is List) {
          for (final t in raw) {
            if (t is Map) {
              tokens.add(Map<String, dynamic>.from(t));
            }
          }
        }
      }

      setState(() {
        _savedTokens = tokens;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load saved cards')));
      }
    }
  }

  void _onCardSelected(Map<String, dynamic> card) {
    final token = card['token'] as String?;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid card token')));
      return;
    }
    // Set flag before pop — mirrors Java FIX 1
    _cardSelected = true;
    Navigator.pop(context, {
      'selectedToken': token,
      'cardMask': card['cardMask'] ?? '',
    });
  }

  void _onCardDeleteTapped(Map<String, dynamic> card) {
    final cardMask = card['cardMask'] as String?;
    final label = cardMask != null
        ? 'card ending in •••• $cardMask'
        : 'this card';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Remove $label? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteCard(card);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(Map<String, dynamic> card) async {
    final token = card['token'] as String?;
    final uid = _uid;
    if (uid == null || token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cannot delete card')));
      return;
    }

    // Optimistic local update — mirrors Java version
    setState(() {
      _savedTokens.removeWhere((t) => t['token'] == token);
    });

    try {
      final snap = await _db.collection('customers').doc(uid).get();
      if (!snap.exists) return;

      final raw = snap.get('paymentTokens');
      if (raw is! List) return;

      final updated = raw
          .cast<Map<String, dynamic>>()
          .where((t) => t['token'] != token)
          .toList();

      await _db
          .collection('customers')
          .doc(uid)
          .update({'paymentTokens': updated});

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Card deleted')));
      }
    } catch (e) {
      // Restore from Firestore on failure — mirrors Java
      _loadSavedCards();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete card')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Only set RESULT_CANCELED when user is genuinely dismissing
        // without selecting a card — mirrors Java FIX 1
        if (!_cardSelected) {
          Navigator.pop(context, null);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Saved Payment Methods')),
        body: Column(
          children: [
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Refreshing…')));
                        _loadSavedCards();
                      },
                      child: const Text('Refresh'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple),
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const CardRegistrationScreen()),
                        );
                        if (result == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Card added successfully')));
                          _loadSavedCards();
                        }
                      },
                      child: const Text('Add New Card',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (_savedTokens.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    "You have no saved cards yet.\nTap 'Add New Card' to save one.",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _savedTokens.length,
                  itemBuilder: (_, i) {
                    final card = _savedTokens[i];
                    final cardMask =
                        card['cardMask'] as String? ?? '';
                    final cardType =
                        card['cardType'] as String? ?? 'Credit / Debit Card';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _onCardSelected(card),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cardMask.isNotEmpty
                                          ? 'Card ending in •••• $cardMask'
                                          : 'Saved Card',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(cardType,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () =>
                                    _onCardDeleteTapped(card),
                                child: const Text('Delete',
                                    style:
                                        TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}