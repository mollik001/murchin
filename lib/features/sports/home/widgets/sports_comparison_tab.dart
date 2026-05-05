import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';

class SportsComparisonTab extends StatelessWidget {
  final String title;
  final String? percentage;
  final String? team;
  final Color percentageColor;

  const SportsComparisonTab({
    super.key,
    required this.title,
    this.percentage,
    this.team,
    required this.percentageColor,
  });

  @override
  Widget build(BuildContext context) {
    final isShimmer = percentage == null || team == null;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          if (isShimmer)
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 60.w,
                height: 28.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            )
          else
            Text(
              percentage!,
              style: AppTextStyles.headlineSmall?.copyWith(
                color: percentageColor,
                fontWeight: FontWeight.w600,
                fontSize: 28.sp,
              ),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 4.h),
          if (isShimmer)
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 80.w,
                height: 14.h,
                margin: EdgeInsets.only(top: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            )
          else
            Text(
              team!,
              style: AppTextStyles.bodyMedium?.copyWith(
                color: AppColors.gray600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
