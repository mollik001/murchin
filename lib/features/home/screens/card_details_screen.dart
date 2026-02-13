// lib/features/card_detail/screens/card_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';
import 'package:murchin/const/widgets/custom_appbar_2.dart';
import 'package:murchin/const/widgets/custom_button.dart';

class CardDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String aiPercentage;
  final String team;
  final bool isPolymarket;
  final Color bgColor;

   CardDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.marketPercentage,
    required this.aiPercentage,
    required this.team,
    required this.isPolymarket,
    required this.bgColor,
  });

  // Color constant for Pickfair insights text
  final Color pickfairTextColor = const Color(0xFF194F46);

  // Sample candidate data
  final List<Map<String, String>> candidates = [
    {'initials': 'JV', 'name': 'JD Vance', 'party': 'Republican'},
    {'initials': 'DT', 'name': 'Donald Trump', 'party': 'Republican'},
    {'initials': 'RB', 'name': 'Ron DeSantis', 'party': 'Republican'},
    {'initials': 'NH', 'name': 'Nikki Haley', 'party': 'Republican'},
    {'initials': 'JB', 'name': 'Joe Biden', 'party': 'Democrat'},
    {'initials': 'KH', 'name': 'Kamala Harris', 'party': 'Democrat'},
    {'initials': 'EW', 'name': 'Elizabeth Warren', 'party': 'Democrat'},
    {'initials': 'BS', 'name': 'Bernie Sanders', 'party': 'Democrat'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppbar2(
        title: '',

        onBackPressed: () => Get.back(),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),

              // Mini Card (like from home page)
              _buildMiniCard(),

              SizedBox(height: 30.h),

              // Gradient Info Card with #194F46 text
              _buildGradientInfoCard(),

              SizedBox(height: 30.h),

              // Candidates Section
              _buildCandidatesSection(),

              SizedBox(height: 30.h),

              // View on Platform Button
              CustomButton(
                text: 'View on platform',
                onPressed: () {
                  // Handle platform navigation
                  _viewOnPlatform();
                },
                backgroundColor: AppColors.primary,
                borderRadius: 15.r,
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  // Mini Card (similar to home page card but simplified)
  Widget _buildMiniCard() {
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
          // Top row: Icon, Title, Bookmark
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform Icon
              Image.asset(
                isPolymarket
                    ? 'assets/icons/polymarket.png'
                    : 'assets/icons/kalshi.png',
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

              // Bookmark Icon
              Image.asset(
                'assets/icons/bookmark.png',
                width: 20.w,
                height: 20.h,
                fit: BoxFit.contain,
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Platform tag and date row
          Row(
            children: [
              // Platform Tag
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: isPolymarket ? AppColors.notBlue : AppColors.blue,
                    width: 1.w,
                  ),
                ),
                child: Text(
                  isPolymarket ? 'Polymarket' : 'Kalshi',
                  style: AppTextStyles.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // Date
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
        ],
      ),
    );
  }

  // Gradient Info Card with #194F46 text
  Widget _buildGradientInfoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primaryLight.withOpacity(0.6),
          ],
        ),
        image: const DecorationImage(
          image: AssetImage('assets/icons/gradient_bg.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and title row
            Row(
              children: [
                // AI Icon - always from assets/icons/ai.png
                Image.asset(
                  'assets/icons/ai.png',
                  width: 20.w,
                  height: 20.h,
                  fit: BoxFit.contain,
                  color: pickfairTextColor,
                ),
                SizedBox(width: 12.w),

                // Title - always "Pickfair Insights"
                Expanded(
                  child: Text(
                    'Pickfair Insights',
                    style: AppTextStyles.headlineMedium?.copyWith(
                      color: pickfairTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 6.h),

            // Description - always the same text
            _buildDescriptionText(),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionText() {
    // Use the exact description provided
    final description =
        'Our AI model predicts $team has a slightly higher chance '
        '($aiPercentage) than the market suggests ($marketPercentage). '
        'Historical data shows early frontrunners often maintain leads.';

    return Text(
      description,
      style: AppTextStyles.bodyMedium?.copyWith(
        color: pickfairTextColor,
        fontWeight: FontWeight.w500,
        fontSize: 14.sp,
        height: 1.6,
      ),
    );
  }

  // Candidates Section
  Widget _buildCandidatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Candidates',
          style: AppTextStyles.headlineSmall?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),

        SizedBox(height: 16.h),

        // Candidate Cards List
        Column(
          children: candidates.map((candidate) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildCandidateCard(
                initials: candidate['initials']!,
                name: candidate['name']!,
                party: candidate['party']!,
                marketPercentage: marketPercentage,
                aiPercentage: aiPercentage,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

// Candidate Card Widget
Widget _buildCandidateCard({
  required String initials,
  required String name,
  required String party,
  required String marketPercentage,
  required String aiPercentage,
}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.6),
    decoration: BoxDecoration(
      color: const Color(0xffF1F2F5),
      borderRadius: BorderRadius.circular(10.r),
      border: Border.all(
        color: const Color(0xffE7E9EE),
        width: 1.w,
      ),
    ),
    child: Row(
      children: [
        // Circular initials container
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: const Color(0xffD9D9D9),
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: Center(
            child: Text(
              initials,
              style: AppTextStyles.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),

        SizedBox(width: 12.w),

        // Name and Party
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                party,
                style: AppTextStyles.bodySmall?.copyWith(
                  color: AppColors.gray600,
                  fontWeight: FontWeight.w400,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 16.w),

        // Market Percentage - Centered
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center, // Changed to center
          children: [
            Text(
              'Market',
              style: AppTextStyles.bodySmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center, // Add text alignment
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF3CB043),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: const Color(0xFF3CB043),
                  width: 1.w,
                ),
              ),
              child: Text(
                marketPercentage,
                style: AppTextStyles.headlineSmall?.copyWith(
                 color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center, // Center text inside container
              ),
            ),
          ],
        ),

        SizedBox(width: 12.w),

        // AI Percentage - Centered
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center, // Changed to center
          children: [
            Text(
              'AI',
              style: AppTextStyles.bodySmall?.copyWith(
               color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center, // Add text alignment
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Color(0xffFD2400),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: Color(0xffFD2400),
                  width: 1.w,
                ),
              ),
              child: Text(
                aiPercentage,
                style: AppTextStyles.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center, // Center text inside container
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


  // Handle platform navigation
  void _viewOnPlatform() {
    // Navigate to platform URL or screen
    print('View on ${isPolymarket ? 'Polymarket' : 'Kalshi'}');
    
    // Example: Open URL
    // if (isPolymarket) {
    //   // Open Polymarket URL
    // } else {
    //   // Open Kalshi URL
    // }
    
    // Or show a dialog/snackbar
    Get.snackbar(
      'Platform Redirect',
      'Redirecting to ${isPolymarket ? 'Polymarket' : 'Kalshi'}...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}