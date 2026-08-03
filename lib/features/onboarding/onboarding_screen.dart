// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:murcin/const/theme/app_color.dart';
// import 'package:murcin/const/theme/app_theme.dart';
// import 'package:murcin/const/widgets/custom_button.dart';
// import 'package:murcin/features/auth/signin_screen.dart';
// import 'package:murcin/features/onboarding/onboarding_controller.dart';

// class LandingPage extends StatefulWidget {
//   const LandingPage({super.key});

//   @override
//   State<LandingPage> createState() => _LandingPageState();
// }

// class _LandingPageState extends State<LandingPage> {
//   late final LandingController controller;
//   bool _fontsLoaded = false;

//   @override
//   void initState() {
//     super.initState();
//     controller = Get.put(LandingController());
//     _loadFonts();
//   }

//   Future<void> _loadFonts() async {
//     try {
//       // Ensure fonts are loaded before building text widgets
//       await Future.wait(
//         [
//               // Load font variants
//               GoogleFonts.roboto(),
//               Future.delayed(const Duration(milliseconds: 200)),
//             ]
//             as Iterable<Future<dynamic>>,
//       );
//     } catch (e) {
//       print("⚠️ Error loading fonts: $e");
//     } finally {
//       if (mounted) {
//         setState(() {
//           _fontsLoaded = true;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_fontsLoaded) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Image.asset(
//             'assets/images/logo_2.png',
//             width: 200.w,
//             height: 200.h,
//             fit: BoxFit.contain,
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Page View for splash and onboarding
//             Expanded(
//               child: PageView(
//                 controller: controller.pageController,
//                 onPageChanged: (index) {
//                   controller.currentPage.value = index;
//                 },
//                 children: [
//                   // Page 1: Splash Screen (only asset)
//                   _buildSplashPage(),

//                   // Page 2: Onboarding Screen
//                   _buildOnboardingPage(context),
//                 ],
//               ),
//             ),

//             // Page Indicator
//             _buildPageIndicator(controller),

//             SizedBox(height: 30.h),
//           ],
//         ),
//       ),
//     );
//   }

//   // Splash Page (only asset, no text) - Auto changes after 2 seconds
//   Widget _buildSplashPage() {
//     // Auto navigate after 2 seconds
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted && controller.currentPage.value == 0) {
//         controller.nextPage();
//       }
//     });

//     return Center(
//       child: Image.asset(
//         'assets/images/logo_2.png',
//         width: 420.w,
//         height: 360.w,
//         fit: BoxFit.contain,
//       ),
//     );
//   }

//   // Onboarding Page with vertical scroll
//   Widget _buildOnboardingPage(BuildContext context) {
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: Padding(
//         padding: EdgeInsets.symmetric(
//           horizontal: 30.w,
//           vertical: 50.h,
//         ), // Increased vertical padding from 30 to 50
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             // Top Asset
//             Image.asset(
//               'assets/images/name_2.png',
//               width: 109.w,
//               height: 30.w,
//               fit: BoxFit.contain,
//             ),

//             SizedBox(height: 40.h), // Increased from 30 to 40
//             // Title - with fallback font
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 30.w),
//               child: Text(
//                 'Smarter Investments through Artificial Intelligence',
//                 style:
//                     GoogleFonts.roboto(
//                       fontSize: 24.sp,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.black,
//                       height: 1.3,
//                     ).copyWith(
//                       // Fallback if GoogleFonts fails
//                       fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
//                     ),
//                 textAlign: TextAlign.center,
//               ),
//             ),

//             SizedBox(height: 40.h), // Increased from 30 to 40
//             // Bottom Asset
//             Image.asset(
//               'assets/images/onboarding_image.png',
//               width: 165.w,
//               height: 165.h,
//               fit: BoxFit.contain,
//             ),

//             // ... rest of the code remains the same until the features section ...
//             SizedBox(height: 50.h), // Increased from 40 to 50
//             // Transparent Card with exported image from Figma
//             Container(
//               height: 84.h,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Colors.transparent,
//                 borderRadius: BorderRadius.circular(
//                   0,
//                 ), // No border radius if you want sharp corners
//               ),
//               child: Image.asset(
//                 'assets/images/onboarding_features.png', // Your exported image from Figma
//                 fit: BoxFit.contain, // Adjust based on your image aspect ratio
//               ),
//             ),

//             SizedBox(height: 60.h), // Increased from 50 to 60

//             // Continue Button
//             CustomButton(
//               borderRadius: 30,
//               text: 'Continue',
//               onPressed: () {
//                 Get.offAll(() => const SignInPage());
//               },
//             ),

//             // Extra space at bottom for better scrolling
//             SizedBox(height: 30.h), // Increased from 20 to 30
//           ],
//         ),
//       ),
//     );
//   }

//   // Updated Page Indicator with proper dot for selected
//   Widget _buildPageIndicator(LandingController controller) {
//     return Obx(
//       () => Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // First indicator - Selected is circle, unselected is line
//           GestureDetector(
//             onTap: () => controller.goToPage(0),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeInOut,
//               width: controller.currentPage.value == 0 ? 12.w : 30.w,
//               height: controller.currentPage.value == 0 ? 12.h : 6.h,
//               decoration: BoxDecoration(
//                 color: controller.currentPage.value == 0
//                     ? AppColors.primary
//                     : AppColors.primaryLight,
//                 borderRadius: BorderRadius.circular(
//                   controller.currentPage.value == 0 ? 6.w : 3.w,
//                 ),
//               ),
//             ),
//           ),

//           SizedBox(width: 8.w),

//           // Second indicator - Selected is circle, unselected is line
//           GestureDetector(
//             onTap: () => controller.goToPage(1),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeInOut,
//               width: controller.currentPage.value == 1 ? 12.w : 30.w,
//               height: controller.currentPage.value == 1 ? 12.h : 6.h,
//               decoration: BoxDecoration(
//                 color: controller.currentPage.value == 1
//                     ? AppColors.primary
//                     : AppColors.primaryLight,
//                 borderRadius: BorderRadius.circular(
//                   controller.currentPage.value == 1 ? 6.w : 3.w,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murcin/const/service/shared_preference_helper.dart';
import 'package:murcin/features/auth/signin_screen.dart';
import 'package:murcin/features/market/navbar/market_navbar_screen.dart';
import 'package:murcin/features/onboarding/onboarding_controller.dart';
import 'package:murcin/features/sports/navbar/sports_navbar_screen.dart';
import 'package:murcin/features/selection/selection_screen.dart';
import 'package:murcin/const/theme/app_theme.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late final LandingController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LandingController());
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    await Future.delayed(const Duration(seconds: 5));

    final token = await SharedPreferencesHelper.getAccessToken();
    print(' 🔑 Retrieved Token:-------------------------- $token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      print("✅ Token Found → Navigate To Home");

      String? lastSection =
          await SharedPreferencesHelper.getLastVisitedSection();

      if (lastSection == 'sports') {
        Get.offAll(() => SportsNavbarScreen());
      } else if (lastSection == 'market') {
        Get.offAll(() => MarketNavbarScreen());
      } else {
        bool? isSportsbook = await SharedPreferencesHelper.getSportsbookMode();

        if (isSportsbook == true) {
          Get.offAll(() => SportsNavbarScreen());
        } else if (isSportsbook == false) {
          Get.offAll(() => MarketNavbarScreen());
        } else {
          Get.offAll(() => const SelectionScreen());
        }
      }
    } else {
      print("❌ No Token → Navigate To Sign In");
      Get.offAll(() => SignInPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 130.h,
              child: Image.asset(
                'assets/images/logo_2.jpg',
                width: 400.w,
                height: 350.h,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 455.h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  'Smarter predictions through\nartificial intelligence',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 20.sp,
                    color: const Color(0xFF254577),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
