import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_app/screens/home/home_screen.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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

      await _initializeUserDataForCustomer(userCredential.user!.uid);

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


Future<void> _initializeUserDataForCustomer(String uid) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    throw Exception('No user is currently signed in');
  }

  // Create a reference to the user document
  DocumentReference userRef = firestore.collection('users').doc(currentUser.uid);

  // Initialize the user data
  Map<String, dynamic> userData = {
    'adress_of_company': '',
    'adress_of_delivery': [
      {
        'adress': '',
        'business_entity': 'Ship to my place',
        'cargo_company': '',
        'cargo_customer_no': '',
        'city': '',
        'country': '',
        'name': '',
        'phone': '',
        'zip': '',
      }
    ],
    'business_entity': '',
    'business_license_image': '',
    'city': '',
    'company_name': '',
    'company_registration_no': '',
    'contact_name': '',
    'country': '',
    'email': '',
    'eu_vat_no': '',
    'nip_number': '',
    'phone': '',
    'role': '',
    'tax_no': '',
    'uid': currentUser.uid,
    'zip_no': '02-458',
  };

  // Initialize cart data
  Map<String, dynamic> cartData = {
    'cart_items': []
  };

  // Initialize orders collection (empty for now)
  // We don't need to explicitly create an empty collection in Firestore

  // Batch write to ensure atomicity
  WriteBatch batch = firestore.batch();

  // Set the user data
  batch.set(userRef, userData, SetOptions(merge: true));

  // Set the cart data
  batch.set(userRef.collection('cart').doc('current_cart'), cartData);

  // Commit the batch
  await batch.commit();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text;
                final password = passwordController.text;
                String? error = await signUpUser(email, password);
                if (error == null) {
                  Navigator.of(context).push(CupertinoPageRoute(builder: (context) => HomePage()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                }
              },
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}