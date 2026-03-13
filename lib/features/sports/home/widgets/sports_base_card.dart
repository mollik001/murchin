import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/features/sports/home/controllers/sports_home_controller.dart';
import 'package:murchin/features/sports/home/widgets/sports_comparison_tab.dart';
import 'package:shimmer/shimmer.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';

class SportsBaseCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String? aiPercentage;
  final String team;
  final Color bgColor;
  final Color borderColor;
  final String platform;
  final String iconAsset;
  final bool initiallySaved;
  final String? eventId;
  final VoidCallback? onSaved;

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
    required this.platform,
    required this.iconAsset,
    this.initiallySaved = false,
    this.eventId,
    this.onSaved,
  });

  @override
  State<SportsBaseCard> createState() => _SportsBaseCardState();
}

class _SportsBaseCardState extends State<SportsBaseCard> {
  late bool isSaved;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    isSaved = widget.initiallySaved;
  }

  Future<void> _toggleSaved() async {
    if (_isSaving) return;
    
    // Check if we have an event ID
    if (widget.eventId == null) {
      // Get.snackbar(
      //   'Error',
      //   'Event ID not available',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.red.withOpacity(0.9),
      //   colorText: Colors.white,
      // );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final controller = Get.find<SportsHomeController>();

    // Save event via API
    final success = await controller.saveEvent(
      eventId: widget.eventId!,
      marketPlace: widget.platform,
    );

    if (success && mounted) {
      setState(() {
        isSaved = !isSaved;
      });

      // Refresh saved events list
      await controller.fetchSavedEvents();

      Get.snackbar(
        isSaved ? 'Saved' : 'Removed',
        isSaved ? 'Event saved to your list' : 'Event removed from saved list',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: isSaved ? AppColors.primary.withOpacity(0.9) : Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    } else if (mounted) {
      Get.snackbar(
        'Error',
        'Failed to save event',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show shimmer when AI value is null (loading), show N/A only when explicitly set
    bool isLoadingValues = widget.aiPercentage == null;

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
              Image.asset(widget.iconAsset, width: 44.w, height: 44.h),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: AppTextStyles.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (widget.subtitle.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(widget.subtitle,
                          style: AppTextStyles.bodyMedium?.copyWith(
                            color: const Color(0xff848484),
                            fontWeight: FontWeight.w400,
                            fontSize: 14.sp,
                          )),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: _toggleSaved,
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
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: widget.borderColor, width: 1.w),
                ),
                child: Text(widget.platform,
                    style: AppTextStyles.bodySmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(widget.date,
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
                        percentage: widget.marketPercentage,
                        team: widget.team,
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
                        percentage: widget.aiPercentage ?? '0%',
                        team: widget.team,
                        percentageColor: const Color(0xffC41E3A),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
