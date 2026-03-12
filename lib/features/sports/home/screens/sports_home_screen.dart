// lib/features/sports/home/screens/sports_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';
import 'package:murchin/features/sports/home/controllers/sports_home_controller.dart';
import 'package:murchin/features/sports/home/model/sportsbook_model.dart';
import 'package:murchin/features/sports/home/widgets/sports_base_card.dart';
import 'package:murchin/features/sports/home/widgets/sports_card_details_screen.dart';

class SportsHomeScreen extends StatefulWidget {
  const SportsHomeScreen({super.key});

  @override
  State<SportsHomeScreen> createState() => _SportsHomeScreenState();
}

class _SportsHomeScreenState extends State<SportsHomeScreen> {
  final SportsHomeController controller = Get.put(SportsHomeController());
  final ScrollController scrollController = ScrollController();

  final Color unselectedBgColor = const Color(0xFFBDC4D2);
  final Color fanduelBgColor = const Color(0xFF607D3B);
  final Color draftkingsBgColor = const Color(0xFF6678F3);
  final Color betmgmBgColor = const Color(0xFFE31837);

  @override
  void initState() {
    super.initState();
    // No pagination needed for now - API returns all events
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  String formatPrettyDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  Color _getBgColor(String marketTitle) {
    switch (marketTitle.toLowerCase()) {
      case 'fanduel':
        return fanduelBgColor;
      case 'draftkings':
        return draftkingsBgColor;
      case 'betmgm':
        return betmgmBgColor;
      default:
        return unselectedBgColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(imageAsset: 'assets/images/name.png'),
      body: Column(
        children: [
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildSearchBar(),
          ),
          SizedBox(height: 30.h),
          Expanded(
            child: Obx(() {
              // Show search results when there's an active search or search results
              if (controller.hasActiveSearch.value || controller.searchResults.isNotEmpty) {
                if (controller.isSearching.value) {
                  return _buildLoadingState();
                }

                if (controller.searchResults.isEmpty) {
                  return _buildEmptyState(
                    message: 'No search results found',
                    subtitle: 'Try a different search term',
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: controller.searchResults.length,
                  itemBuilder: (context, index) {
                    final event = controller.searchResults[index];
                    return _buildSearchResultCard(event);
                  },
                );
              }

              if (controller.sportsbookEvents.isEmpty && controller.isLoading.value) {
                return _buildLoadingState();
              }

              if (controller.sportsbookEvents.isEmpty && !controller.isLoading.value) {
                return _buildEmptyState(
                  message: 'No data available',
                  subtitle: 'Please check back later',
                  actionLabel: 'Retry',
                  onAction: () {
                    controller.fetchSportsbookEvents();
                  },
                );
              }

              return ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: controller.sportsbookEvents.length,
                itemBuilder: (context, eventIndex) {
                  final event = controller.sportsbookEvents[eventIndex];
                  
                  return Column(
                    children: [
                      // Cards for each sportsbook
                      ...event.bookmark.map((bookmark) {
                        // Get H2H market and determine favorite team
                        final h2hMarket = bookmark.market.firstWhere(
                          (m) => m.key == 'h2h',
                          orElse: () => Market(id: 0, key: '', outcome: MarketOutcome(), bookmark: 0),
                        );
                        
                        final awayMoneyline = h2hMarket.outcome.awayTeam?.american;
                        final homeMoneyline = h2hMarket.outcome.homeTeam?.american;
                        
                        // Determine the favorite (lowest american value)
                        String favoriteTeam;
                        String? moneylineOdds;
                        
                        if (awayMoneyline != null && homeMoneyline != null) {
                          final awayValue = int.tryParse(awayMoneyline) ?? 0;
                          final homeValue = int.tryParse(homeMoneyline) ?? 0;
                          
                          if (awayValue < homeValue) {
                            favoriteTeam = event.awayTeam;
                            moneylineOdds = awayMoneyline;
                          } else {
                            favoriteTeam = event.homeTeam;
                            moneylineOdds = homeMoneyline;
                          }
                        } else if (awayMoneyline != null) {
                          favoriteTeam = event.awayTeam;
                          moneylineOdds = awayMoneyline;
                        } else if (homeMoneyline != null) {
                          favoriteTeam = event.homeTeam;
                          moneylineOdds = homeMoneyline;
                        } else {
                          favoriteTeam = event.homeTeam;
                          moneylineOdds = null;
                        }
                        
                        final isSaved = controller.isEventSaved(
                          event.eventId,
                          bookmark.marketTitle,
                        );

                        // Get AI moneyline from bookmark - match with the displayed moneyline team
                        // If we're showing the favorite's moneyline, show the AI's prediction for that same team
                        String? aiPercentage;
                        if (favoriteTeam == event.awayTeam) {
                          // We're showing away team's moneyline, use away team's AI prediction
                          aiPercentage = (bookmark.aiMoneylineAway != null && bookmark.aiMoneylineAway != 'N/A') 
                              ? bookmark.aiMoneylineAway 
                              : event.aiPercentage;
                        } else {
                          // We're showing home team's moneyline, use home team's AI prediction
                          aiPercentage = (bookmark.aiMoneylineHome != null && bookmark.aiMoneylineHome != 'N/A') 
                              ? bookmark.aiMoneylineHome 
                              : event.aiPercentage;
                        }

                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: GestureDetector(
                            onTap: () {
                              Get.to(() => SportsCardDetailsScreen(
                                title: 'NBA Championship Odds 2026',
                                subtitle: '${event.awayTeam} vs ${event.homeTeam}',
                                date: formatPrettyDate(event.date),
                                marketPercentage: _formatMoneyline(moneylineOdds),
                                aiPercentage: aiPercentage ?? 'N/A',
                                team: favoriteTeam,
                                isFanduel: bookmark.marketTitle.toLowerCase() == 'fanduel',
                                bgColor: _getBgColor(bookmark.marketTitle),
                                eventId: event.eventId,
                                platform: bookmark.marketTitle,
                                awayTeam: event.awayTeam,
                                homeTeam: event.homeTeam,
                                spreadAway: h2hMarket.outcome.awayTeam?.american ?? '-',
                                spreadHome: h2hMarket.outcome.homeTeam?.american ?? '-',
                                moneylineAway: awayMoneyline ?? '-',
                                moneylineHome: homeMoneyline ?? '-',
                                totalOver: bookmark.market.firstWhere(
                                  (m) => m.key == 'totals',
                                  orElse: () => Market(id: 0, key: '', outcome: MarketOutcome(), bookmark: 0),
                                ).outcome.over?.american ?? '-',
                                totalUnder: bookmark.market.firstWhere(
                                  (m) => m.key == 'totals',
                                  orElse: () => Market(id: 0, key: '', outcome: MarketOutcome(), bookmark: 0),
                                ).outcome.under?.american ?? '-',
                                // Pass AI predictions from bookmark
                                aiSpreadAway: bookmark.aiSpreadAway,
                                aiSpreadHome: bookmark.aiSpreadHome,
                                aiMoneylineAway: bookmark.aiMoneylineAway,
                                aiMoneylineHome: bookmark.aiMoneylineHome,
                                aiTotalOver: bookmark.aiTotalOver,
                                aiTotalUnder: bookmark.aiTotalUnder,
                              ));
                            },
                            child: SportsBaseCard(
                              title: 'NBA Championship Odds 2026',
                              subtitle: '${event.awayTeam} vs ${event.homeTeam}',
                              date: formatPrettyDate(event.date),
                              marketPercentage: _formatMoneyline(moneylineOdds),
                              aiPercentage: aiPercentage,
                              team: favoriteTeam,
                              bgColor: _getBgColor(bookmark.marketTitle),
                              borderColor: AppColors.blue,
                              platform: bookmark.marketTitle,
                              iconAsset: _getIconAsset(bookmark.marketTitle),
                              initiallySaved: isSaved,
                              onSaved: () {
                                Get.snackbar(
                                  'Saved',
                                  'Event saved to your list',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.primary.withOpacity(0.9),
                                  colorText: Colors.white,
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                      
                      // Divider between events (except last one)
                      if (eventIndex < controller.sportsbookEvents.length - 1)
                        Divider(
                          color: Colors.grey.shade300,
                          thickness: 1.h,
                          height: 24.h,
                        ),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasText = controller.searchController.text.isNotEmpty;

    return Obx(() {
      final isSearching = controller.isSearching.value;
      return Container(
        height: 42.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(color: const Color(0xffE6E6E6)),
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 12.w),
              child: Image.asset('assets/icons/search.png', width: 20.w),
            ),
            Expanded(
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: isSearching ? 'Searching...' : 'Search',
                  border: InputBorder.none,
                ),
                onChanged: controller.onSearchQueryChanged,
              ),
            ),
            if (hasText && !isSearching)
              GestureDetector(
                onTap: controller.clearSearch,
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Icon(
                    Icons.clear,
                    size: 18.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            if (isSearching)
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  String _getIconAsset(String marketTitle) {
    // Use NBA logo for all sportsbooks
    return 'assets/images/NBA.png';
  }

  /// Format moneyline odds - remove '+' for positive values
  String _formatMoneyline(String? odds) {
    if (odds == null || odds == 'N/A') return 'N/A';
    // Remove '+' prefix for positive values
    if (odds.startsWith('+')) {
      return odds.substring(1);
    }
    return odds;
  }

  /// Build loading state widget
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48.w,
            height: 48.h,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3.w,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Loading events...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please wait',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState({
    required String message,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120.w,
              height: 120.h,
              fit: BoxFit.contain,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 32.h),
            Text(
              message,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 24.h),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build search result card
  Widget _buildSearchResultCard(SportsbookEvent event) {
    return Column(
      children: [
        ...event.bookmark.map((bookmark) {
          final moneylineOdds = controller.getMoneylineOdds(bookmark);
          final isSaved = controller.isEventSaved(
            event.eventId,
            bookmark.marketTitle,
          );

          // Get AI percentage from event
          final aiPercentage = event.aiPercentage;

          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: SportsBaseCard(
              title: 'NBA Championship Odds 2026',
              subtitle: '${event.awayTeam} vs ${event.homeTeam}',
              date: formatPrettyDate(event.date),
              marketPercentage: _formatMoneyline(moneylineOdds),
              aiPercentage: aiPercentage,
              team: event.homeTeam,
              bgColor: _getBgColor(bookmark.marketTitle),
              borderColor: AppColors.blue,
              platform: bookmark.marketTitle,
              iconAsset: _getIconAsset(bookmark.marketTitle),
              initiallySaved: isSaved,
              onSaved: () {
                Get.snackbar(
                  'Saved',
                  'Event saved to your list',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.primary.withOpacity(0.9),
                  colorText: Colors.white,
                );
              },
            ),
          );
        }).toList(),
      ],
    );
  }
}
