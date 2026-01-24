// lib/const/styles/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // ========== SPACE GROTESK (For Titles) ==========
  
 
  static TextStyle headlineLarge = GoogleFonts.roboto(
    fontWeight: FontWeight.w500,
    fontSize: 32.sp,
    color: Colors.black,
  );
    static TextStyle headlineMedium = GoogleFonts.roboto(
    fontWeight: FontWeight.w600,
    fontSize: 24.sp,
    color: Colors.black,
  );

    static TextStyle headlineSmall = GoogleFonts.roboto(
    fontWeight: FontWeight.w500,
    fontSize: 16.sp,
    color: Colors.black,
  );
      static TextStyle bodyLarge = GoogleFonts.roboto(
    fontWeight: FontWeight.w600,
    fontSize: 16.sp,
    color: Colors.black,
  );
      static TextStyle bodyMedium = GoogleFonts.roboto(
    fontWeight: FontWeight.w500,
    fontSize: 14.sp,
    color: Colors.black,
  );

      static TextStyle bodySmall = GoogleFonts.roboto(
    fontWeight: FontWeight.w400,
    fontSize: 12.sp,
    color: Color(0xff848484),
  );
  
 
  static TextStyle authSubtitle = GoogleFonts.inter(
   // fontWeight: FontWeight.w400,
    fontSize: 14.sp,
    //height: 24 / 16,
    color: Colors.black,
  );


}