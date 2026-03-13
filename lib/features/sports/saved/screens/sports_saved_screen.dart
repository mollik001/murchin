// lib/features/sports/saved/screens/sports_saved_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';
import 'package:murchin/features/sports/home/controllers/sports_home_controller.dart';
import 'package:murchin/features/sports/home/widgets/fanduel_card.dart';
import 'package:murchin/features/sports/home/widgets/draftkings_card.dart';
import 'package:shimmer/shimmer.dart';

class SportsSavedScreen extends StatefulWidget {
  const SportsSavedScreen({super.key});

  @override
  State<SportsSavedScreen> createState() => _SportsSavedScreenState();
}

class _SportsSavedScreenState extends State<SportsSavedScreen> {
  final SportsHomeController controller = Get.find<SportsHomeController>();

  @override
  void initState() {
    super.initState();
    controller.fetchSavedEvents();
  }

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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),

              Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved Events',
                  style: AppTextStyles.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              _buildSavedCardsList(),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedCardsList() {
    final Color fanduelBgColor = const Color(0xFF607D3B);
    final Color draftkingsBgColor = const Color(0xFF6678F3);

    return GetX<SportsHomeController>(
      builder: (controller) {
        if (controller.isLoading.value &&
            controller.savedFanduelEvents.isEmpty &&
            controller.savedDraftkingsEvents.isEmpty) {
          return _buildLoadingShimmer();
        }

        if (controller.savedFanduelEvents.isEmpty &&
            controller.savedDraftkingsEvents.isEmpty) {
          return Center(
            child: Column(
              children: [
                SizedBox(height: 50.h),
                Icon(
                  Icons.bookmark_border,
                  size: 64.sp,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No saved events',
                  style: AppTextStyles.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            ...controller.savedFanduelEvents.asMap().entries.map((entry) {
              int index = entry.key;
              final e = entry.value;
              
              // Use the aiPercentage that was calculated by the controller (favorite team's AI value)
              // Show shimmer if AI data is not yet loaded (null or 'N/A')
              String? aiPercentage = e['aiPercentage'] as String?;
              if (aiPercentage == 'N/A' || aiPercentage == null) {
                aiPercentage = null; // Show shimmer
              }
              
              return Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: FanduelCard(
                  eventId: e['event_id']?.toString(),
                  title: 'NBA Championship Odds 2026',
                  subtitle: e['subtitle'] ?? '',
                  date: formatPrettyDate(e['endDate']),
                  marketPercentage: e['marketPercentage'],
                  aiPercentage: aiPercentage,
                  team: e['team'],
                  bgColor: fanduelBgColor,
                  borderColor: AppColors.notBlue,
                  platform: e['marketPlace'] as String? ?? 'FanDuel',
                  isSaved: true,
                  eventRef: e,
                ),
              );
            }),
            ...controller.savedDraftkingsEvents.asMap().entries.map((entry) {
              int index = entry.key;
              final e = entry.value;
              
              // Use the aiPercentage that was calculated by the controller (favorite team's AI value)
              // Show shimmer if AI data is not yet loaded (null or 'N/A')
              String? aiPercentage = e['aiPercentage'] as String?;
              if (aiPercentage == 'N/A' || aiPercentage == null) {
                aiPercentage = null; // Show shimmer
              }
              
              return Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: DraftkingsCard(
                  eventId: e['event_id']?.toString(),
                  title: 'NBA Championship Odds 2026',
                  subtitle: e['subtitle'] ?? '',
                  date: formatPrettyDate(e['endDate']),
                  marketPercentage: e['marketPercentage'],
                  aiPercentage: aiPercentage,
                  team: e['team'],
                  bgColor: draftkingsBgColor,
                  borderColor: AppColors.blue,
                  platform: e['marketPlace'] as String? ?? 'DraftKings',
                  isSaved: true,
                  eventRef: e,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 20.h),
          child: Container(
            height: 180.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
