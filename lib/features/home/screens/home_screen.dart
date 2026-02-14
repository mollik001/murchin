// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';
import 'package:murchin/features/home/controllers/home_controller.dart';
import 'package:murchin/features/home/widgets/polymarket_card.dart';
import 'package:murchin/features/home/widgets/kalshi_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.put(HomeController());
  final ScrollController scrollController = ScrollController();

  // Color constants
  final Color unselectedBgColor = const Color(0xFFBDC4D2);
  final Color polymarketBgColor = const Color(0xFF607D3B);
  final Color kalshiBgColor = const Color(0xFF6678F3);

  @override
  void initState() {
    super.initState();

    // Listen for scroll to bottom
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 100 &&
          controller.nextPageUrl != null &&
          !controller.isLoading.value) {
        controller.loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(imageAsset: 'assets/images/name.png'),
      body: Column(
        children: [
          SizedBox(height: 20.h),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildSearchBar(),
          ),

          SizedBox(height: 30.h),

          // Platform Tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildSeparatePlatformTabs(),
          ),

          SizedBox(height: 30.h),

          // Expanded list for events
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.events.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Polymarket tab
              if (controller.selectedPlatform.value == 1) {
                if (controller.events.isEmpty) {
                  return const Center(child: Text("No events found"));
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: controller.events.length + 1, // +1 for loader
                  itemBuilder: (context, index) {
                    if (index < controller.events.length) {
                      final e = controller.events[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 20.h),
                        child: PolymarketCard(
                          title: e['title'] ?? '',
                          subtitle: e['endDate']?.split('T').first ?? '',
                          date: e['endDate'] ?? '',
                          marketPercentage: e['marketPercentage'] ?? '0',
                          aiPercentage: e['aiPercentage'] ?? '0%',
                          team: e['team'] ?? '',
                          bgColor: polymarketBgColor,
                          borderColor: AppColors.notBlue,
                        ),
                      );
                    } else {
                      // Bottom loader when fetching next page
                      return controller.isLoading.value
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink();
                    }
                  },
                );
              }

              // Kalshi tab (static)
              if (controller.selectedPlatform.value == 2) {
                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  children: [
                    KalshiCard(
                      title: 'Bitcoin Price',
                      subtitle: 'End of 2025',
                      date: 'Mar 15, 2025',
                      marketPercentage: '45',
                      aiPercentage: '72%',
                      team: 'Over 100K',
                      bgColor: kalshiBgColor,
                      borderColor: AppColors.blue,
                    ),
                    SizedBox(height: 20.h),
                    KalshiCard(
                      title: 'Fed Rate Decision',
                      subtitle: 'March 2024 Meeting',
                      date: 'Mar 20, 2024',
                      marketPercentage: '60',
                      aiPercentage: '82%',
                      team: 'Rate Hold',
                      bgColor: kalshiBgColor,
                      borderColor: AppColors.blue,
                    ),
                  ],
                );
              }

              // All platforms tab (first 3 Polymarket + static Kalshi)
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  ...controller.events.take(3).map(
                    (e) => Padding(
                      padding: EdgeInsets.only(bottom: 20.h),
                      child: PolymarketCard(
                        title: e['title'] ?? '',
                        subtitle: e['endDate']?.split('T').first ?? '',
                        date: e['endDate'] ?? '',
                        marketPercentage: e['marketPercentage'] ?? '0',
                        aiPercentage: e['aiPercentage'] ?? '0%',
                        team: e['team'] ?? '',
                        bgColor: polymarketBgColor,
                        borderColor: AppColors.notBlue,
                      ),
                    ),
                  ),
                  KalshiCard(
                    title: 'Bitcoin Price',
                    subtitle: 'End of 2025',
                    date: 'Mar 15, 2025',
                    marketPercentage: '45',
                    aiPercentage: '72%',
                    team: 'Over 100K',
                    bgColor: kalshiBgColor,
                    borderColor: AppColors.blue,
                  ),
                  SizedBox(height: 20.h),
                  KalshiCard(
                    title: 'Fed Rate Decision',
                    subtitle: 'March 2024 Meeting',
                    date: 'Mar 20, 2024',
                    marketPercentage: '60',
                    aiPercentage: '82%',
                    team: 'Rate Hold',
                    bgColor: kalshiBgColor,
                    borderColor: AppColors.blue,
                  ),
                  SizedBox(height: 40.h),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // Helper to format date
  String _formatDate(String dateStr) {
    final parts = dateStr.split('T');
    return parts.isNotEmpty ? parts[0] : dateStr;
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      height: 42.h,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: const Color(0xffE6E6E6), width: 1.w),
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
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                isDense: true,
              ),
              style: AppTextStyles.bodyMedium?.copyWith(
                color: AppColors.gray800,
                height: 1.0,
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
