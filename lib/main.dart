import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murchin/features/onboarding/onboarding_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-load Google Fonts before runApp
  await _preloadGoogleFonts();
  await Firebase.initializeApp();

  
  runApp(const MyApp());
}

// Function to pre-load Google Fontsdo

Future<void> _preloadGoogleFonts() async {
  try {
  
    await GoogleFonts.pendingFonts([
      GoogleFonts.roboto(), // Main font
      GoogleFonts.inter(),  // Secondary font if used
    ]);
    
    // Alternative method: Load specific font variants
    await Future.wait([
      GoogleFonts.robotoTextTheme().bodyLarge,
      GoogleFonts.robotoTextTheme().headlineLarge,
      Future.delayed(const Duration(milliseconds: 100)), // Small delay
    ] as Iterable<Future<dynamic>>);
    
    print("✅ Google Fonts pre-loaded successfully");
  } catch (e) {
    print("⚠️ Error pre-loading Google Fonts: $e");
    // Continue anyway, fonts will load lazily
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852), // iPhone 11 Pro dimensions
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          title: 'PickFair',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // Apply Google Fonts to the entire app
            fontFamily: GoogleFonts.roboto().fontFamily,
            textTheme: GoogleFonts.robotoTextTheme(
              Theme.of(context).textTheme,
            ),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          // Using GetX for navigation
          home: const LandingPage(),
        );
      },
    );
  }
}


//onboarding selection page title double line
//ai text color 
//Navigation flow change
//removing toggle from profile page
// Terms & policy page


//TODO:

 //i can not find The Memphis Grizzlies vs New York Knicks game still.
 //data handling issue with date and timel.