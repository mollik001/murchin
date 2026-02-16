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

  final Color unselectedBgColor = const Color(0xFFBDC4D2);
  final Color polymarketBgColor = const Color(0xFF607D3B);
  final Color kalshiBgColor = const Color(0xFF6678F3);

  @override
  void initState() {
    super.initState();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
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

  /// ✅ Pretty Date Format
  String formatPrettyDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(imageAsset: 'assets/images/name.png'),
      body: Column(
        children: [
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildSearchBar(),
          ),
          SizedBox(height: 30.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildSeparatePlatformTabs(),
          ),
          SizedBox(height: 30.h),
          Expanded(
            child: Obx(() {
              // Show cached/local events immediately
              if (controller.events.isEmpty && controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Polymarket tab
              if (controller.selectedPlatform.value == 1) {
                return ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: controller.events.length + 1,
                  itemBuilder: (context, index) {
                    // In ListView.builder for Polymarket tab
                    if (index < controller.events.length) {
                      final e = controller.events[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 20.h),
                        child: PolymarketCard(
                          title: e['title'],
                          subtitle: formatPrettyDate(e['endDate']),
                          date: formatPrettyDate(e['endDate']),
                          marketPercentage: e['marketPercentage'],
                          aiPercentage: e['aiPercentage'],
                          team: e['team'],
                          bgColor: polymarketBgColor,
                          borderColor: AppColors.notBlue,
                          optionTitles: e['optionTitles'] != null ? List<String>.from(e['optionTitles']) : null,
                          marketProbs: e['marketProbs'] != null ? List<double>.from(e['marketProbs']) : null,
                          aiPercentages: e['aiPercentages'] != null ? List<double>.from(e['aiPercentages']) : null,
                          aiExplanation: e['aiExplanation'] as String?,
                        ),
                      );
                    } else {
                      // pagination spinner only
                      return controller.isPageLoading.value
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox();
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

              // All tab (mix of Polymarket + Kalshi)
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [

                  ...controller.events
                      .take(3)
                      .map(
                        (e) => Padding(
                          padding: EdgeInsets.only(bottom: 20.h),
                          child: PolymarketCard(
                            title: e['title'],
                            subtitle: formatPrettyDate(e['endDate']),
                            date: formatPrettyDate(e['endDate']),
                            marketPercentage: e['marketPercentage'],
                            aiPercentage: e['aiPercentage'],
                            team: e['team'],
                            bgColor: polymarketBgColor,
                            borderColor: AppColors.notBlue,
                            
                            optionTitles: e['optionTitles'] != null ? List<String>.from(e['optionTitles']) : null,
                            marketProbs: e['marketProbs'] != null ? List<double>.from(e['marketProbs']) : null,
                            aiPercentages: e['aiPercentages'] != null ? List<double>.from(e['aiPercentages']) : null,
                            aiExplanation: e['aiExplanation'] as String?,
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
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: const Color(0xffE6E6E6)),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 12.w),
            child: Image.asset('assets/icons/search.png', width: 20.w),
          ),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparatePlatformTabs() {
    return Row(
      children: [
        _buildTab(0, "All"),
        SizedBox(width: 10.w),
        _buildTab(1, "Polymarket"),
        SizedBox(width: 10.w),
        _buildTab(2, "Kalshi"),
      ],
    );
  }

  Widget _buildTab(int index, String text) {
    return Expanded(
      child: Obx(() {
        final selected = controller.selectedPlatform.value == index;
        return GestureDetector(
          onTap: () => controller.selectPlatform(index),
          child: Container(
            height: 30.h,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : unselectedBgColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(text, style: const TextStyle(color: Colors.white)),
            ),
          ),
        );
      }),
    );
  }
}
