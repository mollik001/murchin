import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murcin/features/sports/home/controllers/sports_home_controller.dart';
import 'package:murcin/features/sports/home/widgets/sports_comparison_tab.dart';
import 'package:shimmer/shimmer.dart';
import 'package:murcin/const/theme/app_color.dart';
import 'package:murcin/const/theme/app_theme.dart';
import 'package:murcin/const/utils/platform_helper.dart';

class SportsBaseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String? aiPercentage;
  final String team;
  final Color bgColor;
  final Color borderColor;
  final Color? platformTagBgColor;
  final Color? platformTagBorderColor;
  final String platform;
  final String iconAsset;
  final bool initiallySaved;
  final String? eventId;
  final VoidCallback? onSaved;
  final bool showBookmark;

  const SportsBaseCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.marketPercentage,
    required this.aiPercentage,
    required this.team,
    required this.bgColor,
    required this.borderColor,
    this.platformTagBgColor,
    this.platformTagBorderColor,
    required this.platform,
    required this.iconAsset,
    this.initiallySaved = false,
    this.eventId,
    this.onSaved,
    this.showBookmark = true,
  });

  @override
  Widget build(BuildContext context) {
    // Show shimmer when AI value is null (loading), show N/A only when explicitly set
    bool isLoadingValues = aiPercentage == null;

    print('🔵 SportsBaseCard build - eventId: $eventId, platform: $platform');

    return GetBuilder<SportsHomeController>(
      id: 'saved_events', // Use specific ID for better control
      builder: (controller) {
        final isSaved = eventId != null && controller.isEventSaved(eventId!, platform);

        print('🟢 GetBuilder rebuild - eventId: $eventId, isSaved: $isSaved');

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.gray300, width: 1.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(iconAsset, width: 44.w, height: 44.h),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTextStyles.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (subtitle.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(subtitle,
                              style: AppTextStyles.bodyMedium?.copyWith(
                                color: const Color(0xff848484),
                                fontWeight: FontWeight.w400,
                                fontSize: 14.sp,
                              )),
                        ],
                      ],
                    ),
                  ),
                  if (showBookmark && PlatformHelper.isBookmarkEnabled)
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () async {
                        print('🔴 Bookmark tapped - eventId: $eventId, isSaved: $isSaved');

                        // If already saved, do nothing
                        if (isSaved) {
                          print('⚠️ Already saved, ignoring tap');
                          return;
                        }

                        // Check if we have an event ID
                        if (eventId == null) {
                          print('❌ Event ID is null');
                          return;
                        }

                        print('✅ Saving event: $eventId on $platform');

                        final isMlb = iconAsset.toLowerCase().contains('mlb') || 
                                      title.toUpperCase().contains('MLB');

                        // Optimistically mark saved so UI updates immediately
                        controller.markEventSavedLocally(
                          eventId: eventId!,
                          marketPlace: platform,
                          title: title,
                          subtitle: subtitle,
                          endDate: date,
                          marketPercentage: marketPercentage,
                          aiPercentage: aiPercentage,
                          team: team,
                          bookmark: null,
                        );

                        // Save event via API
                        final success = await controller.saveEvent(
                          eventId: eventId!,
                          marketPlace: platform,
                          isMlb: isMlb,
                          title: title,
                          subtitle: subtitle,
                          endDate: date,
                          marketPercentage: marketPercentage,
                          aiPercentage: aiPercentage,
                          team: team,
                        );

                        print('💾 Save result: $success');

                        if (success) {
                          // Refresh saved events list in background (keeps local optimistic entry in sync)
                          controller.fetchSavedEvents();

                          Get.snackbar(
                            'Saved',
                            'Event saved to your list',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.primary.withOpacity(0.9),
                            colorText: Colors.white,
                          );

                          // Update the UI with specific ID
                          print('🔄 Calling controller.update()');
                          controller.update(['saved_events']);
                        } else {
                          Get.snackbar(
                            'Error',
                            'Failed to save event',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.withOpacity(0.9),
                            colorText: Colors.white,
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        child: Image.asset(
                          isSaved
                              ? 'assets/icons/bookmark_active.png'
                              : 'assets/icons/bookmark.png',
                          width: 20.w,
                          height: 20.h,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: platformTagBgColor ?? bgColor,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: platformTagBorderColor ?? borderColor, width: 1.w),
                    ),
                    child: Text(platform,
                        style: AppTextStyles.bodySmall?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall?.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 12.sp,
                            color: const Color(0xff848484))),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: isLoadingValues
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              height: 48.h,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r)),
                            ),
                          )
                        : SportsComparisonTab(
                            title: 'Sportsbook',
                            percentage: marketPercentage,
                            team: team,
                            percentageColor: const Color(0xff4588C6),
                          ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: isLoadingValues
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              height: 48.h,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r)),
                            ),
                          )
                        : SportsComparisonTab(
                            title: 'AI Predicts',
                            percentage: aiPercentage ?? '0%',
                            team: team,
                            percentageColor: const Color(0xffC41E3A),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
