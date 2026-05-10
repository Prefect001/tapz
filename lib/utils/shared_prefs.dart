import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class SharedPrefs {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Generic getters/setters
  static String getString(String key, [String defaultValue = '']) =>
      _prefs.getString(key) ?? defaultValue;

  static bool getBool(String key, [bool defaultValue = false]) =>
      _prefs.getBool(key) ?? defaultValue;

  static Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  static Future<bool> setBool(String key, bool value) =>
      _prefs.setBool(key, value);

  static Future<bool> remove(String key) => _prefs.remove(key);

  static Future<void> clear() => _prefs.clear();

  // Convenience properties
  static String get userFirebaseId => getString(Constants.userFirebaseId);
  static String get userName => getString(Constants.userName);
  static String get userEmail => getString(Constants.userEmail);
  static String get userCity => getString(Constants.userCity);
  static String get userZipcode => getString(Constants.userZipcode);
  static String get mobileNumber => getString(Constants.mobileNumber);
  static bool get isLoggedIn => getBool(Constants.isLoggedIn);
  static bool get isProfileDone => getBool(Constants.isProfileDone);
  static bool get isCartActive => getBool(Constants.isCartActive);
  static String get storeId => getString(Constants.storeId);
  static String get storeName => getString(Constants.storeName);
  static String get storeImageUrl => getString(Constants.storeImageUrl);
  static String get payfastMerchantId => getString(Constants.payfastMerchantId);

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
    String? payfastMerchantId,
  }) async {
    if (storeId != null) await setString(Constants.storeId, storeId);
    if (storeName != null) await setString(Constants.storeName, storeName);
    if (storeImageUrl != null) await setString(Constants.storeImageUrl, storeImageUrl);
    if (isCartActive != null) await setBool(Constants.isCartActive, isCartActive);
    if (payfastMerchantId != null) await setString(Constants.payfastMerchantId, payfastMerchantId);
  }

  static Future<void> clearCart() async {
    await remove(Constants.storeId);
    await remove(Constants.storeName);
    await remove(Constants.storeImageUrl);
    await remove(Constants.isCartActive);
    await remove(Constants.payfastMerchantId);
    await remove(Constants.orderId);
    await remove(Constants.paidAmount);
    await remove(Constants.transactionNumber);
    await remove(Constants.isPaymentDone);
    await remove(Constants.storeUpiId);
  }
}