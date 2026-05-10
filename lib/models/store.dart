import 'package:google_maps_flutter/google_maps_flutter.dart';

class Store {
  final String storeId;
  final String storeName;
  final String address;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String storeExtraInfo;
  final String mobileNumber;
  final String email;
  final String zipcode;
  final String storeUpiId;
  final String payfastMerchantId;

  Store({
    required this.storeId,
    required this.storeName,
    this.address = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.imageUrl = '',
    this.storeExtraInfo = '',
    this.mobileNumber = '',
    this.email = '',
    this.zipcode = '',
    this.storeUpiId = '',
    this.payfastMerchantId = '',
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      storeExtraInfo: map['storeExtraInfo'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      email: map['email'] ?? '',
      zipcode: map['zipcode'] ?? '',
      storeUpiId: map['storeUpiId'] ?? '',
      payfastMerchantId: map['payfastMerchantId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'storeExtraInfo': storeExtraInfo,
      'mobileNumber': mobileNumber,
      'email': email,
      'zipcode': zipcode,
      'storeUpiId': storeUpiId,
      'payfastMerchantId': payfastMerchantId,
    };
  }
}