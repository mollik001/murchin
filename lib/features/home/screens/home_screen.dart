// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';
import 'package:murchin/features/home/controllers/home_controller.dart';
import 'package:murchin/features/home/widgets/kalshi_card.dart';
import 'package:murchin/features/home/widgets/polymarket_card.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  // Controller for the platform tabs
  final HomeController controller = Get.put(HomeController());

  // Color constants
  final Color unselectedBgColor = const Color(0xFFBDC4D2);
  final Color polymarketBgColor = const Color(0xFF607D3B);
  final Color kalshiBgColor = const Color(0xFF6678F3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(imageAsset: 'assets/images/name.png'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              
              // Search Bar
              _buildSearchBar(),
              
              SizedBox(height: 30.h),
              
              // Platform Tabs
              _buildSeparatePlatformTabs(),
              
              SizedBox(height: 30.h),
              
              // Cards based on selected platform
              Obx(() {
                switch (controller.selectedPlatform.value) {
                  case 0: // All Platforms
                    return Column(
                      children: [
                        PolymarketCard(
                          title: 'Super Bowl Champion',
                          subtitle: '2026',
                          date: 'Feb 8, 2026',
                          marketPercentage: '27%',
                          aiPercentage: '68%', // AI higher than market
                          team: 'Chiefs',
                          bgColor: polymarketBgColor,
                          borderColor: AppColors.notBlue,
                        ),
                        SizedBox(height: 20.h),
                        KalshiCard(
                          title: 'Bitcoin Price',
                          subtitle: 'End of 2025',
                          date: 'Mar 15, 2025',
                          marketPercentage: '45%',
                          aiPercentage: '72%', // AI higher than market
                          team: 'Over 100K',
                          bgColor: kalshiBgColor,
                          borderColor: AppColors.blue,
                        ),
                        SizedBox(height: 20.h),
                        PolymarketCard(
                          title: 'Next US President',
                          subtitle: '2024 Election',
                          date: 'Nov 5, 2024',
                          marketPercentage: '48%',
                          aiPercentage: '65%', // AI higher than market
                          team: 'Democratic',
                          bgColor: polymarketBgColor,
                           borderColor: AppColors.notBlue,
                        ),
                        SizedBox(height: 20.h),
                        KalshiCard(
                          title: 'Fed Rate Decision',
                          subtitle: 'March 2024 Meeting',
                          date: 'Mar 20, 2024',
                          marketPercentage: '60%',
                          aiPercentage: '82%', // AI higher than market
                          team: 'Rate Hold',
                          bgColor: kalshiBgColor,
                          borderColor: AppColors.blue,
                        ),
                        SizedBox(height: 20.h),
                        PolymarketCard(
                          title: 'Tesla Stock',
                          subtitle: 'Q1 2025 Target',
                          date: 'Jan 10, 2025',
                          marketPercentage: '35%',
                          aiPercentage: '58%', // AI higher than market
                          team: 'Over 300',
                          bgColor: polymarketBgColor,
                           borderColor: AppColors.notBlue,
                        ),
                        SizedBox(height: 20.h),
                        KalshiCard(
                          title: 'NBA Championship',
                          subtitle: '2023-24 Season',
                          date: 'Jun 15, 2024',
                          marketPercentage: '28%',
                          aiPercentage: '51%', // AI higher than market
                          team: 'Celtics',
                          bgColor: kalshiBgColor,
                          borderColor: AppColors.blue,
                          
                        ),
                      ],
                    );
                  case 1: // Polymarket
                    return Column(
                      children: [
                        PolymarketCard(
                          title: 'Super Bowl Champion',
                          subtitle: '2026',
                          date: 'Feb 8, 2026',
                          marketPercentage: '27%',
                          aiPercentage: '68%', // AI higher than market
                          team: 'Chiefs',
                          bgColor: polymarketBgColor,
                           borderColor: AppColors.notBlue,
                        ),
                        SizedBox(height: 20.h),
                        PolymarketCard(
                          title: 'Next US President',
                          subtitle: '2024 Election',
                          date: 'Nov 5, 2024',
                          marketPercentage: '48%',
                          aiPercentage: '65%', // AI higher than market
                          team: 'Democratic',
                          bgColor: polymarketBgColor,
                           borderColor: AppColors.notBlue,
                        ),
                        SizedBox(height: 20.h),
                        PolymarketCard(
                          title: 'Tesla Stock',
                          subtitle: 'Q1 2025 Target',
                          date: 'Jan 10, 2025',
                          marketPercentage: '35%',
                          aiPercentage: '58%', // AI higher than market
                          team: 'Over 300',
                          bgColor: polymarketBgColor,
                           borderColor: AppColors.notBlue,
                        ),
                        SizedBox(height: 20.h),
                        PolymarketCard(
                          title: 'Apple Market Cap',
                          subtitle: 'End of Q2 2024',
                          date: 'Jun 30, 2024',
                          marketPercentage: '42%',
                          aiPercentage: '67%', // AI higher than market
                          team: 'Over 3T',
                          bgColor: polymarketBgColor,
                           borderColor: AppColors.notBlue,
                        ),
                        SizedBox(height: 20.h),
                        PolymarketCard(
                          title: 'COVID Variant',
                          subtitle: 'Winter 2024 Wave',
                          date: 'Dec 15, 2024',
                          marketPercentage: '31%',
                          aiPercentage: '54%', // AI higher than market
                          team: 'Significant',
                          bgColor: polymarketBgColor,
                           borderColor: AppColors.notBlue,
                        ),
                      ],
                    );
                  case 2: // Kalshi
                    return Column(
                      children: [
                        KalshiCard(
                          title: 'Bitcoin Price',
                          subtitle: 'End of 2025',
                          date: 'Mar 15, 2025',
                          marketPercentage: '45%',
                          aiPercentage: '72%', // AI higher than market
                          team: 'Over 100K',
                          bgColor: kalshiBgColor,
                          borderColor: AppColors.blue,
                        ),
                        SizedBox(height: 20.h),
                        KalshiCard(
                          title: 'Fed Rate Decision',
                          subtitle: 'March 2024 Meeting',
                          date: 'Mar 20, 2024',
                          marketPercentage: '60%',
                          aiPercentage: '82%', // AI higher than market
                          team: 'Rate Hold',
                          bgColor: kalshiBgColor,
                          borderColor: AppColors.blue,
                        ),
                        SizedBox(height: 20.h),
                        KalshiCard(
                          title: 'NBA Championship',
                          subtitle: '2023-24 Season',
                          date: 'Jun 15, 2024',
                          marketPercentage: '28%',
                          aiPercentage: '51%', // AI higher than market
                          team: 'Celtics',
                          bgColor: kalshiBgColor,
                          borderColor: AppColors.blue,
                        ),
                        SizedBox(height: 20.h),
                        KalshiCard(
                          title: 'Oil Price',
                          subtitle: 'December 2024',
                          date: 'Dec 31, 2024',
                          marketPercentage: '38%',
                          aiPercentage: '62%', // AI higher than market
                          team: 'Over 90\$',
                          bgColor: kalshiBgColor,
                          borderColor: AppColors.blue,
                        ),
                        SizedBox(height: 20.h),
                        KalshiCard(
                          title: 'US GDP Growth',
                          subtitle: 'Q3 2024',
                          date: 'Sep 30, 2024',
                          marketPercentage: '52%',
                          aiPercentage: '74%', // AI higher than market
                          team: 'Over 2.5%',
                          bgColor: kalshiBgColor,
                          borderColor: AppColors.blue,
                        ),
                      ],
                    );
                  default:
                    return const SizedBox.shrink();
                }
              }),
              
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  // Search Bar
Widget _buildSearchBar() {
  return Container(
    width: double.infinity,
    height: 42.h,
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25.r),
      border: Border.all(
        color: const Color(0xffE6E6E6),
        width: 1.w,
      ),
    ),
    child: Row(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.w, right: 12.w),
          child: Image.asset(
            'assets/icons/search.png',
            width: 20.w,
            height: 20.h,
            fit: BoxFit.contain,
          ),
        ),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: AppTextStyles.bodyMedium?.copyWith(
                color: const Color(0xff999999),
                fontWeight: FontWeight.w400,
                fontSize: 14.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12.h), // Fix vertical centering
              isDense: true, // This helps with vertical alignment
            ),
            style: AppTextStyles.bodyMedium?.copyWith(
              color: AppColors.gray800,
              height: 1.0, // Set height to 1.0 to prevent extra vertical space
            ),
          ),
        ),
      ],
    ),
  );
}

  // Platform Tabs
  Widget _buildSeparatePlatformTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSeparateTab(0, 'All Platforms'),
        SizedBox(width: 12.w),
        _buildSeparateTab(1, 'Polymarket'),
        SizedBox(width: 12.w),
        _buildSeparateTab(2, 'Kalshi'),
      ],
    );
  }

  Widget _buildSeparateTab(int index, String text) {
    return Obx(() {
      final isSelected = controller.selectedPlatform.value == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => controller.selectPlatform(index),
          child: Container(
            height: 29.h,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : unselectedBgColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}




