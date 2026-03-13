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
import 'package:shimmer/shimmer.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final HomeController controller = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    // Only fetch if not already loaded
    if (controller.savedPolymarketEvents.isEmpty && 
        controller.savedKalshiEvents.isEmpty) {
      controller.fetchSavedEvents();
    }
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
      body: RefreshIndicator(
        onRefresh: _refreshSavedEvents,
        child: SingleChildScrollView(
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
      ),
    );
  }

  Future<void> _refreshSavedEvents() async {
    await controller.fetchSavedEvents();
  }

  Widget _buildSavedCardsList() {
    return GetX<HomeController>(
      builder: (controller) {
        // Show shimmer while initial loading
        if (controller.isLoadingSaved.value) {
          return _buildLoadingShimmer();
        }

        if (controller.savedPolymarketEvents.isEmpty &&
            controller.savedKalshiEvents.isEmpty) {
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
            ...controller.savedPolymarketEvents.asMap().entries.map((entry) {
              int index = entry.key;
              final e = entry.value;
              return GetX<HomeController>(
                builder: (ctrl) {
                  // Get fresh data from controller's list
                  final freshEvent = ctrl.savedPolymarketEvents[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: PolymarketCard(
                      eventId: freshEvent['event_id'],
                      title: freshEvent['title'],
                      subtitle: formatPrettyDate(freshEvent['endDate']),
                      date: formatPrettyDate(freshEvent['endDate']),
                      marketPercentage: freshEvent['marketPercentage'],
                      aiPercentage: freshEvent['aiPercentage'],
                      team: freshEvent['team'],
                      bgColor: const Color(0xFF607D3B),
                      borderColor: AppColors.notBlue,
                      slug: freshEvent['slug'] as String?,
                      isSaved: true,
                      eventRef: freshEvent,
                      onSaved: () {
                        // Show dialog - unsave not available
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove from Saved?'),
                            content: const Text(
                              'Unsave functionality will be available soon.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      optionTitles: freshEvent['optionTitles'] != null
                          ? List<String>.from(freshEvent['optionTitles'])
                          : null,
                      marketProbs: freshEvent['marketProbs'] != null
                          ? List<double>.from(freshEvent['marketProbs'])
                          : null,
                      aiPercentages: freshEvent['aiPercentages'] != null
                          ? List<double>.from(freshEvent['aiPercentages'])
                          : null,
                      aiExplanation: freshEvent['aiExplanation'] as String?,
                    ),
                  );
                },
              );
            }).toList(),

            // Kalshi Events
            ...controller.savedKalshiEvents.asMap().entries.map((entry) {
              int index = entry.key;
              final e = entry.value;
              return GetX<HomeController>(
                builder: (ctrl) {
                  // Get fresh data from controller's list
                  final freshEvent = ctrl.savedKalshiEvents[index];
                  final seriesTicker = freshEvent['series_ticker'] as String?;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: KalshiCard(
                      eventId: freshEvent['event_id'] as String?,
                      title: freshEvent['title'],
                      subtitle: formatPrettyDate(freshEvent['endDate']),
                      date: formatPrettyDate(freshEvent['endDate']),
                      marketPercentage: freshEvent['marketPercentage'],
                      aiPercentage: freshEvent['aiPercentage'],
                      team: freshEvent['team'],
                      bgColor: const Color(0xFF6678F3),
                      borderColor: AppColors.blue,
                      seriesTicker: seriesTicker,
                      eventRef: freshEvent,
                      isSaved: true,
                    ),
                  );
                },
              );
            }).toList(),
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
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 150.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
