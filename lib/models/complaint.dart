import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  Timestamp? timestamp;
  final String category;
  final String description;
  final String userId;
  final String ticketNumber;

  Complaint({
    this.timestamp,
    required this.category,
    required this.description,
    required this.userId,
    required this.ticketNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'category': category,
      'description': description,
      'userId': userId,
      'ticketNumber': ticketNumber,
    };
  }

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      timestamp: map['timestamp'],
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      ticketNumber: map['ticketNumber'] ?? '',
    );
  }
}