import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murcin/const/theme/app_color.dart';
import 'package:murcin/const/theme/app_theme.dart';
import 'package:murcin/const/widgets/custom_button.dart';
import 'package:murcin/features/auth/auth_controller.dart';

class SignInPage extends StatelessWidget {
  SignInPage({super.key});

  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Platform.isIOS;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: 1.sh),
            padding: EdgeInsets.only(
              left: 30.w,
              right: 30.w,
              top: 30.h,
              bottom: 40.h,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Logo
                Center(
                  child: Image.asset(
                    'assets/images/name_2.png',
                    width: 180.w,
                    height: 85.h,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: 80.h),

                /// Title
                Text(
                  'Welcome to Pickfair AI',
                  style: AppTextStyles.authSubtitle?.copyWith(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16.h),

                /// Subtitle
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Text(
                    'Sign in to access AI-powered predictions!',
                    style: AppTextStyles.authSubtitle?.copyWith(
                      color: const Color(0xff848484),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 40.h),

                /// Sign-in label
                Text(
                  isIOS ? 'Continue with Apple' : 'Continue with Google',
                  style: AppTextStyles.authSubtitle?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),

                SizedBox(height: 24.h),

                /// Platform-specific sign-in button
                Obx(() {
                  final loading = authController.isLoading.value;

                  if (isIOS) {
                    // Apple Sign-In button (iOS only) — same look as Google button
                    return CustomButton(
                      text: loading ? 'Signing in...' : '',
                      onPressed: loading ? () {} : () async {
                        await authController.signInWithApple();
                      },
                      icon: loading
                          ? null
                          : SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Text(
                                  '', // Apple logo Unicode glyph
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontFamily: '-apple-system',
                                  ),
                                ),
                              ),
                            ),
                      backgroundColor: Colors.black,
                      borderRadius: 30.r,
                    );
                  } else {
                    // Google Sign-In button (Android)
                    return CustomButton(
                      text: loading ? 'Signing in...' : '',
                      onPressed: loading ? () {} : () async {
                        await authController.signInWithGoogle();
                      },
                      icon: loading
                          ? null
                          : Image.asset(
                              'assets/icons/google.png',
                              width: 20.w,
                              height: 20.w,
                            ),
                      borderRadius: 30.r,
                    );
                  }
                }),

                SizedBox(height: 40.h),

                /// Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey[400], thickness: 1.h),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'Secure and private sign-in',
                        style: AppTextStyles.authSubtitle?.copyWith(
                          color: AppColors.gray600,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey[400], thickness: 1.h),
                    ),
                  ],
                ),

                SizedBox(height: 40.h),

                /// Privacy Text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Column(
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyles.bodySmall?.copyWith(
                            color: const Color(0xff848484),
                            fontSize: 13.sp,
                            height: 1.6,
                          ),
                          children: [
                            const TextSpan(text: 'By clicking the '),
                            TextSpan(
                              text: '"sign-up"',
                              style: AppTextStyles.bodySmall?.copyWith(
                                color: const Color(0xff848484),
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                            const TextSpan(
                              text: ' button, you accept the terms\n',
                            ),
                            const TextSpan(text: 'of the '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Privacy Policy',
                                  style: AppTextStyles.bodySmall?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
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
