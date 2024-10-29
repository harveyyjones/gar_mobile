import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
     
      home: ValueListenableBuilder<Uri?>(
        valueListenable: _dynamicLinkData,
        builder: (context, deepLink, child) {
          return AuthWrapper(initialDeepLink: deepLink);
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Uri? initialDeepLink; // Declare the parameter
  final AuthService _authService = AuthService();
  final LoginLogic _loginLogic = LoginLogic();
  final SignUpLogic _signUpLogic = SignUpLogic();

  // Update constructor to use named parameter
  AuthWrapper({
    Key? key,
    this.initialDeepLink, // Add named parameter
  }) : super(key: key);

  Future<void> _handleDeepLink(BuildContext context, Uri deepLink) async {
    // ... existing code ...l
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (!authSnapshot.hasData) {
          return AuthPage(loginLogic: _loginLogic, signUpLogic: _signUpLogic);
        }

        // User is logged in, now determine their type
        return StreamBuilder<String>(
          stream: _authService.getUserTypeStream(),
          builder: (context, userTypeSnapshot) {
            if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: Colors.white,
                child: const Center(
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              );
            }

            // Handle errors
            if (userTypeSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Error loading profile'),
                    SizedBox(height: 8),
                    CupertinoButton(
                      child: Text('Try Again'),
                      onPressed: () {
                        // Force refresh
                        FirebaseAuth.instance.currentUser?.reload();
                      },
                    ),
                    CupertinoButton(
                      child: Text('Sign Out'),
                      onPressed: () => _authService.signOut(),
                    ),
                  ],
                ),
              );
            }

            switch (userTypeSnapshot.data) {
              case 'user':
                return HomePage();
              case 'seller':
                return HomePage();
              case 'undefined':
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Account setup incomplete'),
                      CupertinoButton(
                        child: Text('Sign Out'),
                        onPressed: () => _authService.signOut(),
                      ),
                    ],
                  ),
                );
              case 'error':
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error determining account type'),
                      CupertinoButton(
                        child: Text('Try Again'),
                        onPressed: () {
                          FirebaseAuth.instance.currentUser?.reload();
                        },
                      ),
                    ],
                  ),
                );
              default:
                return AuthPage(loginLogic: _loginLogic, signUpLogic: _signUpLogic);
            }
          },
        );
      },
    );
  }
}

class AuthPage extends StatelessWidget { // New AuthPage class
  final LoginLogic loginLogic;
  final SignUpLogic signUpLogic;

  AuthPage({required this.loginLogic, required this.signUpLogic}); // Constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage(
                    onLoginPressed: (email, password) async {
                      String? error = await loginLogic.loginUser(email, password);
                      error != null ? ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))) : Navigator.push(context, CupertinoPageRoute(builder: (context) => HomePage()));
                      // No need to navigate, AuthWrapper will handle it
                    },
                  )),
                );
              },
              child: Text('Login'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage(
                   
                  )),
                );
              },
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
