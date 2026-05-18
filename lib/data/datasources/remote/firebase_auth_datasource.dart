import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/user_model.dart';

/// Firebase authentication data source
class FirebaseAuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  FirebaseAuthDataSource({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _firestore = firestore;

  /// Get current authenticated user
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        final newUser = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
        );
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toJson());
        return newUser;
      }

      return UserModel.fromJson({
        'id': firebaseUser.uid,
        ...userDoc.data()!,
      });
    } catch (e) {
      throw AuthException(message: 'Failed to get current user: $e');
    }
  }

  /// Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException(message: 'Google sign-in was cancelled');
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      // Create or update user document
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      final user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        preferredUnit: userDoc.exists
            ? (userDoc.data()?['preferredUnit'] as String? ?? 'kg')
            : 'kg',
        defaultRestTime: userDoc.exists
            ? (userDoc.data()?['defaultRestTime'] as int? ?? 90)
            : 90,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toJson(), SetOptions(merge: true));

      return user;
    } catch (e) {
      throw AuthException(message: 'Failed to sign in with Google: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException(message: 'Failed to sign out: $e');
    }
  }

  /// Stream of auth state changes
  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await getCurrentUser();
    });
  }

  /// Update user preferences
  Future<void> updateUserPreferences({
    String? preferredUnit,
    int? defaultRestTime,
  }) async {
    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) {
        throw AuthException(message: 'No authenticated user');
      }

      final updates = <String, dynamic>{};
      if (preferredUnit != null) updates['preferredUnit'] = preferredUnit;
      if (defaultRestTime != null) updates['defaultRestTime'] = defaultRestTime;

      await _firestore
          .collection('users')
          .doc(userId)
          .update(updates);
    } catch (e) {
      throw AuthException(message: 'Failed to update preferences: $e');
    }
  }
}
