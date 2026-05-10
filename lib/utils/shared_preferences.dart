// utils/shared_preferences.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class SharedPrefs {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Getters
  static String getString(String key, [String defaultValue = '']) {
    return _prefs.getString(key) ?? defaultValue;
  }

  static bool getBool(String key, [bool defaultValue = false]) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  static int getInt(String key, [int defaultValue = 0]) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  static double getDouble(String key, [double defaultValue = 0.0]) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  // Setters
  static Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  static Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  static Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  static Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  // Remove
  static Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  // Convenience methods for specific keys - UPDATED to camelCase
  static String get mobileNumber => getString(Constants.mobileNumber);
  static String get userFirebaseId => getString(Constants.userFirebaseId);
  static String get userName => getString(Constants.userName);
  static String get userEmail => getString(Constants.userEmail);
  static String get userCity => getString(Constants.userCity);
  static String get userZipcode => getString(Constants.userZipcode);
  static String get storeId => getString(Constants.storeId);
  static String get storeName => getString(Constants.storeName);
  static String get storeImageUrl => getString(Constants.storeImageUrl);
  static bool get isLoggedIn => getBool(Constants.isLoggedIn);
  static bool get isProfileDone => getBool(Constants.isProfileDone);
  static bool get isCartActive => getBool(Constants.isCartActive);
  
  // PayFast Merchant ID - NEW PROPERTY
  static String get payfastMerchantId => getString('payfast_merchant_id') ?? '';
  static set payfastMerchantId(String value) => setString('payfast_merchant_id', value);

  static Future<void> setUserData({
    String? mobileNumber,
    String? firebaseId,
    String? name,
    String? email,
    String? city,
    String? zipcode,
    bool? isLoggedIn,
    bool? isProfileDone,
  }) async {
    if (mobileNumber != null) await setString(Constants.mobileNumber, mobileNumber);
    if (firebaseId != null) await setString(Constants.userFirebaseId, firebaseId);
    if (name != null) await setString(Constants.userName, name);
    if (email != null) await setString(Constants.userEmail, email);
    if (city != null) await setString(Constants.userCity, city);
    if (zipcode != null) await setString(Constants.userZipcode, zipcode);
    if (isLoggedIn != null) await setBool(Constants.isLoggedIn, isLoggedIn);
    if (isProfileDone != null) await setBool(Constants.isProfileDone, isProfileDone);
  }

  static Future<void> setStoreData({
    String? storeId,
    String? storeName,
    String? storeImageUrl,
    bool? isCartActive,
    String? payfastMerchantId, // NEW: Added PayFast merchant ID
  }) async {
    if (storeId != null) await setString(Constants.storeId, storeId);
    if (storeName != null) await setString(Constants.storeName, storeName);
    if (storeImageUrl != null) await setString(Constants.storeImageUrl, storeImageUrl);
    if (isCartActive != null) await setBool(Constants.isCartActive, isCartActive);
    if (payfastMerchantId != null) {
      await setString('payfast_merchant_id', payfastMerchantId);
    }
  }

  static Future<void> clearUserData() async {
    await remove(Constants.mobileNumber);
    await remove(Constants.userFirebaseId);
    await remove(Constants.userName);
    await remove(Constants.userEmail);
    await remove(Constants.userCity);
    await remove(Constants.userZipcode);
    await remove(Constants.isLoggedIn);
    await remove(Constants.isProfileDone);
  }

  static Future<void> clearCartData() async {
    await remove(Constants.storeId);
    await remove(Constants.storeName);
    await remove(Constants.storeImageUrl);
    await remove(Constants.isCartActive);
    await remove('payfast_merchant_id'); // NEW: Clear PayFast merchant ID
  }
  
  // NEW: Convenience method to get all store data including PayFast merchant ID
  static Map<String, dynamic> getStoreData() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'storeImageUrl': storeImageUrl,
      'isCartActive': isCartActive,
      'payfastMerchantId': payfastMerchantId,
    };
  }
  
  // NEW: Debug method to print all stored preferences
  static void printAllPreferences() {
    print('=== SHARED PREFERENCES DEBUG ===');
    print('User Firebase ID: $userFirebaseId');
    print('User Email: $userEmail');
    print('User Name: $userName');
    print('Store ID: $storeId');
    print('Store Name: $storeName');
    print('PayFast Merchant ID: $payfastMerchantId');
    print('Is Cart Active: $isCartActive');
    print('Is Logged In: $isLoggedIn');
    print('=== END DEBUG ===');
  }
}