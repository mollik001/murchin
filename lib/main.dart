import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:murcin/features/onboarding/onboarding_screen.dart';

void main() {
  // Run everything inside a single zone so bindings and runApp use the same zone
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase before any Firebase usage
    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized');
    } catch (e, st) {
      print('❌ Firebase initialization failed: $e\n$st');
      // Continue — app may still fail if Firebase is required
    }

    // Pre-load Google Fonts (after Firebase init)
    await _preloadGoogleFonts();

    // Capture Flutter errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      print('FlutterError: ${details.exceptionAsString()}');
      print(details.stack);
    };

    runApp(const MyApp());
  }, (error, stack) {
    print('Uncaught zone error: $error\n$stack');
  });
}

// Function to pre-load Google Fonts
Future<void> _preloadGoogleFonts() async {
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.roboto(),
      GoogleFonts.inter(),
    ]);
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
          title: 'Pickfair AI',
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



// grep -qxF '/ios/build/' .gitignore || printf "\n/ios/build/\n" >> .gitignore
// git rm -r --cached ios/build
// git add .gitignore
// git commit --amend --no-edit
// git push origin main


