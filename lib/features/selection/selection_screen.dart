import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/service/shared_preference_helper.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/features/market/navbar/market_navbar_screen.dart';
import 'package:murchin/features/sports/navbar/sports_navbar_screen.dart';

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
                  'assets/images/name.png',
                  width: 109.w,
                  height: 30.h,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: 30.h),

                /// Title
                Text(
                  'Where do you want to go?',
                  style: AppTextStyles.authSubtitle?.copyWith(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12.h),

                /// Subtitle
                Text(
                  'Choose a prediction to start with PickFair',
                  style: AppTextStyles.authSubtitle?.copyWith(
                    color: const Color(0xff848484),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 100.h),

                /// Sportsbook Logo (Selectable)
                GestureDetector(
                  onTap: () async {
                    await SharedPreferencesHelper.saveLastVisitedSection('sports');
                    Get.offAll(() => SportsNavbarScreen());
                  },
                  child: Image.asset(
                    'assets/images/sports.png',
                    width: 100.w,
                    height: 100.h,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: 16.h),

                /// Divider
                Divider(color: Colors.grey[300], thickness: 1.h),

                SizedBox(height: 16.h),

                /// Market Logo (Selectable)
                GestureDetector(
                  onTap: () async {
                    await SharedPreferencesHelper.saveLastVisitedSection('market');
                    Get.offAll(() => MarketNavbarScreen());
                  },
                  child: Image.asset(
                    'assets/images/market.png',
                    width: 100.w,
                    height: 100.h,
                    fit: BoxFit.contain,
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
