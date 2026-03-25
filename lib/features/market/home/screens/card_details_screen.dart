// lib/features/market/home/screens/card_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar_2.dart';
import 'package:murchin/const/widgets/custom_button.dart';
import 'package:murchin/features/market/home/controllers/home_controller.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class CardDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String aiPercentage;
  final String team;
  final bool isPolymarket;
  final Color bgColor;
  final int? eventId;
  final String? eventIdString;
  final String? slug;
  final String? seriesTicker;
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
    this.eventId,
    this.eventIdString,
    this.slug,
    this.seriesTicker,
    this.optionTitles,
    this.marketProbs,
    this.aiPercentages,
    this.aiExplanation,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  bool _isFetchingAI = false;
  String? _freshAiExplanation;
  String? _freshAiPercentage;
  List<double>? _freshAiPercentages;
  bool _isAiLoading = true;
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    // Check if event is already saved
    final controller = Get.find<HomeController>();
    if (widget.eventId != null) {
      _isSaved = controller.isEventSaved(widget.eventId!);
    } else if (widget.eventIdString != null) {
      _isSaved = controller.isKalshiEventSaved(widget.eventIdString!);
    }
    // Always fetch fresh AI data when detail screen opens (never use cache)
    Future.microtask(() => _fetchFreshAIData());
  }

  Future<void> _fetchFreshAIData() async {
    if (_isFetchingAI) return;
    _isFetchingAI = true;

    try {
      final controller = Get.find<HomeController>();

      // Build options and market predictions from widget data
      final optionTitles = widget.optionTitles ?? [];
      final marketProbs = widget.marketProbs ?? [];

      // Filter out 0% and 100% values
      List<String> filteredOptions = [];
      List<double> filteredMarketProbs = [];
      List<int> originalIndices = [];

      for (int j = 0; j < optionTitles.length && j < marketProbs.length; j++) {
        final prob = marketProbs[j];
        if (prob <= 0) continue;
        filteredOptions.add(optionTitles[j]);
        filteredMarketProbs.add(prob);
        originalIndices.add(j);
      }

      // Keep market leader at index 0
      if (widget.team.isNotEmpty) {
        int leaderIndex = filteredOptions.indexOf(widget.team);
        if (leaderIndex > 0) {
          final topOption = filteredOptions.removeAt(leaderIndex);
          final topProb = filteredMarketProbs.removeAt(leaderIndex);
          final topIndex = originalIndices.removeAt(leaderIndex);
          filteredOptions.insert(0, topOption);
          filteredMarketProbs.insert(0, topProb);
          originalIndices.insert(0, topIndex);
        }
      }

      print("Fetching fresh AI for: ${widget.title}");
      print("Options: $filteredOptions");
      print("Market probs: $filteredMarketProbs");

      // Fetch fresh AI data from API
      final aiData = await controller.fetchAIValue(
        eventName: widget.title,
        options: filteredOptions,
        marketPredictions: filteredMarketProbs,
        baseEvent: {
          'title': widget.title,
          'optionTitles': widget.optionTitles ?? [],
          'marketProbs': widget.marketProbs ?? [],
          'team': widget.team,
        },
        originalIndices: originalIndices,
      );

      print("Fresh AI received:");
      print("AI Percentage: ${aiData['aiPercentage']}");
      print("AI Explanation: ${aiData['aiExplanation']}");
      print("AI Percentages: ${aiData['aiPercentages']}");

      // Store fresh AI data only if still mounted
      if (mounted) {
        setState(() {
          _freshAiExplanation = aiData['aiExplanation'] as String?;
          _freshAiPercentage = aiData['aiPercentage'] as String?;
          final rawPercentages = aiData['aiPercentages'];
          if (rawPercentages != null && rawPercentages is List) {
            _freshAiPercentages = List<double>.from(rawPercentages);
          }
          _isAiLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching fresh AI data: $e");
      if (mounted) {
        setState(() {
          _isAiLoading = false;
        });
      }
    } finally {
      _isFetchingAI = false;
    }
  }

  Future<void> _toggleSaveEvent() async {
    if (_isSaving) return;
    
    // If already saved, do nothing
    if (_isSaved) return;

    // Debug: Print event IDs
    print('=== Save Event Debug ===');
    print('eventId: ${widget.eventId}');
    print('eventIdString: ${widget.eventIdString}');
    print('isPolymarket: ${widget.isPolymarket}');
    print('title: ${widget.title}');
    print('========================');

    // Check if we have an event ID to save
    if (widget.eventId == null && widget.eventIdString == null) {
      Get.snackbar(
        'Error',
        'Event ID not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final controller = Get.find<HomeController>();

    // Save event
    bool success = false;
    if (widget.eventId != null) {
      print('Saving Polymarket event with ID: ${widget.eventId}');
      success = await controller.saveEvent(
        eventId: widget.eventId!,
        marketPlace: 'Polymarket',
        title: widget.title,
        slug: widget.slug,
        seriesTicker: widget.seriesTicker,
        endDate: widget.date,
        team: widget.team,
        marketPercentage: widget.marketPercentage,
        aiPercentage: widget.aiPercentage,
        aiExplanation: widget.aiExplanation,
        optionTitles: widget.optionTitles,
        marketProbs: widget.marketProbs,
        aiPercentages: widget.aiPercentages,
      );
    } else if (widget.eventIdString != null) {
      print('Saving Kalshi event with ID: ${widget.eventIdString}');
      success = await controller.saveEvent(
        eventIdString: widget.eventIdString!,
        marketPlace: 'Kalshi',
        title: widget.title,
        slug: widget.slug,
        seriesTicker: widget.seriesTicker,
        endDate: widget.date,
        team: widget.team,
        marketPercentage: widget.marketPercentage,
        aiPercentage: widget.aiPercentage,
        aiExplanation: widget.aiExplanation,
        optionTitles: widget.optionTitles,
        marketProbs: widget.marketProbs,
        aiPercentages: widget.aiPercentages,
      );
    }

    if (success && mounted) {
      setState(() {
        _isSaved = true;
      });

      // Refresh saved events list in Saved screen
      await controller.fetchSavedEvents();

      Get.snackbar(
        'Saved',
        'Event saved to your list',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary.withOpacity(0.9),
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

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use fresh AI data if available, otherwise use widget data
    final aiExplanation = _freshAiExplanation ?? widget.aiExplanation ?? '';
    final aiPercentage = _freshAiPercentage ?? widget.aiPercentage ?? 'N/A';
    final aiPercentages = _freshAiPercentages ?? widget.aiPercentages ?? [];

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
              _buildMiniCard(isAiLoading: _isAiLoading),
              SizedBox(height: 30.h),
              _buildGradientInfoCard(aiExplanation),
              SizedBox(height: 30.h),
              _buildOptionsSection(aiPercentages, isAiLoading: _isAiLoading),
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
  }

  Widget _buildMiniCard({required bool isAiLoading}) {
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
                    Text(
                      widget.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _toggleSaveEvent,
                child: _isSaving
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : Image.asset(
                        _isSaved
                            ? 'assets/icons/bookmark_active.png'
                            : 'assets/icons/bookmark.png',
                        width: 20.w,
                        height: 20.h,
                        fit: BoxFit.contain,
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
                  color: widget.isPolymarket ? AppColors.polymarketColor : AppColors.kalshiColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: widget.isPolymarket ? Colors.grey : Colors.black,
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
              isAiLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 100.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    )
                  : Text(
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
  child: Text.rich(
    TextSpan(
      style: AppTextStyles.headlineMedium.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 14.sp,
      ),
      children: [
        const TextSpan(
          text: 'Pickf',
          style: TextStyle(color: Color(0xFF06205B)),
        ),
        const TextSpan(
          text: 'ai',
          style: TextStyle(color: Color(0xFFCF152D)),
        ),
        const TextSpan(
          text: 'r',
          style: TextStyle(color: Color(0xFF06205B)),
        ),
        const TextSpan(
          text: ' Insights',
          style: TextStyle(color: Color(0xFF06205B)),
        ),
      ],
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
    if (_isAiLoading) {
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

  Widget _buildOptionsSection(List<double>? updatedAiPercentages, {required bool isAiLoading}) {
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

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildOptionCard(
                title: option['title'],
                marketPercentage: option['marketPercentage'],
                aiPercentage: option['aiPercentage'],
                isAiLoading: isAiLoading,
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

  void _viewOnPlatform() async {
    if (widget.isPolymarket) {
      // For Polymarket events
      if (widget.slug != null && widget.slug!.isNotEmpty) {
        final url = Uri.parse('https://polymarket.com/event/${widget.slug}');
        print('🔗 Opening Polymarket URL: $url');
        
        try {
          // Directly launch the URL without canLaunchUrl check
          final launched = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
          
          if (!launched) {
            print('❌ Failed to launch URL');
            Get.snackbar(
              'Error',
              'Could not open the platform',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        } catch (e) {
          print('❌ Error launching URL: $e');
          Get.snackbar(
            'Error',
            'Could not open the platform',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        print('⚠️ No slug available for Polymarket event');
        Get.snackbar(
          'Unavailable',
          'Platform link not available for this event',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      // For Kalshi events
      if (widget.seriesTicker != null && widget.seriesTicker!.isNotEmpty) {
        final url = Uri.parse('https://kalshi.com/markets/${widget.seriesTicker}');
        print('🔗 Opening Kalshi URL: $url');
        
        try {
          final launched = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
          
          if (!launched) {
            print('❌ Failed to launch URL');
            Get.snackbar(
              'Error',
              'Could not open the platform',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        } catch (e) {
          print('❌ Error launching URL: $e');
          Get.snackbar(
            'Error',
            'Could not open the platform',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        print('⚠️ No series_ticker available for Kalshi event');
        Get.snackbar(
          'Unavailable',
          'Platform link not available for this event',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}
