import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murcin/features/market/home/screens/comparison_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:murcin/const/theme/app_color.dart';
import 'package:murcin/const/theme/app_theme.dart';
import 'package:murcin/const/utils/platform_helper.dart';

class BaseCard extends StatefulWidget {
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
  final VoidCallback? onSaved;
  final bool canToggleSave; // Allow disabling bookmark tap

  const BaseCard({
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
    this.onSaved,
    this.canToggleSave = true, // Default to true for backward compatibility
  });

  @override
  State<BaseCard> createState() => _BaseCardState();
}

class _BaseCardState extends State<BaseCard> {
  late bool isSaved;

  @override
  void initState() {
    super.initState();
    isSaved = widget.initiallySaved;
  }

  void _toggleSaved() {
    // Only toggle if allowed
    if (!widget.canToggleSave) return;
    
    // If already saved, do nothing
    if (isSaved) return;

    setState(() => isSaved = true);

    // Call the callback if provided
    widget.onSaved?.call();

    Get.snackbar(
      'Saved',
      'Event saved to your list',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLoadingValues =
        widget.aiPercentage == null ||
        widget.aiPercentage!.isEmpty ||
        widget.aiPercentage == 'N/A' ||
        widget.aiPercentage == 'NA';

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: AppTextStyles.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (PlatformHelper.isBookmarkEnabled)
                GestureDetector(
                  onTap: widget.canToggleSave ? _toggleSaved : null,
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
                  color: widget.platformTagBgColor ?? widget.bgColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: widget.platformTagBorderColor ?? widget.borderColor, width: 1.w),
                ),
                child: Text(widget.platform,
                    style: AppTextStyles.bodySmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              SizedBox(width: 12.w),
              Text(widget.date,
                  style: AppTextStyles.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 12.sp,
                      color: const Color(0xff848484))),
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
                    : ComparisonTab(
                        title: 'The Market',
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
                    : ComparisonTab(
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
