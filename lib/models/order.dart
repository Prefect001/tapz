import 'package:intl/intl.dart';
import 'product_item.dart';

class Order {
  int? id;
  final String orderId;
  final String storeId;
  final String storeName;
  final String userId;
  final int totalQuantity;
  final double totalPrice;
  final List<ProductItem> items;
  final String? transactionNumber;
  final String userName;
  final DateTime date;
  final String? paymentMethod;
  final bool verified;

  Order({
    this.id,
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.userId,
    required this.totalQuantity,
    required this.totalPrice,
    required this.items,
    this.transactionNumber,
    required this.userName,
    required this.date,
    this.paymentMethod,
    this.verified = false,
  });

  String getFormattedDate() {
    return DateFormat('dd-MMM-yyyy hh:mm aa').format(date);
  }

  Map<String, dynamic> toMap() {
    final itemsStr = items
        .map((item) =>
            '${item.id},${item.productId},${item.productName},${item.productPrice},${item.productQuantity}')
        .join('|');
    return {
      if (id != null) 'id': id,
      'orderId': orderId,
      'storeId': storeId,
      'storeName': storeName,
      'userId': userId,
      'totalQuantity': totalQuantity,
      'totalPrice': totalPrice,
      'items': itemsStr,
      'transactionNumber': transactionNumber,
      'userName': userName,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'verified': verified ? 1 : 0,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    List<ProductItem> items = [];
    if (map['items'] != null && (map['items'] as String).isNotEmpty) {
      final itemsData = (map['items'] as String).split('|');
      items = itemsData.map((itemStr) {
        final itemParts = itemStr.split(',');
        if (itemParts.length >= 5) {
          return ProductItem(
            id: int.tryParse(itemParts[0]),
            productId: itemParts[1],
            productName: itemParts[2],
            productPrice: double.tryParse(itemParts[3]) ?? 0.0,
            productQuantity: int.tryParse(itemParts[4]) ?? 1,
          );
        }
        return ProductItem(productId: '', productName: '', productPrice: 0);
      }).toList();
    }

    return Order(
      id: map['id'],
      orderId: map['orderId'] ?? '',
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
      userId: map['userId'] ?? '',
      totalQuantity: map['totalQuantity'] ?? 0,
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      items: items,
      transactionNumber: map['transactionNumber'],
      userName: map['userName'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      paymentMethod: map['paymentMethod'],
      verified: map['verified'] == 1,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'orderId': orderId,
      'storeId': storeId,
      'storeName': storeName,
      'userId': userId,
      'totalQuantity': totalQuantity,
      'totalPrice': totalPrice,
      'items': items.map((item) => item.toFirestoreMap()).toList(),
      'transactionNumber': transactionNumber,
      'userName': userName,
      'date': date,
      'paymentMethod': paymentMethod,
      'verified': verified,
      'status': transactionNumber != null ? 'paid' : 'pending',
    };
  }
}