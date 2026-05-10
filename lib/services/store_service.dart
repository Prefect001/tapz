import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store.dart';
import '../utils/constants.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Store>> getStoresByZipcode(String zipcode) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.storesBaseUrl)
          .where(Constants.keyStoreZipcode, isEqualTo: zipcode)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['storeId'] = doc.id;
        return Store.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Store>> getAllStores() async {
    try {
      final snapshot =
          await _firestore.collection(Constants.storesBaseUrl).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['storeId'] = doc.id;
        return Store.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Store?> getStoreById(String storeId) async {
    try {
      final doc = await _firestore
          .collection(Constants.storesBaseUrl)
          .doc(storeId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['storeId'] = doc.id;
        return Store.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}