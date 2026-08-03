import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murcin/const/service/shared_preference_helper.dart';
import 'package:murcin/const/theme/app_color.dart';
import 'package:murcin/const/theme/app_theme.dart';
import 'package:murcin/features/market/navbar/market_navbar_screen.dart';
import 'package:murcin/features/sports/navbar/sports_navbar_screen.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: 1.sh),
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Column(
              children: [
                SizedBox(height: 40.h),

                /// Logo
                Image.asset(
                  'assets/images/name_2.png',
                  width: 150.w,
                  height: 42.h,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: 50.h),

                /// Title
                Column(
                  children: [
                    Text(
                      'Pickfair AI mitigates',
                      style: AppTextStyles.authSubtitle?.copyWith(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'financial risk',
                      style: AppTextStyles.authSubtitle?.copyWith(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                SizedBox(height: 88.h),

                /// Subtitle
                Text(
                  'Choose a platform',
                  style: AppTextStyles.authSubtitle?.copyWith(
                    color: const Color(0xff848484),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40.h),

                /// Market Button
                GestureDetector(
                  onTap: () async {
                    await SharedPreferencesHelper.saveLastVisitedSection('market');
                    Get.offAll(() => MarketNavbarScreen());
                  },
                  child: Container(
                    width: double.infinity,
                    height: 45.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Center(
                      child: Text(
                        'Prediction Markets vs. AI',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                /// Divider
                Divider(color: Colors.grey[500], thickness: 1.h),

                SizedBox(height: 16.h),

                /// Sportsbook Button
                GestureDetector(
                  onTap: () async {
                    await SharedPreferencesHelper.saveLastVisitedSection('sports');
                    Get.offAll(() => SportsNavbarScreen());
                  },
                  child: Container(
                    width: double.infinity,
                    height: 45.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB54533),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Center(
                      child: Text(
                        'Sportsbooks vs. AI',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}