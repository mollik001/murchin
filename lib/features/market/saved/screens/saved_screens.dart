// lib/features/market/saved/screens/saved_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';
import 'package:murchin/features/market/home/controllers/home_controller.dart';
import 'package:murchin/features/market/home/screens/card_details_screen.dart';
import 'package:murchin/features/market/home/widgets/polymarket_card.dart';
import 'package:murchin/features/market/home/widgets/kalshi_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final HomeController controller = Get.find<HomeController>();

  String formatPrettyDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return 'Date not available';
    }
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
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),

              // Title
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

              // Saved Cards List
              _buildSavedCardsList(),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedCardsList() {
    return Obx(() {
      final polyEvents = controller.savedPolymarketEvents;
      final kalshiEvents = controller.savedKalshiEvents;
      final isLoading = controller.isLoadingSaved.value;

      // Show loading indicator while fetching
      if (isLoading && polyEvents.isEmpty && kalshiEvents.isEmpty) {
        return Center(
          child: Column(
            children: [
              SizedBox(height: 50.h),
              CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text(
                'Loading saved events...',
                style: AppTextStyles.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      // Show empty state if no events
      if (polyEvents.isEmpty && kalshiEvents.isEmpty) {
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
          // Polymarket Events
          ...polyEvents.asMap().entries.map((entry) {
            int index = entry.key;
            final e = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 20.h),
              child: PolymarketCard(
                eventId: e['event_id'],
                title: e['title'],
                subtitle: formatPrettyDate(e['endDate']),
                date: formatPrettyDate(e['endDate']),
                marketPercentage: e['marketPercentage'],
                aiPercentage: e['aiPercentage'],
                team: e['team'],
                bgColor: AppColors.polymarketColor,
                borderColor: AppColors.polymarketColor,
                platformTagBgColor: AppColors.polymarketColor,
                platformTagBorderColor: Colors.grey,
                slug: e['slug'] as String?,
                isSaved: true,
                canToggleSave: false, // Disable bookmark tap in saved page
                eventRef: e,
                optionTitles: e['optionTitles'] != null
                    ? List<String>.from(e['optionTitles'])
                    : null,
                marketProbs: e['marketProbs'] != null
                    ? List<double>.from(e['marketProbs'])
                    : null,
                aiPercentages: e['aiPercentages'] != null
                    ? List<double>.from(e['aiPercentages'])
                    : null,
                aiExplanation: e['aiExplanation'] as String?,
              ),
            );
          }).toList(),

          // Kalshi Events
          ...kalshiEvents.asMap().entries.map((entry) {
            int index = entry.key;
            final e = entry.value;
            final seriesTicker = e['series_ticker'] as String?;
            return Padding(
              padding: EdgeInsets.only(bottom: 20.h),
              child: KalshiCard(
                eventId: e['event_id'] as String?,
                title: e['title'],
                subtitle: formatPrettyDate(e['endDate']),
                date: formatPrettyDate(e['endDate']),
                marketPercentage: e['marketPercentage'],
                aiPercentage: e['aiPercentage'],
                team: e['team'],
                bgColor: AppColors.kalshiCardBg,
                borderColor: AppColors.kalshiCardBg,
                platformTagBgColor: AppColors.kalshiColor,
                platformTagBorderColor: Colors.black,
                seriesTicker: seriesTicker,
                eventRef: e,
                isSaved: true,
                canToggleSave: false, // Disable bookmark tap in saved page
              ),
            );
          }).toList(),
        ],
      );
    });
  }
}
