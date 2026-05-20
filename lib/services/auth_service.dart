import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as model;
import '../utils/constants.dart';
import '../utils/shared_prefs.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Do NOT call signInWithCredential here — it crashes for test numbers.
          // Just notify the caller with the sms code if available.
          onVerificationCompleted(credential.smsCode ?? '');
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      // Surface unexpected errors as a FirebaseAuthException so callers
      // can handle them consistently via onVerificationFailed.
      onVerificationFailed(
        FirebaseAuthException(code: 'unknown', message: e.toString()),
      );
    }
  }

  Future<UserCredential> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<bool> checkIfUserExists(String userId) async {
    try {
      final doc = await _firestore
          .collection(Constants.baseUsersUrl)
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        final user = model.User.fromMap(doc.data()!);
        await _saveUserProfileToPrefs(user);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveUserProfileToPrefs(model.User user) async {
    await SharedPrefs.setUserData(
      name: user.name,
      email: user.email,
      city: user.city,
      zipcode: user.zipcode,
      isProfileDone: true,
    );
  }

  Future<void> createUserProfile(model.User user, String firebaseId) async {
    await _firestore
        .collection(Constants.baseUsersUrl)
        .doc(firebaseId)
        .set(user.toMap());
    await _saveUserProfileToPrefs(user);
    await SharedPrefs.setUserData(isProfileDone: true);
  }

  Future<void> logout() async {
    await SharedPrefs.clear();
    await _auth.signOut();
  }

  User? getCurrentUser() => _auth.currentUser;
}