
// Comparison Tab Widget - Centered content
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:murcin/const/theme/app_color.dart';
import 'package:murcin/const/theme/app_theme.dart';

class ComparisonTab extends StatelessWidget {
  final String title;
  final String percentage;
  final String team;
  final Color percentageColor;

  const ComparisonTab({
    super.key,
    required this.title,
    required this.percentage,
    required this.team,
    required this.percentageColor,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            percentage,
            style: AppTextStyles.headlineSmall?.copyWith(
              color: percentageColor,
              fontWeight: FontWeight.w600,
              fontSize: 28.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            team,
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

