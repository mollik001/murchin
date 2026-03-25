import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/service/endpoint.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/features/sports/controllers/nba_finals_odds_controller.dart';
import 'package:murchin/features/sports/model/nba_finals_odds_model.dart';
import 'package:shimmer/shimmer.dart';

class NbaFinalsDetailsScreen extends StatefulWidget {
  final String platform;
  final Color bgColor;

  const NbaFinalsDetailsScreen({
    super.key,
    required this.platform,
    required this.bgColor,
  });

  @override
  State<NbaFinalsDetailsScreen> createState() => _NbaFinalsDetailsScreenState();
}

class _NbaFinalsDetailsScreenState extends State<NbaFinalsDetailsScreen> {
  late final NbaFinalsOddsController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<NbaFinalsOddsController>()) {
      controller = Get.find<NbaFinalsOddsController>();
    } else {
      controller = Get.put(NbaFinalsOddsController(), permanent: true);
    }
    _scrollController.addListener(_onScroll);

    // Load ALL pages and fetch AI for ALL teams when entering detail screen
    _loadAllPagesAndFetchAi();
  }

  /// Load all pages and fetch AI for ALL teams
  Future<void> _loadAllPagesAndFetchAi() async {
    // Load all pages for this platform
    await controller.fetchAllPagesForPlatform(widget.platform);
    
    // After all pages loaded, fetch AI for ALL teams (not just first 10)
    // Use postFrameCallback to avoid calling update() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAiForAllTeams();
    });
  }

  /// Fetch AI predictions for ALL teams in batches (more stable)
  void _fetchAiForAllTeams() async {
    final odds = controller.getOddsForPlatform(widget.platform);
    if (odds.isEmpty) return;

    controller.isAiLoading.value = true;
    controller.update();

    try {
      print('=== Fetching AI Predictions for ALL ${odds.length} teams ($widget.platform) in batches ===');

      // Fetch in batches of 10 teams for stability
      final batchSize = 10;
      final allPredictions = <String, String>{};

      for (int i = 0; i < odds.length; i += batchSize) {
        final batchEnd = (i + batchSize < odds.length) ? i + batchSize : odds.length;
        final batch = odds.sublist(i, batchEnd);
        
        print('Fetching batch ${i ~/ batchSize + 1}: teams ${i + 1}-${batchEnd}');

        final teamNames = batch.map((odd) => odd.teamName).toList();
        final teamValues = batch.map((odd) {
          try {
            return (double.parse(odd.price)).toInt();
          } catch (e) {
            return 0;
          }
        }).toList();

        try {
          final response = await controller.httpClient.post(
            Uri.parse('${Urls.aiBaseUrl}/nba-finals'),
            headers: {
              'Content-Type': 'application/json',
              'Connection': 'keep-alive',
            },
            body: jsonEncode({
              'team_names': teamNames,
              'team_values': teamValues,
            }),
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final aiPredictions = data['AI_prediction'] as List<dynamic>? ?? [];

            print('Batch ${i ~/ batchSize + 1} received: ${aiPredictions.length} predictions');

            for (int j = 0; j < teamNames.length && j < aiPredictions.length; j++) {
              allPredictions[teamNames[j]] = aiPredictions[j].toString();
            }
          } else {
            print('Batch ${i ~/ batchSize + 1} failed: ${response.statusCode}');
          }
        } catch (e) {
          print('Batch ${i ~/ batchSize + 1} error: $e');
        }

        // Small delay between batches to avoid rate limiting
        if (i + batchSize < odds.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (allPredictions.isNotEmpty) {
        controller.aiPredictions[widget.platform] = allPredictions;
        print('AI predictions stored for $widget.platform: ${allPredictions.length} teams');
        controller.updateOddsWithAiPredictions(widget.platform);
      } else {
        print('No AI predictions received for $widget.platform');
        controller.setAiLoadingComplete(widget.platform);
      }
    } catch (e) {
      print('Error fetching AI predictions for $widget.platform: $e');
      controller.setAiLoadingComplete(widget.platform);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !controller.isRefreshing.value &&
        controller.getOddsForPlatform(widget.platform).isNotEmpty) {
      controller.loadMoreOdds(widget.platform);
    }
  }

  Color _getPlatformTagBgColor() {
    final platform = widget.platform.toLowerCase();
    if (platform == 'fanduel') return AppColors.fanduelColor;
    if (platform == 'draftkings') return AppColors.draftkingsColor;
    if (platform == 'betmgm') return AppColors.betmgmColor;
    return widget.bgColor;
  }

  Color _getPlatformTagBorderColor() {
    return Colors.black;
  }

  Color _getSportsbookValueColor() {
    return _getPlatformTagBgColor();
  }

  String _getPlatformDisplayText() {
    final platform = widget.platform.toLowerCase();
    if (platform == 'fanduel') return 'FanDuel';
    if (platform == 'draftkings') return 'DraftKings';
    if (platform == 'betmgm') return 'BetMGM';
    return widget.platform;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
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
                              'assets/images/NBA.png',
                              width: 44.w,
                              height: 44.h,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                '2025-26 NBA Finals Winner',
                                style: AppTextStyles.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 4.h),
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
                              'Updated: ${controller.formatPrettyDate(DateTime.now().toIso8601String())}',
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Team',
                          style: AppTextStyles.bodyMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      SizedBox(
                        width: 80.w,
                        child: Text(
                          'Sportsbook',
                          style: AppTextStyles.bodySmall?.copyWith(
                            color: const Color(0xFF3CB043),
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      SizedBox(
                        width: 60.w,
                        child: Text(
                          'AI',
                          style: AppTextStyles.bodySmall?.copyWith(
                            color: const Color(0xFFA81D06),
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 14.w),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
            Expanded(
              child: GetBuilder<NbaFinalsOddsController>(
                builder: (controller) {
                  final odds = controller.getOddsForPlatform(widget.platform);
                  final hasOddsWithoutAi = odds.any((odd) => odd.aiPrediction == null);
                  final shouldShowShimmer = controller.isAiLoading.value || 
                      (controller.hasAiPredictions(widget.platform) && hasOddsWithoutAi);

                  if (controller.isLoading.value && odds.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (odds.isEmpty) {
                    return Center(
                      child: Text(
                        'No odds available',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16.sp,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemCount: odds.length + 1,
                    itemBuilder: (context, index) {
                      if (index < odds.length) {
                        return _buildOddCard(odds[index], isAiLoading: shouldShowShimmer);
                      } else {
                        if (controller.isRefreshing.value) {
                          return Padding(
                            padding: EdgeInsets.all(16.h),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return SizedBox.shrink();
                      }
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOddCard(NbaFinalsOdd odd, {bool? isAiLoading}) {
    final bool hasAiPrediction = odd.aiPrediction != null && odd.aiPrediction!.isNotEmpty;
    final bool isLoadingAi = !hasAiPrediction;
    final String aiValue = odd.aiPrediction ?? 'N/A';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.gray300, width: 1.w),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/NBA.png',
              width: 32.w,
              height: 32.h,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                odd.teamName,
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80.w,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getSportsbookValueColor(),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    odd.price,
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
                  width: 60.w,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isLoadingAi ? Colors.grey.shade300 : const Color(0xFFA81D06),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: isLoadingAi
                      ? _buildAiShimmer()
                      : Text(
                          aiValue,
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
    );
  }

  Widget _buildAiShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: double.infinity,
        height: 16.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }
}
