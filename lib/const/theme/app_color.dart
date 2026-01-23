import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF4203966);
  static const Color primaryDark = Color(0xFF406499);
  static const Color primaryLight = Color(0xFF406499);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF36C2CE);
  static const Color secondaryDark = Color(0xFF2AA3AD);
  static const Color secondaryLight = Color(0xFF5DD9E5);
  
  // Neutral Colors
  static const Color blue = Color(0xFF1936EB);
  static const Color lighBlue = Color(0xFF6678F3);
  static const Color veryLightBlue = Color(0xFF4588C6);
  static const Color bgGrey = Color(0xFFBDC4D2);
  
  // Gray Scale
  static const Color gray900 = Color(0xFF212529);
  static const Color gray800 = Color(0xFF343A40);
  static const Color gray700 = Color(0xFF495057);
  static const Color gray600 = Color(0xFF6C757D);
  static const Color gray500 = Color(0xFFADB5BD);
  static const Color gray400 = Color(0xFFCED4DA);
  static const Color gray300 = Color(0xFFDEE2E6);
  static const Color gray200 = Color(0xFFE9ECEF);
  static const Color gray100 = Color(0xFFF8F9FA);
  
  // Semantic Colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );
}