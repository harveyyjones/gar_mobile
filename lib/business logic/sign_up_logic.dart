import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType {
  customer,
  wholesaler
}

class SignUpLogic {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isValidEmail(String email) {
    return email.contains('@');
  }

  bool isValidPassword(String password) {
    return password.length > 5;
  }

  Future<String?> signUpUser(String email, String password, UserType userType) async {
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

      // Initialize data based on user type
      if (userType == UserType.customer) {
        await _initializeCustomerData(userCredential.user!.uid);
      } else {
        await _initializeWholesalerData(userCredential.user!.uid);
      }

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

  Future<void> _initializeCustomerData(String uid) async {
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
              'role': 'customer',
              'tax_no': '',
              'uid': '',
              'zip_no': '02-458'
            }
          }
        ]
      },
      'phone': '',
      'email': _auth.currentUser?.email,
      'created_at': FieldValue.serverTimestamp(),
      'cart_items': [],
      'liked_items': [],
    }, SetOptions(merge: true));
  }

  Future<void> _initializeWholesalerData(String uid) async {
    await _firestore.collection('sellers').doc(uid).set({
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
              'role': 'wholesaler',
              'tax_no': '',
              'uid': '',
              'zip_no': '02-458'
            }
          }
        ]
      },
      'phone': '',
      'email': _auth.currentUser?.email,
      'created_at': FieldValue.serverTimestamp(),
      'is_active': true,
      'rating': 0,
      'total_sales': 0,
      'products': [],
      'categories': [],
      'bank_details': {
        'account_number': '',
        'bank_name': '',
        'swift_code': '',
      },
      'shipping_methods': [],
      'payment_methods': [],
      'working_hours': {
        'monday': {'open': '', 'close': ''},
        'tuesday': {'open': '', 'close': ''},
        'wednesday': {'open': '', 'close': ''},
        'thursday': {'open': '', 'close': ''},
        'friday': {'open': '', 'close': ''},
        'saturday': {'open': '', 'close': ''},
        'sunday': {'open': '', 'close': ''},
      },
    }, SetOptions(merge: true));
  }
}
