class Constants {
  // Shared Preferences keys
  static const String sharedPref = 'app';
  static const String keyProductRawData = 'productRawData';
  static const String keyTotalPrice = 'totalCost';
  static const String keyTotalQuantity = 'totalQuantity';
  static const String isPaymentDone = 'isPaymentDone';
  static const String paidAmount = 'amountPaid';
  static const String orderId = 'orderId';
  static const String transactionNumber = 'transactionNumber';
  static const String paymentMethodCard = 'card';
  static const String paymentStatusConfirmed = 'confirmed';

  // User
  static const String userFirebaseId = 'firebaseId';
  static const String userZipcode = 'zipcode';
  static const String userName = 'name';
  static const String userCity = 'city';
  static const String userEmail = 'userEmail';
  static const String mobileNumber = 'mobileNumber';
  static const String isLoggedIn = 'isLoggedIn';
  static const String isProfileDone = 'isProfileDone';

  // Store
  static const String storeId = 'storeId';
  static const String storeName = 'storeName';
  static const String storeUpiId = 'storeUpiID';
  static const String storeImageUrl = 'storeImageUrl';
  static const String keyStoreZipcode = 'zipcode';
  static const String keyStoreAddress = 'address';
  static const String keyStorePhone = 'mobileNumber';
  static const String keyStoreEmail = 'email';
  static const String payfastMerchantId = 'payfast_merchant_id';

  // Cart
  static const String isCartActive = 'cartStatus';

  // Location
  static const String lastLatitude = 'lastLatitude';
  static const String lastLongitude = 'lastLongitude';

  // Firestore collections
  static const String storesBaseUrl = 'stores';
  static const String complaintsBaseUrl = 'complaints/users/userComplaints';
  static const String bannerImagesBaseUrl = 'sliderImages';
  static const String baseOrderUrl = 'orders';
  static const String baseUsersUrl = 'customers';
  static const String productsCollection = 'Products';
  static const String paymentsCollection = 'payments';

  // Fixed tip amount
  static const double tipAmount = 22.00;
  static const String tipAmountString = '22.00';
  static const double doubleTipAmount = 44.00;
  static const String doubleTipAmountString = '44.00';
  static const double tripleTipAmount = 66.00;
  static const String tripleTipAmountString = '66.00';
}