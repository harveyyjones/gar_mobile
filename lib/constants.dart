import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Constants {
 static const kTextColor = Color(0xFF535353);
 static const kTextLightColor = Color(0xFFACACAC);

 static const kDefaultPadding = 20.0;
 static FirebaseAuth auth = FirebaseAuth.instance;
 static User? currentUser = auth.currentUser;
 static String? get currentUserId => currentUser?.uid;

  // Typography
  static final heading1 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static final heading2 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static final heading3 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static final bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static final bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static final buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static final caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}
