import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_app/business%20logic/models/wholesaler_model.dart';
import 'package:shop_app/business%20logic/sign_up_logic.dart';
import 'package:shop_app/screens/home/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_app/screens/sign%20in%20page/sign_in_page.dart';

// Modern color scheme
class AppColors {
  static const primary = Color(0xFF0A84FF);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF9FAFB);
  static const text = Color(0xFF1A1D1E);
  static const textLight = Color(0xFF6B7280);
  static const error = Color(0xFFDC2626);
}

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
  bool _isLoading = false; // Added loading state

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

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    Expanded(
                      child: _buildForm(),
                    ),
                    _buildFooter(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create an account to continue',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppColors.textLight,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildInputField(
          controller: emailController,
          label: 'Email',
          icon: CupertinoIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: passwordController,
          label: 'Password',
          icon: CupertinoIcons.lock,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        _buildSignUpButton(),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColors.text,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: AppColors.textLight,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.textLight,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
                setState(() => _isLoading = true);
                
                try {
                  final email = emailController.text;
                  final password = passwordController.text;
                  
                  String? error = await _signUpLogic.signUpUser(
                    email,
                    password,
                    selectedUserType,
                  );
                  
                  if (!mounted) return;
                  
                  if (error == null) {
                    Navigator.of(context).pushAndRemoveUntil(
                      CupertinoPageRoute(builder: (context) => HomePage()),
                      (route) => false,
                    );
                  } else {
                    _showError(error);
                  }
                } catch (e) {
                  _showError('An unexpected error occurred. Please try again.');
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 1,
              width: 100,
              color: Colors.grey.withOpacity(0.2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: GoogleFonts.poppins(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              height: 1,
              width: 100,
              color: Colors.grey.withOpacity(0.2),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Already have an account?',
          style: GoogleFonts.poppins(
            color: AppColors.textLight,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => LoginPage())),
          child: Text(
            'Sign In',
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
