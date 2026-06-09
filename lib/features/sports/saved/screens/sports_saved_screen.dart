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
import 'package:murchin/features/sports/home/widgets/betmgm_card.dart';
import 'package:shimmer/shimmer.dart';

class SportsSavedScreen extends StatefulWidget {
  const SportsSavedScreen({super.key});

  @override
  State<SportsSavedScreen> createState() => _SportsSavedScreenState();
}

class _SportsSavedScreenState extends State<SportsSavedScreen> {
  final SportsHomeController controller = Get.find<SportsHomeController>();

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
      appBar: CustomAppBar(imageAsset: 'assets/images/name_2.png'),
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
    final Color fanduelBgColor = const Color(0xFF559CEE);
    final Color draftkingsBgColor = const Color(0xFF218B28);
    final Color betmgmBgColor = const Color(0xFFA79D2C);

    return GetX<SportsHomeController>(
      builder: (controller) {
        // Show shimmer while initial loading
        if (controller.isLoading.value) {
          return _buildLoadingShimmer();
        }

        // Check if all saved lists are empty
        if (controller.savedFanduelEvents.isEmpty &&
            controller.savedDraftkingsEvents.isEmpty &&
            controller.savedBetMgmEvents.isEmpty) {
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
            // FanDuel Events
            ...controller.savedFanduelEvents.map((e) {
              // Show shimmer if AI data is not yet loaded (null or 'N/A')
              String? aiPercentage = e['aiPercentage'] as String?;
              bool isLoadingAI = aiPercentage == null || aiPercentage == 'N/A' || aiPercentage.isEmpty;
              
              // Debug: log event data
              print('📄 FD Saved Event: event_id=${e['event_id']}, marketPlace=${e['marketPlace']}');

              return Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: FanduelCard(
                  eventId: e['event_id'] as String?,
                  title: 'NBA Championship Odds 2026',
                  subtitle: e['subtitle'] ?? '',
                  date: formatPrettyDate(e['endDate']),
                  marketPercentage: e['marketPercentage'],
                  aiPercentage: isLoadingAI ? null : aiPercentage,
                  team: e['team'],
                  bgColor: fanduelBgColor,
                  borderColor: fanduelBgColor,
                  platformTagBgColor: AppColors.fanduelColor,
                  platformTagBorderColor: Colors.black,
                  platform: e['marketPlace'] as String? ?? 'FanDuel',
                  isSaved: true,
                  eventRef: e,
                ),
              );
            }),
            // DraftKings Events
            ...controller.savedDraftkingsEvents.map((e) {
              // Show shimmer if AI data is not yet loaded (null or 'N/A')
              String? aiPercentage = e['aiPercentage'] as String?;
              bool isLoadingAI = aiPercentage == null || aiPercentage == 'N/A' || aiPercentage.isEmpty;
              
              // Debug: log event data
              print('📄 DK Saved Event: event_id=${e['event_id']}, marketPlace=${e['marketPlace']}');

              return Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: DraftkingsCard(
                  eventId: e['event_id'] as String?,
                  title: 'NBA Championship Odds 2026',
                  subtitle: e['subtitle'] ?? '',
                  date: formatPrettyDate(e['endDate']),
                  marketPercentage: e['marketPercentage'],
                  aiPercentage: isLoadingAI ? null : aiPercentage,
                  team: e['team'],
                  bgColor: draftkingsBgColor,
                  borderColor: draftkingsBgColor,
                  platformTagBgColor: AppColors.draftkingsColor,
                  platformTagBorderColor: Colors.black,
                  platform: e['marketPlace'] as String? ?? 'DraftKings',
                  isSaved: true,
                  eventRef: e,
                ),
              );
            }),
            // BetMGM Events
            ...controller.savedBetMgmEvents.map((e) {
              // Show shimmer if AI data is not yet loaded (null or 'N/A')
              String? aiPercentage = e['aiPercentage'] as String?;
              bool isLoadingAI = aiPercentage == null || aiPercentage == 'N/A' || aiPercentage.isEmpty;
              
              // Debug: log event data
              print('📄 MGM Saved Event: event_id=${e['event_id']}, marketPlace=${e['marketPlace']}');

              return Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: BetmgmCard(
                  eventId: e['event_id'] as String?,
                  title: 'NBA Championship Odds 2026',
                  subtitle: e['subtitle'] ?? '',
                  date: formatPrettyDate(e['endDate']),
                  marketPercentage: e['marketPercentage'],
                  aiPercentage: isLoadingAI ? null : aiPercentage,
                  team: e['team'],
                  bgColor: betmgmBgColor,
                  borderColor: betmgmBgColor,
                  platformTagBgColor: AppColors.betmgmColor,
                  platformTagBorderColor: Colors.black,
                  platform: e['marketPlace'] as String? ?? 'BetMGM',
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
