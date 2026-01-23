// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';

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
      height: 50.h,
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
                  color: AppColors.gray500,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.bodyMedium?.copyWith(
                color: AppColors.gray800,
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
            height: 45.h,
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

// ========== CARD CLASSES ==========

// Base Card Widget
class BaseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String aiPercentage;
  final String team;
  final Color bgColor;
  final String platform;
  final String iconAsset;

  const BaseCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.marketPercentage,
    required this.aiPercentage,
    required this.team,
    required this.bgColor,
    required this.platform,
    required this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.gray300,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Icon, Title, Bookmark
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform Icon - 44x44 size
              Image.asset(
                iconAsset,
                width: 44.w,
                height: 44.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 12.w),
              
              // Title (two lines)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodySmall?.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall?.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bookmark Icon
              Image.asset(
                'assets/icons/bookmark.png',
                width: 20.w,
                height: 20.h,
                fit: BoxFit.contain,
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Platform tag and date row - date right after tag with some gap
          Row(
            children: [
              // Platform Tag
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: bgColor.withOpacity(0.5),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  platform,
                  style: AppTextStyles.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              SizedBox(width: 12.w), // Gap between tag and date
              
              // Date - not at far end
              Text(
                date,
                style: AppTextStyles.bodySmall?.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          // Two tabs comparison - Centered content
          Row(
            children: [
              // Left Tab: The Market
              Expanded(
                child: ComparisonTab(
                  title: 'The Market',
                  percentage: marketPercentage,
                  team: team,
                  percentageColor: AppColors.primary,
                ),
              ),
              
              SizedBox(width: 16.w),
              
              // Right Tab: AI Predicts
              Expanded(
                child: ComparisonTab(
                  title: 'AI Predicts',
                  percentage: aiPercentage,
                  team: team,
                  percentageColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Polymarket Card
class PolymarketCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String aiPercentage;
  final String team;
  final Color bgColor;

  const PolymarketCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.marketPercentage,
    required this.aiPercentage,
    required this.team,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      title: title,
      subtitle: subtitle,
      date: date,
      marketPercentage: marketPercentage,
      aiPercentage: aiPercentage,
      team: team,
      bgColor: bgColor,
      platform: 'Polymarket',
      iconAsset: 'assets/icons/polymarket.png',
    );
  }
}

// Kalshi Card
class KalshiCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String aiPercentage;
  final String team;
  final Color bgColor;

  const KalshiCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.marketPercentage,
    required this.aiPercentage,
    required this.team,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      title: title,
      subtitle: subtitle,
      date: date,
      marketPercentage: marketPercentage,
      aiPercentage: aiPercentage,
      team: team,
      bgColor: bgColor,
      platform: 'Kalshi',
      iconAsset: 'assets/icons/kalshi.png',
    );
  }
}

// Comparison Tab Widget - Centered content
class ComparisonTab extends StatelessWidget {
  final String title;
  final String percentage;
  final String team;
  final Color percentageColor;

  const ComparisonTab({
    super.key,
    required this.title,
    required this.percentage,
    required this.team,
    required this.percentageColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall?.copyWith(
              color: AppColors.gray700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            percentage,
            style: AppTextStyles.headlineSmall?.copyWith(
              color: percentageColor,
              fontWeight: FontWeight.w700,
              fontSize: 22.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            team,
            style: AppTextStyles.bodySmall?.copyWith(
              color: AppColors.gray600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Home Controller
class HomeController extends GetxController {
  final selectedPlatform = 0.obs; // 0: All Platforms, 1: Polymarket, 2: Kalshi
  
  void selectPlatform(int index) {
    selectedPlatform.value = index;
  }
}