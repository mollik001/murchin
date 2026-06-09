import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/features/sports/controllers/ai_prediction_controller.dart';
import 'package:murchin/features/sports/controllers/player_props_controller.dart';
import 'package:murchin/features/sports/home/controllers/sports_home_controller.dart';
import 'package:murchin/features/sports/model/player_props_model.dart';
import 'package:shimmer/shimmer.dart';

class SportsCardDetailsScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String aiPercentage;
  final String team;
  final bool isFanduel;
  final Color bgColor;
  final List<String>? optionTitles;
  final List<double>? marketProbs;
  final List<double>? aiPercentages;
  final String? aiExplanation;
  final String? awayTeam;
  final String? homeTeam;
  final String? spreadAway;
  final String? spreadHome;
  final String? moneylineAway;
  final String? moneylineHome;
  final String? totalOver;
  final String? totalUnder;
  final String? eventId;
  final String? platform;
  // AI Prediction values from bookmark
  final String? aiSpreadAway;
  final String? aiSpreadHome;
  final String? aiMoneylineAway;
  final String? aiMoneylineHome;
  final String? aiTotalOver;
  final String? aiTotalUnder;

  const SportsCardDetailsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.marketPercentage,
    required this.aiPercentage,
    required this.team,
    required this.isFanduel,
    required this.bgColor,
    this.optionTitles,
    this.marketProbs,
    this.aiPercentages,
    this.aiExplanation,
    this.awayTeam,
    this.homeTeam,
    this.spreadAway,
    this.spreadHome,
    this.moneylineAway,
    this.moneylineHome,
    this.totalOver,
    this.totalUnder,
    this.eventId,
    this.platform,
    this.aiSpreadAway,
    this.aiSpreadHome,
    this.aiMoneylineAway,
    this.aiMoneylineHome,
    this.aiTotalOver,
    this.aiTotalUnder,
  });

  @override
  State<SportsCardDetailsScreen> createState() => _SportsCardDetailsScreenState();
}

class _SportsCardDetailsScreenState extends State<SportsCardDetailsScreen> {
  final Set<int> _expandedCards = {};
  final PlayerPropsController _playerPropsController = Get.put(PlayerPropsController());
  final AiPredictionController _aiPredictionController = Get.put(AiPredictionController());

  // Local state for AI predictions
  String? _aiSpreadAway;
  String? _aiSpreadHome;
  String? _aiMoneylineAway;
  String? _aiMoneylineHome;
  String? _aiTotalOver;
  String? _aiTotalUnder;

  // Save state
  bool _isSaved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Check if event is already saved
    if (widget.eventId != null && widget.platform != null) {
      final controller = Get.find<SportsHomeController>();
      _isSaved = controller.isEventSaved(widget.eventId!, widget.platform!);
    }

    // Use AI values from widget if provided, otherwise fetch them
    _aiSpreadAway = widget.aiSpreadAway;
    _aiSpreadHome = widget.aiSpreadHome;
    _aiMoneylineAway = widget.aiMoneylineAway;
    _aiMoneylineHome = widget.aiMoneylineHome;
    _aiTotalOver = widget.aiTotalOver;
    _aiTotalUnder = widget.aiTotalUnder;

    // Fetch player props data if eventId and platform are provided
    if (widget.eventId != null && widget.platform != null) {
      final isMlb = widget.title.contains('MLB');
      _playerPropsController.fetchPlayerProps(
        eventId: widget.eventId!,
        platform: widget.platform!,
        isMlb: isMlb,
      ).then((_) {
        if (!mounted) return;
        // Fetch AI for all player props after player props are loaded
        if (widget.awayTeam != null && widget.homeTeam != null) {
          _playerPropsController.fetchAiForAllCategories(
            teamNames: [widget.awayTeam!, widget.homeTeam!],
            isMlb: isMlb,
          );
        }
      });
    }

    // Always fetch fresh AI predictions when opening event details
    _fetchAiPredictions();
  }

  Future<void> _fetchAiPredictions() async {
    if (widget.awayTeam == null || widget.homeTeam == null) return;

    final isMlb = widget.title.contains('MLB');
    final aiData = await _aiPredictionController.fetchAiPredictions(
      awayTeam: widget.awayTeam!,
      homeTeam: widget.homeTeam!,
      spreadAway: widget.spreadAway,
      spreadHome: widget.spreadHome,
      moneylineAway: widget.moneylineAway,
      moneylineHome: widget.moneylineHome,
      totalOver: widget.totalOver,
      totalUnder: widget.totalUnder,
      isMlb: isMlb,
    );

    if (aiData != null && mounted) {
      setState(() {
        _aiSpreadAway = aiData['aiSpreadAway'];
        _aiSpreadHome = aiData['aiSpreadHome'];
        _aiMoneylineAway = aiData['aiMoneylineAway'];
        _aiMoneylineHome = aiData['aiMoneylineHome'];
        _aiTotalOver = aiData['aiTotalOver'];
        _aiTotalUnder = aiData['aiTotalUnder'];
      });
    } else if (mounted) {
      // API failed or returned null, stop shimmer by setting default values
      setState(() {
        _aiSpreadAway ??= 'N/A';
        _aiSpreadHome ??= 'N/A';
        _aiMoneylineAway ??= 'N/A';
        _aiMoneylineHome ??= 'N/A';
        _aiTotalOver ??= 'N/A';
        _aiTotalUnder ??= 'N/A';
      });
    }
  }

  Future<void> _toggleSaveEvent() async {
    if (_isSaving) return;
    
    // If already saved, do nothing
    if (_isSaved) return;

    // Check if we have an event ID and platform
    if (widget.eventId == null || widget.platform == null) {
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

    final controller = Get.find<SportsHomeController>();

    // Save event via API
    final success = await controller.saveEvent(
      eventId: widget.eventId!,
      marketPlace: widget.platform!,
      title: widget.title,
      subtitle: '${widget.awayTeam ?? ''} vs ${widget.homeTeam ?? ''}',
      endDate: widget.date,
      marketPercentage: widget.marketPercentage,
      aiPercentage: widget.aiPercentage,
      team: widget.homeTeam ?? '',
    );

    if (success && mounted) {
      setState(() {
        _isSaved = true;
      });

      // Refresh saved events list
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

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _playerPropsController.clearPlayerProps();
    super.dispose();
  }

  void _toggleCard(int index) {
    setState(() {
      if (_expandedCards.contains(index)) {
        _expandedCards.remove(index);
      } else {
        _expandedCards.add(index);
      }
    });
  }

  Color _getPlatformTagBgColor() {
    final platform = widget.platform?.toLowerCase() ?? (widget.isFanduel ? 'fanduel' : 'draftkings');
    if (platform == 'fanduel') return AppColors.fanduelColor;
    if (platform == 'draftkings') return AppColors.draftkingsColor;
    if (platform == 'betmgm') return AppColors.betmgmColor;
    return widget.bgColor;
  }

  Color _getPlatformTagBorderColor() {
    return Colors.black;
  }

  String _getPlatformDisplayText() {
    final platform = widget.platform?.toLowerCase() ?? (widget.isFanduel ? 'fanduel' : 'draftkings');
    if (platform == 'fanduel') return 'FanDuel';
    if (platform == 'draftkings') return 'DraftKings';
    if (platform == 'betmgm') return 'BetMGM';
    return platform;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Back Button
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                    size: 20.sp,
                  ),
                ),

                SizedBox(height: 20.h),

                /// Card with NBA Logo, Title and Bookmark
                Container(
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
                            widget.title.contains('MLB') ? 'assets/images/mlb.png' : 'assets/images/NBA.png',
                            width: 44.w,
                            height: 44.h,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: AppTextStyles.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
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
                            color: _getPlatformTagBgColor(),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: _getPlatformTagBorderColor(),
                                width: 1.w,
                            ),
                            ),
                            child: Text(
                              _getPlatformDisplayText(),
                              style: AppTextStyles.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
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
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                /// Section Header
                Row(
                  children: [
                    Text(
                      widget.title.contains('MLB') ? 'MLB' : 'NBA',
                      style: AppTextStyles.bodyLarge?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    SizedBox(
                      width: 48.w,
                      child: Text(
                        'Spread',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    SizedBox(
                      width: 48.w,
                      child: Text(
                        'Money',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    SizedBox(
                      width: 55.w,
                      child: Text(
                        'Total',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                ),

                SizedBox(height: 8.h),

                /// Divider
                Container(
                  height: 1.h,
                  color: AppColors.gray300,
                ),

                SizedBox(height: 24.h),

                /// Team Values Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.gray300, width: 1.w),
                  ),
                  child: Column(
                    children: [
/// Away Team Section
                       Row(
                         children: [
                           Image.asset(
                             widget.title.contains('MLB') ? 'assets/images/mlb.png' : 'assets/images/NBA.png',
                             width: 32.w,
                             height: 32.h,
                           ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Text(
                              widget.awayTeam ?? 'Away Team',
                              style: AppTextStyles.bodyLarge?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48.w,
                            child: _buildValueContainer(widget.spreadAway ?? '-', const Color(0xFF3CB043)),
                          ),
                          SizedBox(width: 14.w),
                          SizedBox(
                            width: 48.w,
                            child: _buildValueContainer(widget.moneylineAway ?? '-', const Color(0xFFFF6D00)),
                          ),
                          SizedBox(width: 14.w),
                          SizedBox(
                            width: 55.w,
                            child: _buildValueContainer(widget.totalOver ?? '-', const Color(0xFF0D47A1)),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      /// AI Prediction for Away Team
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/ai_logo.png',
                            width: 24.w,
                            height: 24.h,
                          ),
                          SizedBox(width: 14.w),
                          Text(
                            'AI Prediction',
                            style: AppTextStyles.bodySmall?.copyWith(
                              color: const Color(0xff848484),
                              fontWeight: FontWeight.w500,
                              fontSize: 12.sp,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 48.w,
                            child: _buildAiValueContainer(_aiSpreadAway),
                          ),
                          SizedBox(width: 14.w),
                          SizedBox(
                            width: 48.w,
                            child: _buildAiValueContainer(_aiMoneylineAway),
                          ),
                          SizedBox(width: 14.w),
                          SizedBox(
                            width: 55.w,
                            child: _buildAiValueContainer(_aiTotalOver),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      /// VS Divider
                      Row(
                        children: [
                          SizedBox(
                            width: 40.w,
                            child: Container(
                              height: 1.h,
                              color: Color(0xff203966),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              'Vs',
                              style: AppTextStyles.bodySmall?.copyWith(
                                color: Color(0xff203966),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 40.w,
                            child: Container(
                              height: 1.h,
                              color: Color(0xff203966),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

/// Team 2 Section
                       Row(
                         children: [
                           Image.asset(
                             widget.title.contains('MLB') ? 'assets/images/mlb.png' : 'assets/images/NBA.png',
                             width: 32.w,
                             height: 32.h,
                           ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Text(
                              widget.homeTeam ?? 'Home Team',
                              style: AppTextStyles.bodyLarge?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48.w,
                            child: _buildValueContainer(widget.spreadHome ?? '-', const Color(0xFF3CB043)),
                          ),
                          SizedBox(width: 14.w),
                          SizedBox(
                            width: 48.w,
                            child: _buildValueContainer(widget.moneylineHome ?? '-', const Color(0xFFFD6500)),
                          ),
                          SizedBox(width: 14.w),
                          SizedBox(
                            width: 55.w,
                            child: _buildValueContainer(widget.totalUnder ?? '-', const Color(0xFF203966)),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      /// AI Prediction for Team 2
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/ai_logo.png',
                            width: 24.w,
                            height: 24.h,
                          ),
                          SizedBox(width: 14.w),
                          Text(
                            'AI Prediction',
                            style: AppTextStyles.bodySmall?.copyWith(
                              color: const Color(0xff848484),
                              fontWeight: FontWeight.w500,
                              fontSize: 12.sp,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 48.w,
                            child: _buildAiValueContainer(_aiSpreadHome),
                          ),
                          SizedBox(width: 14.w),
                          SizedBox(
                            width: 48.w,
                            child: _buildAiValueContainer(_aiMoneylineHome),
                          ),
                          SizedBox(width: 14.w),
                          SizedBox(
                            width: 55.w,
                            child: _buildAiValueContainer(_aiTotalUnder),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                /// Player Props Section
                Obx(() {
                  if (_playerPropsController.isLoading.value) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.h),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final categories = _playerPropsController.getAvailableCategories();
                  
                  if (categories.isEmpty) {
                    // Only show static fallback for NBA events
                    if (!widget.title.contains('MLB')) {
                      return Column(
                        children: [
                          _buildExpandableCard(0, 'First Basket', false),
                          SizedBox(height: 12.h),
                          _buildExpandableCard(1, 'First team basket scorer', false),
                          SizedBox(height: 12.h),
                          _buildExpandableCard(2, 'To Score 10+ Points', true),
                          SizedBox(height: 12.h),
                          _buildExpandableCard(3, 'To Score 25+ Points', true),
                          SizedBox(height: 12.h),
                          _buildExpandableCard(4, '5+ Made Threes', true),
                          SizedBox(height: 12.h),
                          _buildExpandableCard(5, 'To record 10+ Rebounds', true),
                        ],
                      );
                    }
                    // For MLB, if no data, show nothing or empty message
                    return const SizedBox.shrink();
                  }

                  // Show API data
                  return Column(
                    children: categories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final title = _playerPropsController.getCategoryTitle(category);
                      final rawPropsData = _playerPropsController.playerProps?.getPropsByCategory(category) ?? {};

                      if (rawPropsData.isEmpty) return const SizedBox.shrink();

                      // Filter out players or direct props with no valid odds
                      final Map<String, dynamic> filteredPropsData = {};
                      
                      // Check if it's a direct prop (keys are 'over', 'under', etc., not player names)
                      final bool isDirectProp = rawPropsData.containsKey('over') || 
                                               rawPropsData.containsKey('under') || 
                                               rawPropsData.containsKey('result');

                      if (isDirectProp) {
                        // Direct Prop: only keep if it has at least one valid odd
                        if (rawPropsData.containsKey('over') || 
                            rawPropsData.containsKey('under') || 
                            rawPropsData.containsKey('result')) {
                          filteredPropsData.addAll(rawPropsData);
                        }
                      } else {
                        // Player-Mapped Prop: filter players to keep only those with valid odds
                        rawPropsData.forEach((playerName, playerData) {
                          if (playerData is Map && (playerData.containsKey('over') || 
                                                   playerData.containsKey('under') || 
                                                   playerData.containsKey('result'))) {
                            filteredPropsData[playerName] = playerData;
                          }
                        });
                      }

                      if (filteredPropsData.isEmpty) return const SizedBox.shrink();

                      final firstValue = filteredPropsData.values.first;
                      final isMlb = widget.title.contains('MLB');
                      Map<String, dynamic> finalPropsData;
                      bool hasOverUnder;

                      if (isDirectProp) {
                        // Direct Prop (e.g. totals_1st_1_innings)
                        if (isMlb && (category == 'totals_1st_1_innings' || category == 'totals_1st_5_innings')) {
                          // Special MLB Split logic: Treat "over" and "under" as separate players
                          finalPropsData = {};
                          if (filteredPropsData.containsKey('over')) {
                            finalPropsData['Over'] = {'over': filteredPropsData['over'], 'point': filteredPropsData['point']};
                          }
                          if (filteredPropsData.containsKey('under')) {
                            finalPropsData['Under'] = {'over': filteredPropsData['under'], 'point': filteredPropsData['point']};
                          }
                          hasOverUnder = false; // They are now Type 1 single value items
                        } else {
                          finalPropsData = {"Game Total": filteredPropsData};
                          hasOverUnder = filteredPropsData.containsKey('over') && filteredPropsData.containsKey('under');
                        }
                      } else {
                        // Player-Mapped Prop
                        finalPropsData = filteredPropsData;
                        hasOverUnder = PlayerPropsResponse.hasOverUnder(firstValue);
                      }

                      return Column(
                        children: [
                          if (index > 0) SizedBox(height: 12.h),
                          _buildPlayerPropsCard(index, title, category, finalPropsData, hasOverUnder),
                        ],
                      );
                    }).toList(),
                  );
                }),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableCard(int index, String title, bool isOverUnder) {
    final isExpanded = _expandedCards.contains(index);

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.gray300, width: 1.w),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _toggleCard(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                    if (isOverUnder && isExpanded) ...[
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'Over',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'Under',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 4.w),
                  ],
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.gray600,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              height: 1.h,
              color: AppColors.gray300,
            ),
            if (isOverUnder) _buildOverUnderPlayerList() else _buildPlayerList(),
          ],
        ],
      ),
    );
  }

  /// Build player props card with API data
  Widget _buildPlayerPropsCard(int index, String title, String category, Map<String, dynamic> propsData, bool hasOverUnder) {
    final isExpanded = _expandedCards.contains(index);

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.gray300, width: 1.w),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _toggleCard(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  if (hasOverUnder && isExpanded) ...[
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'Over',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'Under',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 4.w),
                  ],
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.gray600,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              height: 1.h,
              color: AppColors.gray300,
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Obx(() {
                return Column(
                  children: propsData.entries.map((entry) {
                    final playerName = entry.key;
                    final playerData = entry.value;
                    final isOverUnder = PlayerPropsResponse.hasOverUnder(playerData);

                    return Column(
                      children: [
                        if (isOverUnder)
                          _buildOverUnderPlayerItem(playerName, playerData, category)
                        else
                          _buildSingleValuePlayerItem(playerName, playerData, category),
                        if (entry.key != propsData.keys.last)
                          Container(
                            height: 1.h,
                            color: AppColors.gray300,
                            margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
                          ),
                      ],
                    );
                  }).toList(),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  /// Build over/under player item with API data
  Widget _buildOverUnderPlayerItem(String playerName, dynamic playerData, String category) {
    final over = playerData is Map ? playerData['over']?.toString().replaceAll('+', '') ?? '-' : '-';
    final under = playerData is Map ? playerData['under']?.toString().replaceAll('+', '') ?? '-' : '-';
    final initials = playerName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

    // Check if AI is still loading for this category
    final isAiLoading = !_playerPropsController.isAiLoaded(category);
    
    // Get AI predictions for this player (Type 2)
    final aiPrediction = _playerPropsController.getAiPredictionForType2(category, playerName);
    final aiOver = aiPrediction?['over'];
    final aiUnder = aiPrediction?['under'];

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.bodySmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              playerName,
              style: AppTextStyles.bodySmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 14.w),
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'Sportsbook',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: const Color(0xFF3CB043),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'Sportsbook',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: const Color(0xFF3CB043),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      width: 50.w,
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3CB043),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        over,
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Container(
                      width: 50.w,
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3CB043),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        under,
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'AI',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: const Color(0xFFA81D06),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'AI',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: const Color(0xFFA81D06),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    isAiLoading
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: 50.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          )
                        : Container(
                            width: 50.w,
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA81D06),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              aiOver ?? '-',
                              style: AppTextStyles.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                    SizedBox(width: 14.w),
                    isAiLoading
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: 50.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          )
                        : Container(
                            width: 50.w,
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA81D06),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              aiUnder ?? '-',
                              style: AppTextStyles.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build single value player item (result or over only)
  Widget _buildSingleValuePlayerItem(String playerName, dynamic playerData, String category) {
    final sportsbookValue = PlayerPropsResponse.getSportsbookValue(playerData)?.toString().replaceAll('+', '') ?? '-';
    final initials = playerName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    
    // Check if AI is still loading for this category
    final isAiLoading = !_playerPropsController.isAiLoaded(category);
    
    // Get AI prediction for this player
    final aiPredictions = _playerPropsController.getAiPredictions(category);
    final aiValue = aiPredictions[playerName];

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.bodySmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              playerName,
              style: AppTextStyles.bodySmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 14.w),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  SizedBox(
                    width: 54.w,
                    child: Text(
                      'Sportsbook',
                      style: AppTextStyles.bodySmall?.copyWith(
                        color: const Color(0xFF3CB043),
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 54.w,
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3CB043),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      sportsbookValue,
                      style: AppTextStyles.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 14.w),
              Column(
                children: [
                  SizedBox(
                    width: 54.w,
                    child: Text(
                      'AI',
                      style: AppTextStyles.bodySmall?.copyWith(
                        color: const Color(0xFFA81D06),
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  isAiLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: 54.w,
                          height: 24.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      )
                    : Container(
                        width: 54.w,
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA81D06),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          aiValue ?? '-',
                          style: AppTextStyles.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList() {
    final players = [
      {'name': 'Shai Gilgeous-Alexander', 'team': 'Oklahoma City Thunder', 'sportsbook': '+350', 'ai': '+380'},
      {'name': 'Jalen Williams', 'team': 'Oklahoma City Thunder', 'sportsbook': '+450', 'ai': '+420'},
      {'name': 'Luka Doncic', 'team': 'Dallas Mavericks', 'sportsbook': '+500', 'ai': '+550'},
      {'name': 'Jayson Tatum', 'team': 'Boston Celtics', 'sportsbook': '+600', 'ai': '+580'},
    ];

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          for (int i = 0; i < players.length; i++) ...[
            _buildPlayerItem(
              players[i]['name']!,
              players[i]['team']!,
              players[i]['sportsbook']!,
              players[i]['ai']!,
            ),
            if (i < players.length - 1)
              Container(
                height: 1.h,
                color: AppColors.gray300,
                margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerItem(String name, String team, String sportsbook, String ai) {
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.bodySmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  team,
                  style: AppTextStyles.bodySmall?.copyWith(
                    color: const Color(0xFF626262),
                    fontWeight: FontWeight.w400,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Sportsbook',
                style: AppTextStyles.bodySmall?.copyWith(
                  color: AppColors.gray600,
                  fontWeight: FontWeight.w500,
                  fontSize: 10.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF3CB043),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  sportsbook,
                  style: AppTextStyles.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'AI',
                style: AppTextStyles.bodySmall?.copyWith(
                  color: AppColors.gray600,
                  fontWeight: FontWeight.w500,
                  fontSize: 10.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFA81D06),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  ai,
                  style: AppTextStyles.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverUnderPlayerList() {
    final players = [
      {'name': 'Shai Gilgeous-Alexander', 'team': 'Oklahoma City Thunder', 'sportsbookOver': '-115', 'sportsbookUnder': '-115', 'aiOver': '-120', 'aiUnder': '-110'},
      {'name': 'Jalen Williams', 'team': 'Oklahoma City Thunder', 'sportsbookOver': '-115', 'sportsbookUnder': '-115', 'aiOver': '-120', 'aiUnder': '-110'},
      {'name': 'Luka Doncic', 'team': 'Dallas Mavericks', 'sportsbookOver': '-115', 'sportsbookUnder': '-115', 'aiOver': '-120', 'aiUnder': '-110'},
      {'name': 'Jayson Tatum', 'team': 'Boston Celtics', 'sportsbookOver': '-115', 'sportsbookUnder': '-115', 'aiOver': '-120', 'aiUnder': '-110'},
    ];

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          for (int i = 0; i < players.length; i++) ...[
            _buildOverUnderPlayerItemStatic(
              players[i]['name']!,
              players[i]['team']!,
              players[i]['sportsbookOver']!,
              players[i]['sportsbookUnder']!,
              players[i]['aiOver']!,
              players[i]['aiUnder']!,
            ),
            if (i < players.length - 1)
              Container(
                height: 1.h,
                color: AppColors.gray300,
                margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverUnderPlayerItemStatic(String name, String team, String sportsbookOver, String sportsbookUnder, String aiOver, String aiUnder) {
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.bodySmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100.w,
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                    style: AppTextStyles.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  width: 100.w,
                  child: Text(
                    team,
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                    style: AppTextStyles.bodySmall?.copyWith(
                      color: const Color(0xFF626262),
                      fontWeight: FontWeight.w400,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'Sportsbook',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: const Color(0xFF3CB043),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'Sportsbook',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: const Color(0xFF3CB043),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      width: 50.w,
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3CB043),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        sportsbookOver,
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Container(
                      width: 50.w,
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3CB043),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        sportsbookUnder,
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'AI',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: const Color(0xFFA81D06),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    SizedBox(
                      width: 54.w,
                      child: Text(
                        'AI',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: const Color(0xFFA81D06),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      width: 50.w,
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA81D06),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        aiOver,
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Container(
                      width: 50.w,
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA81D06),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        aiUnder,
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueContainer(String value, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        value,
        style: AppTextStyles.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAiValueContainer(String? value) {
    // Show shimmer if value is null or empty (loading state)
    if (value == null || value.isEmpty || value == '-') {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
          ),
          height: 28.h,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFA81D06),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        _formatValue(value),
        style: AppTextStyles.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Format value - remove '+' sign for positive values
  String _formatValue(String value) {
    if (value == 'N/A' || value == '-') return value;
    // Remove '+' prefix for positive values
    if (value.startsWith('+')) {
      return value.substring(1);
    }
    return value;
  }
}
