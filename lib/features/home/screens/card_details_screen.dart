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

class CardDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String aiPercentage;
  final String team;
  final bool isPolymarket;
  final Color bgColor;
  final List<String>? optionTitles;
  final List<double>? marketProbs;
  final List<double>? aiPercentages;
  final String? aiExplanation;

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
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger AI fetch when screen loads
    Future.microtask(() {
      Get.find<HomeController>().fetchAIForEventByTitle(widget.title);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return GetBuilder<HomeController>(
      builder: (ctrl) {
        // Find the current event - check saved events first, then home events
        Map<String, dynamic>? currentEvent;

        final savedEventIndex = ctrl.savedPolymarketEvents.indexWhere(
          (event) => event['title'] == widget.title,
        );

        final homeEventIndex = ctrl.allEvents.indexWhere(
          (event) => event['title'] == widget.title,
        );

        if (savedEventIndex != -1) {
          currentEvent = ctrl.savedPolymarketEvents[savedEventIndex];
        } else if (homeEventIndex != -1) {
          currentEvent = ctrl.allEvents[homeEventIndex];
        } else {
          currentEvent = {
            'title': widget.title,
            'aiPercentage': widget.aiPercentage,
            'aiExplanation': widget.aiExplanation ?? '',
            'aiPercentages': widget.aiPercentages ?? [],
          };
        }

        final updatedAiExplanation = currentEvent['aiExplanation'] as String?;
        final rawAiPercentages = currentEvent['aiPercentages'];

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
                  _buildMiniCard(),
                  SizedBox(height: 30.h),
                  _buildGradientInfoCard(updatedAiExplanation),
                  SizedBox(height: 30.h),
                  _buildOptionsSection(updatedAiPercentages),
                  SizedBox(height: 30.h),
                  CustomButton(
                    text: 'View on platform',
                    onPressed: _viewOnPlatform,
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
                widget.isPolymarket
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
                      widget.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.subtitle,
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
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: widget.isPolymarket ? AppColors.notBlue : AppColors.blue,
                    width: 1.w,
                  ),
                ),
                child: Text(
                  widget.isPolymarket ? 'Polymarket' : 'Kalshi',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                widget.date,
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

    final explanation = updatedAiExplanation ?? widget.aiExplanation;

    final description = explanation ??
        'Our AI model predicts ${widget.team} has a slightly higher chance '
        '(${widget.aiPercentage}) than the market suggests (${widget.marketPercentage}). '
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

  Widget _buildOptionsSection(List<double>? updatedAiPercentages) {
    final titles = widget.optionTitles ?? [];
    final probs = widget.marketProbs ?? [];
    final aiPercents = updatedAiPercentages ?? widget.aiPercentages ?? [];

    List<Map<String, dynamic>> displayOptions = [];

    if (titles.isNotEmpty && probs.isNotEmpty) {
      for (int i = 0; i < titles.length; i++) {
        if (i < probs.length && probs[i] > 0) {
          double aiPercent = 0;
          if (aiPercents.isNotEmpty && i < aiPercents.length) {
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
    Get.snackbar(
      'Platform Redirect',
      'Redirecting to ${widget.isPolymarket ? 'Polymarket' : 'Kalshi'}...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
