import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_button.dart';
import 'package:murchin/features/navbar/navbar_screen.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: 1.sh, // Full screen height
            ),
            padding: EdgeInsets.only(
              left: 30.w,
              right: 30.w,
              top: 60.h, // Increased from 40.h to 80.h
              bottom: 40.h, // Reduced bottom padding
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Changed to center
              children: [
                // Name Asset - Moved down
               // SizedBox(height: 20.h), // Added extra space at top
                Center(
                  child: Image.asset(
                    'assets/images/name.png',
                    width: 109.w,
                    height: 30.w,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: 60.h), // Increased from 40.h to 60.h

                // Title Text
                Text(
                  'Welcome to Pickfair',
                  style: AppTextStyles.authSubtitle?.copyWith(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700, // Changed to w700 for boldness
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16.h), // Increased from 12.h to 16.h

                // Subtitle Text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Text(
                    'Sign in to access AI-powered predictions!',
                    style: AppTextStyles.authSubtitle?.copyWith(
                      color: const Color(0xff848484),
                      fontSize: 16.sp, // Added .sp for consistency
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 40.h), 

                // "Registration coming soon" Section
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Registration coming soon',
                        style: AppTextStyles.authSubtitle?.copyWith(
                          fontWeight: FontWeight.w700, // Changed to w700
                          color: Colors.black,
                          fontSize: 16.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12.h), // Increased from 8.h to 12.h
                      Text(
                        'We\'re currently onboarding users via Google sign-in only. '
                        'Email registration will be available in a future update.',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: const Color(0xff848484),
                          fontWeight: FontWeight.w500,
                          fontSize: 13.sp, // Slightly larger
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40.h), // Increased from 40.h to 60.h

                // "Continue with Google" Text
                Text(
                  'Continue with Google',
                  style: AppTextStyles.authSubtitle?.copyWith(
                    fontWeight: FontWeight.w700, // Changed to w700
                    fontSize: 16.sp,
                  ),
                ),

                SizedBox(height: 24.h), // Increased from 20.h to 24.h

                // Google Sign-in Button
                CustomButton(
                  text: '',
                  onPressed: () {
                    Get.offAll(() =>  CustomNavbar());
                  },
                  icon: Image.asset(
                    'assets/icons/google.png',
                    width: 20.w,
                    height: 20.w,
                    fit: BoxFit.contain,
                  ),
                  borderRadius: 30.r,
                ),

                SizedBox(height: 60.h), // Increased from 40.h to 60.h

                // Divider with Text
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey[400], // Softer color
                        thickness: 1.h,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'Secure and private sign in',
                        style: AppTextStyles.authSubtitle?.copyWith(
                          color: AppColors.gray600, // Darker gray
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey[400], // Softer color
                        thickness: 1.h,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 60.h), // Increased from 40.h to 60.h

                // Bottom Privacy Policy Text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Column(
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyles.bodySmall?.copyWith(
                            color: const Color(0xff848484),
                            fontSize: 13.sp, // Slightly larger
                            height: 1.6, // Better line spacing
                          ),
                          children: [
                            const TextSpan(
                              text: 'By clicking the ',
                            ),
                            TextSpan(
                              text: '"sign up"',
                              style: AppTextStyles.bodySmall?.copyWith(
                                color: const Color(0xff848484),
                                fontWeight: FontWeight.w700, // Changed to w700
                                fontSize: 13.sp,
                              ),
                            ),
                            const TextSpan(
                              text: ' button, you accept the terms\n',
                            ),
                            const TextSpan(
                              text: 'of the ',
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  // Get.toNamed('/privacy-policy');
                                },
                                child: Text(
                                  'Privacy Policy',
                                  style: AppTextStyles.bodySmall?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700, // Changed to w700
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(
                              text: '.',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 60.h), // Space below privacy policy
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


//hasanFaysal7890