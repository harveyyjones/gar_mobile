import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_app/business%20logic/models/wholesaler_model.dart';
import 'package:shop_app/business%20logic/sign_up_logic.dart';
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
  final SignUpLogic _signUpLogic = SignUpLogic(); // Initialize SignUpLogic
  UserType selectedUserType = UserType.customer; // Change to UserType enum

  bool isValidEmail(String email) {
    return email.contains('@');
  }

  bool isValidPassword(String password) {
    return password.length > 5;
  }

  Future<void> _initializeSellerData(String uid) async {
    try {
      // Create default address details
      final addressDetails = AddressDetails(
        addressOfCompany: '',
        city: '',
        country: '',
        zipNo: '',
      );

      // Create default working hours
      final defaultDayHours = DayHours(open: "09:00", close: "17:00");
      final workingHours = WorkingHours(
        monday: defaultDayHours,
        tuesday: defaultDayHours,
        wednesday: defaultDayHours,
        thursday: defaultDayHours,
        friday: defaultDayHours,
        saturday: defaultDayHours,
        sunday: defaultDayHours,
      );

      // Create default bank details
      final bankDetails = BankDetails(
        accountNumber: '',
        bankName: '',
        swiftCode: '',
      );

      // Create the wholesaler model
      final wholesaler = WholesalerModel(
        id: uid,
        email: _auth.currentUser?.email ?? '',
        phone: '',
        name: '',
        logoUrl: '',
        surname: '',
        nipNumber: '',
        isActive: true,
        isSellerInApp: true,
        rating: 0.0,
        totalSales: 0,
        createdAt: DateTime.now(),
        address: addressDetails,
        bankDetails: bankDetails,
        categories: [],
        paymentMethods: [],
        products: [],
        shippingMethods: [],
        workingHours: workingHours, sellerId: uid, 
      );

      // Debug log the data before saving
      print('Saving wholesaler data:');
      print(wholesaler.toFirestore());

      // Convert to Firestore data and save
      await _firestore.collection('sellers').doc(uid).set(wholesaler.toFirestore());

      // Initialize subcollections
      final batch = _firestore.batch();
      
      // Products subcollection
      batch.set(
        _firestore.collection('sellers').doc(uid).collection('products').doc('placeholder'),
        {'initialized': true}
      );

      // Orders subcollection
      batch.set(
        _firestore.collection('sellers').doc(uid).collection('orders').doc('placeholder'),
        {'initialized': true}
      );

      await batch.commit();
    } catch (e) {
      print('Error initializing seller data: $e');
      rethrow;
    }
  }

  Future<void> _initializeCustomerData(String uid) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('No user is currently signed in');
    }

    DocumentReference userRef = firestore.collection('users').doc(currentUser.uid);

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
      'email': currentUser.email ?? '',
      'eu_vat_no': '',
      'nip_number': '',
      'phone': '',
      'role': 'customer',
      'tax_no': '',
      'uid': currentUser.uid,
      'zip_no': '',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    WriteBatch batch = firestore.batch();
    batch.set(userRef, userData);
    batch.set(
      userRef.collection('cart').doc('current_cart'),
      {'cart_items': []},
    );
    batch.set(
      userRef.collection('likes').doc('placeholder'),
      {'initialized': true},
    );
    batch.set(
      userRef.collection('orders').doc('placeholder'),
      {'initialized': true},
    );
    await batch.commit();
  }

  Future<String?> signUpUser(
    String email, 
    String password, 
    { 
      String? userType, 
      Map<String, dynamic>? additionalData 
    } 
  ) async {
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

      if (selectedUserType == UserType.wholesaler) {
        await _initializeSellerData(userCredential.user!.uid);
      } else {
        await _initializeCustomerData(userCredential.user!.uid);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      }
      return 'An error occurred. Please try again.';
    } catch (e) {
      print('Error during sign up: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            // Role Selection
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'I want to:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  RadioListTile<UserType>(
                    title: const Text('Buy Products (Customer)'),
                    value: UserType.customer,
                    groupValue: selectedUserType,
                    onChanged: (UserType? value) {
                      if (value != null) {
                        setState(() => selectedUserType = value);
                      }
                    },
                  ),
                  RadioListTile<UserType>(
                    title: const Text('Sell Products (Wholesaler)'),
                    value: UserType.wholesaler,
                    groupValue: selectedUserType,
                    onChanged: (UserType? value) {
                      if (value != null) {
                        setState(() => selectedUserType = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text;
                final password = passwordController.text;
                
                String? error = await _signUpLogic.signUpUser( // Call signUpUser from SignUpLogic
                  email,
                  password,
                  selectedUserType, // Pass selectedUserType to signUpUser
                );
                if (error == null) {
                  Navigator.of(context).pushAndRemoveUntil(
                    CupertinoPageRoute(builder: (context) => HomePage()),
                    (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
