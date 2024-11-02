import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_app/business%20logic/auth_service.dart';
import 'package:shop_app/business%20logic/dynamic_link_service.dart';
import 'package:shop_app/business%20logic/login_logic.dart';
import 'package:shop_app/business%20logic/sign_up_logic.dart';
import 'package:shop_app/screens/sign%20up%20page/sign_up_page.dart';
import 'constants.dart';
import 'screens/home/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth import

import 'screens/sign in page/sign_in_page.dart'; // Added Firebase import
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart'; // Added Firebase Dynamic Links import


void main() async { // Updated main function
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget { // Changed MyApp to StatefulWidget
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> { // New state class for MyApp
  final _dynamicLinkData = ValueNotifier<Uri?>(null); // Changed to use ValueNotifier for dynamic links
  final AuthService _authService = AuthService();
  final LoginLogic _loginLogic = LoginLogic();
  final SignUpLogic _signUpLogic = SignUpLogic();

  @override
  void initState() {
    super.initState();
    _initializeDynamicLinks(); // Initialize dynamic links
  }

  Future<void> _initializeDynamicLinks() async { // New method to handle dynamic links
    try {
      // Handle initial dynamic link if app was terminated
      final PendingDynamicLinkData? initialLink = 
          await FirebaseDynamicLinks.instance.getInitialLink(); // Use the new method here
      
      if (initialLink != null) {
        _dynamicLinkData.value = initialLink.link;
      }

      // Handle dynamic links when app is in background or foreground
      FirebaseDynamicLinks.instance.onLink.listen(
        (PendingDynamicLinkData dynamicLinkData) {
          _dynamicLinkData.value = dynamicLinkData.link;
        },
        onError: (error) {
          print('Dynamic Link Error: ${error.message}');
        },
      );
    } catch (e) {
      print('Error initializing dynamic links: $e'); // Added error handling
    }
  }

  void _handleDynamicLink(PendingDynamicLinkData data) { // New method to handle dynamic link data
    final Uri deepLink = data.link;
    
    // Handle navigation based on link parameters
    if (deepLink.pathSegments.contains('product')) {
      final productId = deepLink.queryParameters['id'];
      if (productId != null) {
        _navigateAfterAuth(deepLink);
      }
    } else if (deepLink.pathSegments.contains('seller')) {
      final sellerId = deepLink.queryParameters['id'];
      if (sellerId != null) {
        _navigateAfterAuth(deepLink);
      }
    }
  }

  void _navigateAfterAuth(Uri deepLink) { // New method to navigate after authentication
    // Store the deep link to be handled after authentication
    // You can use shared preferences or other state management solution
    DynamicLinkService().setInitialLink(deepLink);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wholesale E-commerce App', // Updated title
      theme: ThemeData(
        primarySwatch: Colors.blue, // Updated theme
        textTheme: Theme.of(context).textTheme.apply(bodyColor: Constants.kTextColor),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
     home: AuthWrapper()
      // home: ValueListenableBuilder<Uri?>(
      //   valueListenable: _dynamicLinkData,
      //   builder: (context, deepLink, child) {
      //     return AuthWrapper(initialDeepLink: deepLink);
      //   },
      // ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final LoginLogic _loginLogic = LoginLogic();
  final SignUpLogic _signUpLogic = SignUpLogic();

  AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (snapshot.hasData) {
          return HomePage();
        }

        return AuthPage(loginLogic: _loginLogic, signUpLogic: _signUpLogic);
      },
    );
  }
}


class AppColors {
  static const primary = Color(0xFF0A84FF);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF9FAFB);
  static const text = Color(0xFF1A1D1E);
  static const textLight = Color(0xFF6B7280);
  static const error = Color(0xFFDC2626);
}

class AuthPage extends StatelessWidget {
  final LoginLogic loginLogic;
  final SignUpLogic signUpLogic;

  AuthPage({required this.loginLogic, required this.signUpLogic});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Pattern
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(),
                  const Spacer(),
                  _buildAuthButtons(context),
                  const SizedBox(height: 40),
                  // _buildFooter(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Witamy w',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        Text(
          'Loris Mobile',
          style: GoogleFonts.montserrat(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Twój premium rynek hurtowy perfum.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppColors.textLight,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPrimaryButton(
          'Zaloguj się',
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => LoginPage(
                  onLoginPressed: (email, password) async {
                    String? error = await loginLogic.loginUser(email, password);
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    } else {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (context) => HomePage()),
                      );
                    }
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSecondaryButton(
          'Utwórz konto',
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => SignUpPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text, {required VoidCallback onPressed}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, {required VoidCallback onPressed}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildFooter() {
  //   return Column(
  //     children: [
  //       Row(
  //         children: [
  //           Expanded(child: Divider(color: AppColors.textLight.withOpacity(0.2))),
  //           Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 16),
  //             child: Text(
  //               'Lub kontynuuj z',
  //               style: GoogleFonts.poppins(
  //                 color: AppColors.textLight,
  //                 fontSize: 14,
  //               ),
  //             ),
  //           ),
  //           Expanded(child: Divider(color: AppColors.textLight.withOpacity(0.2))),
  //         ],
  //       ),
  //       const SizedBox(height: 24),

  //     ],
  //   );
  // }

  Widget _buildSocialButton(String iconPath, {required VoidCallback onPressed}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textLight.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Image.asset(
              iconPath,
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
    );
  }
}

