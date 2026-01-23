import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/route_manager.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_button.dart';
import 'package:murchin/features/auth/signin_screen.dart';
import 'package:murchin/features/onboarding/onboarding_controller.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final LandingController controller = Get.put(LandingController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Page View for splash and onboarding
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: (index) {
                  controller.currentPage.value = index;
                },
                children: [
                  // Page 1: Splash Screen (only asset)
                  _buildSplashPage(),

                  // Page 2: Onboarding Screen
                  _buildOnboardingPage(),
                ],
              ),
            ),

            // Page Indicator
            _buildPageIndicator(controller),

            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  // Splash Page (only asset, no text) - Auto changes after 3 seconds
  Widget _buildSplashPage() {
    final LandingController controller = Get.find();

    // Auto navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      controller.nextPage();
    });

    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        width: 420.w,
        height: 360.w,
        fit: BoxFit.contain,
      ),
    );
  }

  // Onboarding Page with vertical scroll
  Widget _buildOnboardingPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Top Asset
            Image.asset(
              'assets/images/name.png',
              width: 109.w,
              height: 30.w,
              fit: BoxFit.contain,
            ),

            SizedBox(height: 30.h),

            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Text(
                'Smarter Investments through Artificial Intelligence',
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 30.h),

            // Bottom Asset
            Image.asset(
              'assets/images/onboarding_image.png',
              width: 165.w,
              height: 165.h,
              fit: BoxFit.contain,
            ),

            SizedBox(height: 40.h),

            // Features with icon assets (without container)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Image.asset(
                          'assets/icons/tick.png',
                          width: 24.w,
                          height: 24.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 15.w),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 250.w),
                        child: Text(
                          'Kalshi, Polymarket Odds vs. AI Odds',
                          style: AppTextStyles.headlineSmall,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15.h),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Image.asset(
                          'assets/icons/tick.png',
                          width: 24.w,
                          height: 24.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 15.w),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 250.w),
                        child: Text(
                          'Sportsbook Odds vs. AI Odds: Parlays, Props, Micro-Bets',
                          style: AppTextStyles.headlineSmall,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 50.h),

            // Continue Button
            CustomButton(
              borderRadius: 30,
              text: 'Continue',
              onPressed: () {
               Get.offAll(SignInPage());
              },
            ),

            // Extra space at bottom for better scrolling
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // Updated Page Indicator with proper dot for selected
  Widget _buildPageIndicator(LandingController controller) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First indicator - Selected is circle, unselected is line
          GestureDetector(
            onTap: () => controller.goToPage(0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: controller.currentPage.value == 0 ? 12.w : 30.w,
              height: controller.currentPage.value == 0 ? 12.h : 6.h,
              decoration: BoxDecoration(
                color: controller.currentPage.value == 0
                    ? AppColors.primaryLight
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(
                  controller.currentPage.value == 0 ? 6.w : 3.w,
                ),
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // Second indicator - Selected is circle, unselected is line
          GestureDetector(
            onTap: () => controller.goToPage(1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: controller.currentPage.value == 1 ? 12.w : 30.w,
              height: controller.currentPage.value == 1 ? 12.h : 6.h,
              decoration: BoxDecoration(
                color: controller.currentPage.value == 1
                    ? AppColors.primaryLight
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(
                  controller.currentPage.value == 1 ? 6.w : 3.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
