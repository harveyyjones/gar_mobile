import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to check user type
  Stream<String> getUserTypeStream() {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return 'none';
      
      try {
        // Check in users collection
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) return 'user';

        // Check in sellers collection
        final sellerDoc = await _firestore.collection('sellers').doc(user.uid).get();
        if (sellerDoc.exists) return 'seller';

        // If user exists in auth but not in either collection
        return 'undefined';
      } catch (e) {
        print('Error determining user type: $e');
        return 'error';
      }
    });
  }

  // Method to check user type once
  Future<String> getUserType() async {
    final user = _auth.currentUser;
    if (user == null) return 'none';

    try {
      // Check in users collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) return 'user';

      // Check in sellers collection
      final sellerDoc = await _firestore.collection('sellers').doc(user.uid).get();
      if (sellerDoc.exists) return 'seller';

      return 'undefined';
    } catch (e) {
      print('Error determining user type: $e');
      return 'error';
    }
  }

  // Helper method to get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Check in users collection first
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return {
          'type': 'user',
          'data': userDoc.data(),
        };
      }

      // If not found in users, check in sellers
      final sellerDoc = await _firestore.collection('sellers').doc(user.uid).get();
      if (sellerDoc.exists) {
        return {
          'type': 'seller',
          'data': sellerDoc.data(),
        };
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Sign out helper
  Future<void> signOut() async {
    await _auth.signOut();
  }
}