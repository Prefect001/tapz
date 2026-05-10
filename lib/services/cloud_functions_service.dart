import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';

class CloudFunctionsService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'africa-south1');

  static Future<Map<String, dynamic>> initiatePayfastPayment({
    required String amount,
    required String orderId,
    required String email,
    required String name,
    required String storeId,
    required String customerUid,
    bool tokenize = false,
    bool cardRegistration = false,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'initiatePayfastPayment',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final data = {
        'amount': amount,
        'orderId': orderId,
        'email': email,
        'name': name,
        'storeId': storeId,
        'tokenize': tokenize,
        'customerUid': customerUid,
        if (cardRegistration) 'cardRegistration': true,
        if (cardRegistration) 'tokenize': true,
      };

      print('📤 Cloud Function payload: ${jsonEncode(data)}');
      final result = await callable.call(data);
      final response = Map<String, dynamic>.from(result.data as Map);
      print('📥 Cloud Function response: ${jsonEncode(response)}');

      final token = response['paymentToken'] ?? response['uuid'] ?? response['token'];
      if (token != null) {
        return {'success': true, 'paymentToken': token};
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Payment initialization failed',
      };
    } catch (e) {
      print('❌ Cloud Function error: $e');
      return {'success': false, 'error': _parseError(e.toString())};
    }
  }

  static Future<Map<String, dynamic>> processSavedCardPayment({
    required String amount,
    required String orderId,
    required String email,
    required String name,
    required String storeId,
    required String customerUid,
    required String token,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'processSavedCardPayment',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final data = {
        'amount': amount,
        'orderId': orderId,
        'email': email,
        'name': name,
        'storeId': storeId,
        'customerUid': customerUid,
        'token': token,
      };

      final result = await callable.call(data);
      final response = Map<String, dynamic>.from(result.data as Map);

      final paymentToken =
          response['paymentToken'] ?? response['uuid'] ?? response['token'];
      if (paymentToken != null) {
        return {'success': true, 'paymentToken': paymentToken};
      }
      if (response['success'] == true) {
        return {'success': true};
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Saved card payment failed',
      };
    } catch (e) {
      return {'success': false, 'error': _parseError(e.toString())};
    }
  }

  static String _parseError(String errorString) {
    if (errorString.contains('UNAVAILABLE')) {
      return 'Payment service unavailable. Please check your internet connection.';
    } else if (errorString.contains('INTERNAL')) {
      return 'Payment service error. Please try again later.';
    } else if (errorString.contains('DEADLINE_EXCEEDED')) {
      return 'Payment timeout. Please try again.';
    } else if (errorString.contains('PERMISSION_DENIED')) {
      return 'Authentication failed. Please login again.';
    }
    return 'Payment failed. Please try again.';
  }
}