import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shop_app/business%20logic/login_logic.dart';
import 'package:shop_app/business%20logic/sign_up_logic.dart';
import 'package:shop_app/screens/sign%20up%20page/sign_up_page.dart';
import 'constants.dart';
import 'screens/home/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth import

import 'screens/sign in page/sign_in_page.dart'; // Added Firebase import

void main() async { // Updated main function
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
     
      home: AuthWrapper(), // Updated home widget
    );
  }
}

class AuthWrapper extends StatelessWidget { // Renamed from LoginWrapper to AuthWrapper
  final LoginLogic _loginLogic = LoginLogic();
  final SignUpLogic _signUpLogic = SignUpLogic(); // Added SignUpLogic instance

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>( // Added StreamBuilder for auth state
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { // Added loading state
          return CircularProgressIndicator(); // Show loading indicator
        } else if (snapshot.hasData) {
          print('User ID: ${snapshot.data!.uid}'); // Log the user ID
          return HomePage(); // Navigate to HomePage if user is logged in
        } else {
          return AuthPage(loginLogic: _loginLogic, signUpLogic: _signUpLogic); // Updated to use AuthPage
        }
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
