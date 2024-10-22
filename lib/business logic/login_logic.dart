import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginLogic {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isValidEmail(String email) {
    return email.contains('@');
  }

  bool isValidPassword(String password) {
    return password.length > 5;
  }

  Future<String?> loginUser(String email, String password) async {
    if (!isValidEmail(email)) {
      return 'Invalid email format';
    }

    if (!isValidPassword(password)) {
      return 'Password must be longer than 5 characters';
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );


      return null; // Return null if login is successful
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      }
      return 'An error occurred. Please try again.';
    }
  }

 
}