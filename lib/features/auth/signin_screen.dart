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
              top: 40.h,
              bottom: 70.h, // Bottom padding for privacy policy
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    // Name Asset
                    Center(
                      child: Image.asset(
                        'assets/images/name.png',
                        width: 109.w,
                        height: 30.w,
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Title Text
                    Text(
                      'Welcome to Pickfair',
                      style: AppTextStyles.authSubtitle?.copyWith(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 12.h),

                    // Subtitle Text
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Text(
                        'Sign in to access AI-powered predictions!',
                        style: AppTextStyles.authSubtitle?.copyWith(
                          color: Color(0xff848484),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: 60.h),

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
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'We\'re currently onboarding users via Google sign-in only. '
                            'Email registration will be available in a future update.',
                            style: AppTextStyles.bodySmall?.copyWith(
                              color: Color(0xff848484),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // "Continue with Google" Text
                    Text(
                      'Continue with Google',
                      style: AppTextStyles.authSubtitle?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Google Sign-in Button
                    CustomButton(
                      text: '',
                      onPressed: () {
                        Get.offAll(CustomNavbar());
                      },
                      icon: Image.asset(
                        'assets/icons/google.png',
                        width: 20.w,
                        height: 20.w,
                        fit: BoxFit.contain,
                      ),
                      borderRadius: 30.r,
                    ),

                    SizedBox(height: 40.h),

                    // Divider with Text
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1.h,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'Secure and private sign in',
                            style: AppTextStyles.authSubtitle?.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1.h,
                          ),
                        ),
                      ],
                    ),

                    // Add extra space before privacy policy
                    SizedBox(height: 40.h),
                  ],
                ),

                // Bottom Privacy Policy Text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.bodySmall?.copyWith(
                        color: Color(0xff848484),
                      ),
                      children: [
                        const TextSpan(
                          text: 'By clicking the ',
                        ),
                        TextSpan(
                          text: '"sign up"',
                          style: AppTextStyles.bodySmall?.copyWith(
                            color: Color(0xff848484),
                            fontWeight: FontWeight.w600,
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
                                color: Color(0xff000000),
                                fontWeight: FontWeight.bold,
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
                ),
                SizedBox(height: 70.h,)
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleGoogleSignIn() {
    print('Google Sign-in clicked');
  }
}