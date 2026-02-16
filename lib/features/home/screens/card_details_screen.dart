// lib/features/card_detail/screens/card_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar_2.dart';
import 'package:murchin/const/widgets/custom_button.dart';
import 'package:murchin/features/home/controllers/home_controller.dart';
import 'package:shimmer/shimmer.dart';

class CardDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String aiPercentage;
  final String team;
  final bool isPolymarket;
  final Color bgColor;
  final List<String>? optionTitles;  // All option titles
  final List<double>? marketProbs;   // All market probabilities
  final List<double>? aiPercentages; // All AI percentages (calculated from AI API response)
  final String? aiExplanation;      // AI explanation from API

  // Store original AI percentages to check if loading is needed
  final List<double>? originalAiPercentages;

  const CardDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.marketPercentage,
    required this.aiPercentage,
    required this.team,
    required this.isPolymarket,
    required this.bgColor,
    this.optionTitles,
    this.marketProbs,
    this.aiPercentages,
    this.aiExplanation,
  }) : originalAiPercentages = aiPercentages;

  @override
  Widget build(BuildContext context) {
    // Get the HomeController to listen for updates
    final controller = Get.find<HomeController>();

    // 🔥 Trigger AI fetch once when screen builds
    if ((originalAiPercentages == null || originalAiPercentages!.isEmpty)) {
      Future.microtask(() {
        controller.fetchAIForEventByTitle(title);
      });
    }

    return GetX<HomeController>(
      builder: (ctrl) {
        // Find the current event in the controller to get updated AI values
        final currentEvent = ctrl.events.firstWhere(
          (event) => event['title'] == title,
          orElse: () => {
            'title': title,
            'subtitle': subtitle,
            'date': date,
            'marketPercentage': marketPercentage,
            'aiPercentage': aiPercentage,
            'team': team,
            'optionTitles': optionTitles ?? [],
            'marketProbs': marketProbs ?? [],
            'aiPercentages': aiPercentages ?? [],
            'aiExplanation': aiExplanation ?? '',
          },
        );

        // Use the updated values from the controller if available
        final rawOptionTitles = currentEvent['optionTitles'];
        final rawMarketProbs = currentEvent['marketProbs'];
        final rawAiPercentages = currentEvent['aiPercentages'];
        final updatedAiExplanation = currentEvent['aiExplanation'] as String?;

        // Safely convert dynamic lists to the expected types
        List<String>? updatedOptionTitles;
        if (rawOptionTitles != null) {
          if (rawOptionTitles is List<String>) {
            updatedOptionTitles = rawOptionTitles;
          } else if (rawOptionTitles is List<dynamic>) {
            updatedOptionTitles = rawOptionTitles.cast<String>();
          } else {
            updatedOptionTitles = List<String>.from(rawOptionTitles);
          }
        }

        List<double>? updatedMarketProbs;
        if (rawMarketProbs != null) {
          if (rawMarketProbs is List<double>) {
            updatedMarketProbs = rawMarketProbs;
          } else if (rawMarketProbs is List<dynamic>) {
            updatedMarketProbs = rawMarketProbs.cast<double>();
          } else {
            updatedMarketProbs = List<double>.from(rawMarketProbs);
          }
        }

        List<double>? updatedAiPercentages;
        if (rawAiPercentages != null) {
          if (rawAiPercentages is List<double>) {
            updatedAiPercentages = rawAiPercentages;
          } else if (rawAiPercentages is List<dynamic>) {
            updatedAiPercentages = rawAiPercentages.cast<double>();
          } else {
            updatedAiPercentages = List<double>.from(rawAiPercentages);
          }
        }

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
                  _buildGradientInfoCard(updatedAiExplanation),

                  SizedBox(height: 30.h),

                  // Options Section
                  _buildOptionsSection(updatedOptionTitles, updatedMarketProbs, updatedAiPercentages),

                  SizedBox(height: 30.h),

                  // View on Platform Button
                  CustomButton(
                    text: 'View on platform',
                    onPressed: () {
                      _viewOnPlatform();
                    },
                    backgroundColor: AppColors.primary,
                    borderRadius: 15.r,
                  ),

                  SizedBox(height: 70.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                isPolymarket
                    ? 'assets/icons/polymarket.png'
                    : 'assets/icons/kalshi.png',
                width: 44.w,
                height: 44.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/icons/bookmark.png',
                width: 20.w,
                height: 20.h,
                fit: BoxFit.contain,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
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
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                date,
                style: AppTextStyles.bodySmall.copyWith(
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

  Widget _buildGradientInfoCard(String? updatedAiExplanation) {
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
            Row(
              children: [
                Image.asset(
                  'assets/icons/ai.png',
                  width: 20.w,
                  height: 20.h,
                  fit: BoxFit.contain,
                  color: AppColors.pickfairTextColor,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Pickfair Insights',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.pickfairTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            _buildDescriptionText(updatedAiExplanation),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionText(String? updatedAiExplanation) {
    bool isAiExplanationLoading = (updatedAiExplanation?.isEmpty ?? true);

    if (isAiExplanationLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 16.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
              margin: EdgeInsets.only(bottom: 8.h),
            ),
            Container(
              width: double.infinity,
              height: 16.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
              margin: EdgeInsets.only(bottom: 8.h),
            ),
            Container(
              width: 200.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ],
        ),
      );
    }

    final explanation = updatedAiExplanation ?? aiExplanation;

    final description = explanation ??
        'Our AI model predicts $team has a slightly higher chance '
        '($aiPercentage) than the market suggests ($marketPercentage). '
        'Historical data shows early frontrunners often maintain leads.';

    return Text(
      description,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.pickfairTextColor,
        fontWeight: FontWeight.w500,
        fontSize: 14.sp,
        height: 1.6,
      ),
    );
  }

  Widget _buildOptionsSection(
    List<String>? updatedOptionTitles,
    List<double>? updatedMarketProbs,
    List<double>? updatedAiPercentages,
  ) {
    final titles = updatedOptionTitles ?? optionTitles;
    final probs = updatedMarketProbs ?? marketProbs;
    final aiPercents = updatedAiPercentages ?? aiPercentages;

    List<Map<String, dynamic>> displayOptions = [];

    if (titles != null && probs != null) {
      for (int i = 0; i < titles.length; i++) {
        if (i < probs.length && probs[i] > 0) {
          double aiPercent = 0;
          if (aiPercents != null && i < aiPercents.length) {
            aiPercent = aiPercents[i];
          }

          displayOptions.add({
            'title': titles[i],
            'marketPercentage': probs[i],
            'aiPercentage': aiPercent,
          });
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options',
          style: AppTextStyles.headlineSmall.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 16.h),
        Column(
          children: displayOptions.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> option = entry.value;
            bool isOptionAiLoading = (updatedAiPercentages?.isEmpty ?? true);

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildOptionCard(
                title: option['title'],
                marketPercentage: option['marketPercentage'],
                aiPercentage: option['aiPercentage'],
                isAiLoading: isOptionAiLoading,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required double marketPercentage,
    required double aiPercentage,
    required bool isAiLoading,
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
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Market',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                  textAlign: TextAlign.center,
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
                    '${marketPercentage.round()}%',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'AI',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                isAiLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 40.w,
                          height: 24.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: const Color(0xffFD2400),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: const Color(0xffFD2400),
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          '${aiPercentage.round()}%',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewOnPlatform() {
    print('View on ${isPolymarket ? 'Polymarket' : 'Kalshi'}');

    Get.snackbar(
      'Platform Redirect',
      'Redirecting to ${isPolymarket ? 'Polymarket' : 'Kalshi'}...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
