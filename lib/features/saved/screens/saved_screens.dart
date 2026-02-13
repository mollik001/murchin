// lib/features/saved/screens/saved_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';
import 'package:murchin/features/home/screens/card_details_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

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

  // Saved Cards List
  Widget _buildSavedCardsList() {
    // Sample data for saved cards
    final List<Map<String, dynamic>> savedCards = [
      {
        'title': 'Super Bowl Champion',
        'subtitle': '2026',
        'date': 'Feb 8, 2026',
        'marketPercentage': '27%',
        'aiPercentage': '68%',
        'team': 'Chiefs',
        'platform': 'Polymarket',
        'iconAsset': 'assets/icons/polymarket.png',
        'bgColor': const Color(0xFF607D3B),
        'borderColor': AppColors.primary,
        'isPolymarket': true,
      },
      {
        'title': 'Bitcoin Price',
        'subtitle': 'End of 2025',
        'date': 'Mar 15, 2025',
        'marketPercentage': '45%',
        'aiPercentage': '72%',
        'team': 'Over 100K',
        'platform': 'Kalshi',
        'iconAsset': 'assets/icons/kalshi.png',
        'bgColor': const Color(0xFF6678F3),
        'borderColor': const Color(0xFF007AFF),
        'isPolymarket': false,
      },
      {
        'title': 'Next US President',
        'subtitle': '2024 Election',
        'date': 'Nov 5, 2024',
        'marketPercentage': '48%',
        'aiPercentage': '65%',
        'team': 'Democratic',
        'platform': 'Polymarket',
        'iconAsset': 'assets/icons/polymarket.png',
        'bgColor': const Color(0xFF607D3B),
        'borderColor': AppColors.primary,
        'isPolymarket': true,
      },
      {
        'title': 'Fed Rate Decision',
        'subtitle': 'March 2024 Meeting',
        'date': 'Mar 20, 2024',
        'marketPercentage': '60%',
        'aiPercentage': '82%',
        'team': 'Rate Hold',
        'platform': 'Kalshi',
        'iconAsset': 'assets/icons/kalshi.png',
        'bgColor': const Color(0xFF6678F3),
        'borderColor': const Color(0xFF007AFF),
        'isPolymarket': false,
      },
      {
        'title': 'Tesla Stock',
        'subtitle': 'Q1 2025 Target',
        'date': 'Jan 10, 2025',
        'marketPercentage': '35%',
        'aiPercentage': '58%',
        'team': 'Over 300',
        'platform': 'Polymarket',
        'iconAsset': 'assets/icons/polymarket.png',
        'bgColor': const Color(0xFF607D3B),
        'borderColor': AppColors.primary,
        'isPolymarket': true,
      },
    ];

    return Column(
      children: savedCards.map((cardData) {
        return Padding(
          padding: EdgeInsets.only(bottom: 20.h),
          child: BaseCard(
            title: cardData['title'],
            subtitle: cardData['subtitle'],
            date: cardData['date'],
            marketPercentage: cardData['marketPercentage'],
            aiPercentage: cardData['aiPercentage'],
            team: cardData['team'],
            bgColor: cardData['bgColor'],
            borderColor: cardData['borderColor'],
            platform: cardData['platform'],
            iconAsset: cardData['iconAsset'],
            isPolymarket: cardData['isPolymarket'],
            isSaved: true,
          ),
        );
      }).toList(),
    );
  }
}

// Base Card Widget
class BaseCard extends StatelessWidget {
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
  final bool isPolymarket;
  final bool isSaved;

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
    required this.isPolymarket,
    this.isSaved = false,
  });

  // Function to show remove warning dialog
  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          content: Container(
            constraints: BoxConstraints(minWidth: 280.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark_remove_outlined,
                    size: 32.w,
                    color: AppColors.primary,
                  ),
                ),
                
                SizedBox(height: 20.h),
                
                // Title
                Text(
                  'Remove from Saved?',
                  style: AppTextStyles.headlineSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 12.h),
                
                // Message
                Text(
                  'Are you sure you want to remove "$title" from your saved events?',
                  style: AppTextStyles.bodyMedium?.copyWith(
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 24.h),
                
                // Buttons Row
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.bodyLarge?.copyWith(
                                color: AppColors.gray700,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    // Remove Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Handle remove logic here
                          // Remove from saved list
                          Navigator.of(context).pop();
                          Get.snackbar(
                            'Removed',
                            'Event removed from saved',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.primary.withOpacity(0.9),
                            colorText: Colors.white,
                          );
                        },
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              'Remove',
                              style: AppTextStyles.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to CardDetailScreen when tapped on card
        Get.to(() => CardDetailScreen(
          title: title,
          subtitle: subtitle,
          date: date,
          marketPercentage: marketPercentage,
          aiPercentage: aiPercentage,
          team: team,
          isPolymarket: isPolymarket,
          bgColor: bgColor,
        ));
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.gray300 ?? const Color(0xFFE6E6E6),
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
                  iconAsset,
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
                        title,
                        style: AppTextStyles.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bookmark Icon - Separate GestureDetector to prevent card navigation
                GestureDetector(
                  onTap: () {
                    // Show warning dialog when bookmark is tapped
                    _showRemoveDialog(context);
                  },
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
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: borderColor,
                      width: 1.w,
                    ),
                  ),
                  child: Text(
                    platform,
                    style: AppTextStyles.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                SizedBox(width: 12.w), // Gap between tag and date
                
                // Date - not at far end
                Text(
                  date,
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
                    percentage: marketPercentage,
                    team: team,
                    percentageColor: const Color(0xff4588C6),
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                // Right Tab: AI Predicts
                Expanded(
                  child: ComparisonTab(
                    title: 'AI Predicts',
                    percentage: aiPercentage,
                    team: team,
                    percentageColor: const Color(0xffC41E3A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Comparison Tab Widget - Updated Design
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
        color: AppColors.gray100 ?? const Color(0xFFF5F5F5),
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
              color: AppColors.gray600 ?? const Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}