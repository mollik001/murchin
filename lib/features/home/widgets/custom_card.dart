

// Base Card Widget
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/features/home/screens/comparison_card.dart';
import 'package:murchin/features/home/screens/home_screen.dart';

// Base Card Widget - Make it Stateful
class BaseCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String aiPercentage;
  final String team;
  final Color bgColor;
  final Color borderColor;
  final String platform;
  final String iconAsset;
  final bool initiallySaved; // Add this parameter

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
    required this.platform,
    required this.iconAsset,
    this.initiallySaved = false, // Default to not saved
  });

  @override
  State<BaseCard> createState() => _BaseCardState();
}

class _BaseCardState extends State<BaseCard> {
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the passed value
    isSaved = widget.initiallySaved;
  }

  void _toggleSaved() {
    setState(() {
      isSaved = !isSaved;
    });
    
    // Show feedback
    if (isSaved) {
      Get.snackbar(
        'Saved',
        'Event saved to your list',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.gray300,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Icon, Title, Bookmark
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform Icon - 44x44 size
              Image.asset(
                widget.iconAsset,
                width: 44.w,
                height: 44.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 12.w),
              
              // Title (two lines)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: AppTextStyles.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bookmark Icon - Make it tappable
              GestureDetector(
                onTap: _toggleSaved,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  child: Image.asset(
                    isSaved ? 'assets/icons/bookmark_active.png' : 'assets/icons/bookmark.png',
                    width: 20.w,
                    height: 20.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Platform tag and date row - date right after tag with some gap
          Row(
            children: [
              // Platform Tag
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: widget.borderColor,
                    width: 1.w,
                  ),
                ),
                child: Text(
                  widget.platform,
                  style: AppTextStyles.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              SizedBox(width: 12.w), // Gap between tag and date
              
              // Date - not at far end
              Text(
                widget.date,
                style: AppTextStyles.bodySmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 12.sp,
                  color: const Color(0xff848484),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          // Two tabs comparison - Centered content
          Row(
            children: [
              // Left Tab: The Market
              Expanded(
                child: ComparisonTab(
                  title: 'The Market',
                  percentage: widget.marketPercentage,
                  team: widget.team,
                  percentageColor: const Color(0xff4588C6),
                ),
              ),
              
              SizedBox(width: 16.w),
              
              // Right Tab: AI Predicts
              Expanded(
                child: ComparisonTab(
                  title: 'AI Predicts',
                  percentage: widget.aiPercentage,
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
