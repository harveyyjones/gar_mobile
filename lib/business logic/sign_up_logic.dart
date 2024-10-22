import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpLogic {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isValidEmail(String email) {
    return email.contains('@');
  }

  bool isValidPassword(String password) {
    return password.length > 5;
  }

  Future<String?> signUpUser(String email, String password) async {
    if (!isValidEmail(email)) {
      return 'Invalid email format';
    }

    if (!isValidPassword(password)) {
      return 'Password must be longer than 5 characters';
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _initializeUserData(userCredential.user!.uid);

      return null; // Return null if sign-up is successful
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      }
      return 'An error occurred. Please try again.';
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }
  Future<void> _initializeUserData(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'name': '',
      'surname': '',
      'nip_number': '',
      'address': {
        'adress_of_company': '',
        'adress_of_delivery': [
          {
            '0': {
              'adress': '',
              'business_entity': 'Ship to my place',
              'cargo_company': '',
              'cargo_customer_no': '',
              'city': '',
              'country': '',
              'name': '',
              'phone': '',
              'zip': '',
              'business_license_image': '',
              'company_name': '',
              'company_registration_no': '',
              'contact_name': '',
              'email': '',
              'eu_vat_no': '',
              'is_seller_in_app': true,
              'nip_number': '',
              'role': '',
              'tax_no': '',
              'uid': '',
              'zip_no': '02-458'
            }
          }
        ]
      },
      'phone': '',
      'email': _auth.currentUser?.email,
    }, SetOptions(merge: true));
  }
}