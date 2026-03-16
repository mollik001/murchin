import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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
                                color: widget.bgColor,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                widget.platform,
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
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
            Expanded(
              child: GetBuilder<NbaFinalsOddsController>(
                builder: (controller) {
                  final isAiLoading = controller.isAiLoading.value;

                  if (controller.isLoading.value &&
                      controller.getOddsForPlatform(widget.platform).isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final odds = controller.getOddsForPlatform(widget.platform);

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
                        return _buildOddCard(odds[index], isAiLoading: isAiLoading);
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
    final bool isLoadingAi = isAiLoading == true || odd.aiPrediction == null || odd.isLoadingAi;
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
                    color: widget.bgColor,
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
