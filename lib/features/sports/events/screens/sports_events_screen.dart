import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';
import 'package:murchin/features/sports/controllers/nba_finals_odds_controller.dart';
import 'package:murchin/features/sports/events/screens/nba_finals_details_screen.dart';
import 'package:murchin/features/sports/home/controllers/sports_home_controller.dart';
import 'package:murchin/features/sports/home/widgets/draftkings_card.dart';
import 'package:murchin/features/sports/home/widgets/fanduel_card.dart';
import 'package:murchin/features/sports/home/widgets/sports_card_details_screen.dart';
import 'package:murchin/features/sports/home/widgets/sports_comparison_tab.dart';

class SportsEventsScreen extends StatefulWidget {
  const SportsEventsScreen({super.key});

  @override
  State<SportsEventsScreen> createState() => _SportsEventsScreenState();
}

class _SportsEventsScreenState extends State<SportsEventsScreen> {
  final SportsEventsController controller = Get.put(SportsEventsController());
  late final SportsHomeController sportsController;
  late final NbaFinalsOddsController nbaFinalsController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Get or create controllers
    if (Get.isRegistered<SportsHomeController>()) {
      sportsController = Get.find<SportsHomeController>();
    } else {
      sportsController = Get.put(SportsHomeController());
    }
    
    if (Get.isRegistered<NbaFinalsOddsController>()) {
      nbaFinalsController = Get.find<NbaFinalsOddsController>();
    } else {
      nbaFinalsController = Get.put(NbaFinalsOddsController(), permanent: true);
    }
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more NBA Odds events when scrolling near bottom
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !sportsController.isRefreshing.value &&
        sportsController.nextPageUrl != null &&
        selectedCategoryIndex == 0) { // Only for NBA Odds category
      print('=== Scroll pagination triggered ===');
      sportsController.loadMoreSportsbookEvents();
    }
  }

  final Color unselectedBgColor = const Color(0xFF8D9AB1);
  final Color fanduelBgColor = const Color(0xFF559CEE);
  final Color draftkingsBgColor = const Color(0xFF218B28);
  final Color betmgmBgColor = const Color(0xFFA79D2C);

  final List<String> platformTabs = ['All Platform', 'Draftkings', 'Fanduel', 'BetMGM'];
  final List<String> categoryTabs = ['NBA Odds', 'NBA Finals'];
  int selectedCategoryIndex = 0;

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
            child: _buildPlatformTabs(),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildCategoryTabs(),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: Obx(() {
              // Watch sportsController's selectedPlatform for NBA Odds category
              final _ = sportsController.selectedPlatform.value;

              return GetBuilder<NbaFinalsOddsController>(
                builder: (nbaController) {
                  // Check if NBA Finals category is selected
                  final isNbaFinalsCategory = selectedCategoryIndex == 1;

                  // Reload events when GetBuilder rebuilds (after AI predictions loaded)
                  if (isNbaFinalsCategory) {
                    controller.loadEventsForCurrentSelection();
                  }

                  // Also watch betmgmEvents, selectedPlatform, events lists to trigger rebuilds
                  controller.selectedPlatform.value;
                  controller.events.length;
                  controller.draftkingsEvents.length;

                  // Loading state for NBA Odds
                  if (!isNbaFinalsCategory) {
                    if (sportsController.isLoading.value && sportsController.sportsbookEvents.isEmpty) {
                      return _buildLoadingState();
                    }

                    // Empty state for NBA Odds
                    if (sportsController.sportsbookEvents.isEmpty && !sportsController.isLoading.value) {
                      return _buildEmptyState(
                        message: 'No data available',
                        subtitle: 'Please check back later',
                        actionLabel: 'Retry',
                        onAction: () {
                          sportsController.fetchSportsbookEvents();
                        },
                      );
                    }
                  }

                  // Loading state for NBA Finals
                  if (isNbaFinalsCategory) {
                    if (nbaFinalsController.isLoading.value &&
                        controller.events.isEmpty &&
                        controller.draftkingsEvents.isEmpty &&
                        controller.betmgmEvents.isEmpty) {
                      return _buildLoadingState();
                    }

                    // Empty state for NBA Finals
                    final hasNbaFinalsData = controller.events.any((e) => e['is_nba_finals'] == true) ||
                        controller.draftkingsEvents.any((e) => e['is_nba_finals'] == true) ||
                        controller.betmgmEvents.any((e) => e['is_nba_finals'] == true);

                    if (!hasNbaFinalsData && !nbaFinalsController.isLoading.value) {
                      return _buildEmptyState(
                        message: 'No data available',
                        subtitle: 'Please check back later',
                        actionLabel: 'Retry',
                        onAction: () {
                          nbaFinalsController.fetchNbaFinalsOdds('FanDuel');
                          nbaFinalsController.fetchNbaFinalsOdds('DraftKings');
                          nbaFinalsController.fetchNbaFinalsOdds('BetMGM');
                        },
                      );
                    }
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 8.h),
                    itemCount: (isNbaFinalsCategory ? _buildNbaFinalsCards() : _buildSportsbookCards()).length + (isNbaFinalsCategory ? 0 : 2),
                    itemBuilder: (context, index) {
                      final cards = isNbaFinalsCategory ? _buildNbaFinalsCards() : _buildSportsbookCards();

                      // Featured card for NBA Odds
                      if (!isNbaFinalsCategory && index == 0) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: _buildFeaturedCard(),
                        );
                      }

                      // Adjust index for NBA Odds (skip featured card)
                      final cardIndex = isNbaFinalsCategory ? index : index - 1;

                      if (cardIndex < cards.length) {
                        return cards[cardIndex];
                      } else {
                        // Loading indicator for pagination
                        if ((isNbaFinalsCategory && nbaFinalsController.isRefreshing.value) ||
                            (!isNbaFinalsCategory && sportsController.isRefreshing.value)) {
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
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(platformTabs.length, (index) {
        return Obx(() {
          final isSelected = controller.selectedPlatform.value == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                controller.selectPlatform(index);
                sportsController.selectPlatform(index);
              },
              child: Container(
                height: 29.h,
                margin: EdgeInsets.only(right: index < platformTabs.length - 1 ? 8.w : 0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : unselectedBgColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    platformTabs[index],
                    style: AppTextStyles.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      }),
    );
  }

  Widget _buildCategoryTabs() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 40.h,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(categoryTabs.length, (index) {
              final isSelected = selectedCategoryIndex == index;
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategoryIndex = index;
                      controller.selectCategory(categoryTabs[index]);
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                        child: Text(
                          categoryTabs[index],
                          style: AppTextStyles.bodyMedium?.copyWith(
                            color: isSelected ? Colors.black : AppColors.gray600,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 30.w,
                          height: 2.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(1.r),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Obx(() {
      final events = _getCurrentEvents();
      if (events.isEmpty) {
        return const SizedBox.shrink();
      }

      final featuredEvent = events.first;
      final isFanduel = featuredEvent['marketPlace'] == 'Fanduel';
      final bgColor = isFanduel ? fanduelBgColor : draftkingsBgColor;

      return Container(
        width: double.infinity,
        height: 123.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          image: const DecorationImage(
            image: AssetImage('assets/images/gradient_bg2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    featuredEvent['title'] ?? 'Featured Event',
                    style: AppTextStyles.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    featuredEvent['subtitle'] ?? '',
                    style: AppTextStyles.bodyMedium?.copyWith(
                      color: Colors.white.withAlpha(200),
                      fontWeight: FontWeight.w400,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    formatPrettyDate(featuredEvent['endDate'] ?? ''),
                    style: AppTextStyles.bodySmall?.copyWith(
                      color: Colors.white.withAlpha(200),
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      isFanduel ? 'Fanduel' : 'Draftkings',
                      style: AppTextStyles.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
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
            style: AppTextStyles.bodyLarge?.copyWith(
              color: AppColors.gray600,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please wait',
            style: AppTextStyles.bodyMedium?.copyWith(
              color: AppColors.gray500,
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
              color: AppColors.gray400,
            ),
            SizedBox(height: 32.h),
            Text(
              message,
              style: AppTextStyles.bodyLarge?.copyWith(
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
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: AppColors.gray600,
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
                    style: AppTextStyles.bodyMedium?.copyWith(
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

  List<Map<String, dynamic>> _getCurrentEvents() {
    final platform = controller.selectedPlatform.value;
    print('=== _getCurrentEvents: platform=$platform ===');
    if (platform == 1) {
      // Index 1 = Draftkings
      print('Returning ${controller.draftkingsEvents.length} DraftKings events');
      return controller.draftkingsEvents;
    } else if (platform == 2) {
      // Index 2 = Fanduel
      print('Returning ${controller.events.length} FanDuel events');
      return controller.events;
    } else if (platform == 3) {
      // Index 3 = BetMGM
      print('Returning ${controller.betmgmEvents.length} BetMGM events');
      return controller.betmgmEvents;
    } else {
      // Index 0 = All Platform
      final all = [...controller.draftkingsEvents, ...controller.events, ...controller.betmgmEvents];
      print('Returning ${all.length} All Platform events (DK:${controller.draftkingsEvents.length}, FD:${controller.events.length}, MGM:${controller.betmgmEvents.length})');
      return all;
    }
  }

  /// Get NBA Finals events based on platform selection
  List<Map<String, dynamic>> _getCurrentNbaFinalsEvents() {
    final platform = controller.selectedPlatform.value;
    if (platform == 1) {
      return [controller.draftkingsEvents.firstWhere((e) => e['is_nba_finals'] == true, orElse: () => {})];
    } else if (platform == 2) {
      return [controller.events.firstWhere((e) => e['is_nba_finals'] == true, orElse: () => {})];
    } else if (platform == 3) {
      return [controller.betmgmEvents.firstWhere((e) => e['is_nba_finals'] == true, orElse: () => {})];
    } else {
      // All platforms
      final all = <Map<String, dynamic>>[];
      final fanduel = controller.events.firstWhere((e) => e['is_nba_finals'] == true, orElse: () => {});
      final draftkings = controller.draftkingsEvents.firstWhere((e) => e['is_nba_finals'] == true, orElse: () => {});
      final betmgm = controller.betmgmEvents.firstWhere((e) => e['is_nba_finals'] == true, orElse: () => {});
      if (fanduel.isNotEmpty) all.add(fanduel);
      if (draftkings.isNotEmpty) all.add(draftkings);
      if (betmgm.isNotEmpty) all.add(betmgm);
      return all;
    }
  }

  /// Get sportsbook events based on platform selection
  List<dynamic> _getCurrentSportsbookEvents() {
    final platform = sportsController.selectedPlatform.value;
    final events = sportsController.sportsbookEvents;
    
    if (platform == 0) {
      // All platforms - return all events with all bookmarks
      return events;
    } else {
      // Filter by specific platform
      final platformName = platform == 1 ? 'DraftKings' : platform == 2 ? 'FanDuel' : 'BetMGM';
      return events;
    }
  }

  /// Build NBA Finals cards
  List<Widget> _buildNbaFinalsCards() {
    // Read directly from controller to get latest AI predictions
    final fanduelTeam = nbaFinalsController?.getLowestOddsTeam('FanDuel');
    final draftkingsTeam = nbaFinalsController?.getLowestOddsTeam('DraftKings');
    final betmgmTeam = nbaFinalsController?.getLowestOddsTeam('BetMGM');

    final List<Widget> cards = [];

    // FanDuel card
    if (fanduelTeam != null) {
      final aiPrediction = fanduelTeam.aiPrediction;
      final isLoadingAi = aiPrediction == null;

      cards.add(
        Padding(
          padding: EdgeInsets.only(bottom: 20.h),
          child: FanduelCard(
            eventId: '3',
            title: '2025-26 NBA Finals Winner',
            subtitle: '',
            date: formatPrettyDate(fanduelTeam.date),
            marketPercentage: fanduelTeam.price,
            aiPercentage: isLoadingAi ? null : aiPrediction,
            team: fanduelTeam.teamName,
            bgColor: fanduelBgColor,
            borderColor: fanduelBgColor,
            platform: 'FanDuel',
            isSaved: false,
            customOnTap: () {
              Get.to(() => NbaFinalsDetailsScreen(
                platform: 'FanDuel',
                bgColor: fanduelBgColor,
              ));
            },
          ),
        ),
      );
    }

    // DraftKings card
    if (draftkingsTeam != null) {
      final aiPrediction = draftkingsTeam.aiPrediction;
      final isLoadingAi = aiPrediction == null;

      cards.add(
        Padding(
          padding: EdgeInsets.only(bottom: 20.h),
          child: DraftkingsCard(
            eventId: 'dk3',
            title: '2025-26 NBA Finals Winner',
            subtitle: '',
            date: formatPrettyDate(draftkingsTeam.date),
            marketPercentage: draftkingsTeam.price,
            aiPercentage: isLoadingAi ? null : aiPrediction,
            team: draftkingsTeam.teamName,
            bgColor: draftkingsBgColor,
            borderColor: draftkingsBgColor,
            platform: 'DraftKings',
            isSaved: false,
            customOnTap: () {
              Get.to(() => NbaFinalsDetailsScreen(
                platform: 'DraftKings',
                bgColor: draftkingsBgColor,
              ));
            },
          ),
        ),
      );
    }

    // BetMGM card
    if (betmgmTeam != null) {
      final aiPrediction = betmgmTeam.aiPrediction;
      final isLoadingAi = aiPrediction == null;

      cards.add(
        Padding(
          padding: EdgeInsets.only(bottom: 20.h),
          child: DraftkingsCard(
            eventId: 'mgm3',
            title: '2025-26 NBA Finals Winner',
            subtitle: '',
            date: formatPrettyDate(betmgmTeam.date),
            marketPercentage: betmgmTeam.price,
            aiPercentage: isLoadingAi ? null : aiPrediction,
            team: betmgmTeam.teamName,
            bgColor: betmgmBgColor,
            borderColor: betmgmBgColor,
            platform: 'BetMGM',
            isSaved: false,
            customOnTap: () {
              Get.to(() => NbaFinalsDetailsScreen(
                platform: 'BetMGM',
                bgColor: betmgmBgColor,
              ));
            },
          ),
        ),
      );
    }

    return cards;
  }

  /// Build sportsbook cards for NBA Odds
  List<Widget> _buildSportsbookCards() {
    final platform = sportsController.selectedPlatform.value;
    final events = sportsController.sportsbookEvents;

    final List<Widget> cards = [];

    for (var event in events) {
      for (var bookmark in event.bookmark) {
        final marketPlace = bookmark.marketTitle;

        // Filter by platform if specific platform is selected
        if (platform != 0) {
          final platformName = platform == 1 ? 'DraftKings' : platform == 2 ? 'FanDuel' : 'BetMGM';
          if (marketPlace.toLowerCase() != platformName.toLowerCase()) continue;
        }

        // Get H2H moneyline odds and determine which team is the favorite
        final h2hMarket = bookmark.market.firstWhere((m) => m.key == 'h2h', orElse: () => bookmark.market.first);
        final awayMoneyline = h2hMarket.outcome.awayTeam?.american;
        final homeMoneyline = h2hMarket.outcome.homeTeam?.american;
        
        // Determine the favorite (lowest american value) and show that team
        String favoriteTeam;
        String? moneylineOdds;
        
        if (awayMoneyline != null && homeMoneyline != null) {
          final awayValue = int.tryParse(awayMoneyline) ?? 0;
          final homeValue = int.tryParse(homeMoneyline) ?? 0;
          
          if (awayValue < homeValue) {
            // Away team is favorite (lower value)
            favoriteTeam = event.awayTeam;
            moneylineOdds = awayMoneyline;
          } else {
            // Home team is favorite (lower value)
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

        final isFanduel = marketPlace.toLowerCase() == 'fanduel';
        final isBetMgm = marketPlace.toLowerCase() == 'betmgm';

        Color bgColor;
        Color borderColor;

        if (isFanduel) {
          bgColor = fanduelBgColor;
          borderColor = fanduelBgColor;
        } else if (isBetMgm) {
          bgColor = betmgmBgColor;
          borderColor = betmgmBgColor;
        } else {
          bgColor = draftkingsBgColor;
          borderColor = draftkingsBgColor;
        }

        // Custom onTap for navigating to details screen
        final customOnTap = () {
          // Find h2h, spreads, and totals markets
          final h2hMarket = bookmark.market.firstWhere((m) => m.key == 'h2h', orElse: () => bookmark.market.first);
          final spreadsMarket = bookmark.market.firstWhere((m) => m.key == 'spreads', orElse: () => bookmark.market.first);
          final totalsMarket = bookmark.market.firstWhere((m) => m.key == 'totals', orElse: () => bookmark.market.first);
          
          // Get moneyline odds
          final awayMoneyline = h2hMarket.outcome.awayTeam?.american ?? '-';
          final homeMoneyline = h2hMarket.outcome.homeTeam?.american ?? '-';
          
          // Get spread odds (american values)
          final awaySpread = spreadsMarket.outcome.awayTeam?.american ?? '-';
          final homeSpread = spreadsMarket.outcome.homeTeam?.american ?? '-';
          
          // Get total values (just american odds, no points)
          final overTotal = totalsMarket.outcome.over?.american ?? '-';
          final underTotal = totalsMarket.outcome.under?.american ?? '-';
          
          Get.to(() => SportsCardDetailsScreen(
            title: 'NBA Championship Odds 2026',
            subtitle: '${event.awayTeam} vs ${event.homeTeam}',
            date: sportsController.formatPrettyDate(event.date),
            marketPercentage: _formatMoneyline(moneylineOdds),
            aiPercentage: 'N/A',
            team: favoriteTeam,
            isFanduel: isFanduel,
            bgColor: bgColor,
            eventId: event.eventId,
            platform: marketPlace,
            awayTeam: event.awayTeam,
            homeTeam: event.homeTeam,
            spreadAway: awaySpread,
            spreadHome: homeSpread,
            moneylineAway: awayMoneyline,
            moneylineHome: homeMoneyline,
            totalOver: overTotal,
            totalUnder: underTotal,
          ));
        };

        cards.add(
          Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: GestureDetector(
              onTap: customOnTap,
              child: _buildSportsbookOnlyCard(
                title: 'NBA Championship Odds 2026',
                subtitle: '${event.awayTeam} vs ${event.homeTeam}',
                date: sportsController.formatPrettyDate(event.date),
                marketPercentage: _formatMoneyline(moneylineOdds),
                team: favoriteTeam,
                bgColor: bgColor,
                borderColor: borderColor,
                platform: marketPlace,
                iconAsset: 'assets/images/NBA.png',
                isSaved: false,
              ),
            ),
          ),
        );
      }
    }

    return cards;
  }

  /// Build card with only sportsbook value (no AI section)
  Widget _buildSportsbookOnlyCard({
    required String title,
    required String subtitle,
    required String date,
    required String marketPercentage,
    required String team,
    required Color bgColor,
    required Color borderColor,
    required String platform,
    required String iconAsset,
    required bool isSaved,
  }) {
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
              Image.asset(iconAsset, width: 44.w, height: 44.h),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(subtitle,
                          style: AppTextStyles.bodyMedium?.copyWith(
                            color: const Color(0xff848484),
                            fontWeight: FontWeight.w400,
                            fontSize: 14.sp,
                          )),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Get.snackbar(
                    'Saved',
                    'Event saved to your list',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.primary.withOpacity(0.9),
                    colorText: Colors.white,
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  child: Image.asset(
                    isSaved
                        ? 'assets/icons/bookmark_active.png'
                        : 'assets/icons/bookmark.png',
                    width: 20.w,
                    height: 20.h,
                  ),
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
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: borderColor, width: 1.w),
                ),
                child: Text(platform,
                    style: AppTextStyles.bodySmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp,
                        color: const Color(0xff848484))),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Only show Sportsbook section (full width, no AI section)
          Row(
            children: [
              Expanded(
                child: SportsComparisonTab(
                  title: 'Sportsbook',
                  percentage: marketPercentage,
                  team: team,
                  percentageColor: const Color(0xff4588C6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format moneyline odds - remove '+' for positive values
  String _formatMoneyline(String? odds) {
    if (odds == null || odds == 'N/A') return 'N/A';
    if (odds.startsWith('+')) {
      return odds.substring(1);
    }
    return odds;
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
}

class SportsEventsController extends GetxController {
  final selectedPlatform = 0.obs;
  final selectedCategory = 'NBA Odds'.obs;
  final isLoading = false.obs;

  final RxList<Map<String, dynamic>> _events = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _draftkingsEvents = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _betmgmEvents = <Map<String, dynamic>>[].obs;

  List<Map<String, dynamic>> get events => _events;
  List<Map<String, dynamic>> get draftkingsEvents => _draftkingsEvents;
  List<Map<String, dynamic>> get betmgmEvents => _betmgmEvents;

  final Set<int> _savedFanduelEventIds = <int>{};

  // NBA Finals Controller reference
  NbaFinalsOddsController? nbaFinalsController;

  @override
  void onInit() {
    super.onInit();
    // Ensure NBA Finals controller is initialized and permanent
    if (Get.isRegistered<NbaFinalsOddsController>()) {
      nbaFinalsController = Get.find<NbaFinalsOddsController>();
    } else {
      nbaFinalsController = Get.put(NbaFinalsOddsController(), permanent: true);
    }
    loadStaticData();
  }

  void selectPlatform(int index) {
    selectedPlatform.value = index;
    // Don't reset category - preserve user's current selection
    loadEventsForCurrentSelection();
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    loadEventsForCurrentSelection();
  }

  void loadEventsForCurrentSelection() {
    final platform = selectedPlatform.value;
    final category = selectedCategory.value;

    // Clear all lists first
    _events.clear();
    _draftkingsEvents.clear();
    _betmgmEvents.clear();

    if (platform == 0 || platform == 2) {
      // Index 2 = Fanduel
      if (category == 'NBA Odds') {
        _loadFanduelNbaOdds();
      } else {
        _loadFanduelNbaFinals();
      }
    }
    if (platform == 0 || platform == 1) {
      // Index 1 = Draftkings
      if (category == 'NBA Odds') {
        _loadDraftkingsNbaOdds();
      } else {
        _loadDraftkingsNbaFinals();
      }
    }
    if (platform == 0 || platform == 3) {
      // Index 3 = BetMGM
      if (category == 'NBA Odds') {
        _loadBetMgmNbaOdds();
      } else {
        _loadBetMgmNbaFinals();
      }
    }
  }

  void loadStaticData() {
    loadEventsForCurrentSelection();
  }

  void _loadFanduelNbaOdds() {
    _events.assignAll([
      {
        'event_id': 1,
        'title': 'NBA Championship Odds 2026',
        'subtitle': 'Thunder Vs Pistons',
        'endDate': '2026-06-15T00:00:00',
        'marketPercentage': '700',
        'aiPercentage': '850',
        'team': 'Thunder',
        'marketPlace': 'Fanduel',
      },
      {
        'event_id': 2,
        'title': 'NBA Championship Odds 2026',
        'subtitle': 'Celtics Vs Lakers',
        'endDate': '2026-06-15T00:00:00',
        'marketPercentage': '600',
        'aiPercentage': '550',
        'team': 'Celtics',
        'marketPlace': 'Fanduel',
      },
    ]);
  }

  void _loadFanduelNbaFinals() {
    // Get the team with lowest odds from API
    final lowestTeam = nbaFinalsController?.getLowestOddsTeam('FanDuel');

    if (lowestTeam != null) {
      // Get AI prediction from the updated odds in controller
      final aiPrediction = lowestTeam.aiPrediction;
      final isLoadingAi = aiPrediction == null;
      
      print('=== _loadFanduelNbaFinals: team=${lowestTeam.teamName}, aiPrediction=$aiPrediction, isLoadingAi=$isLoadingAi ===');

      _events.assignAll([
        {
          'event_id': 3,
          'title': '2025-26 NBA Finals Winner',
          'subtitle': '',
          'endDate': lowestTeam.date,
          'marketPercentage': lowestTeam.price,
          'aiPercentage': isLoadingAi ? null : aiPrediction,
          'team': lowestTeam.teamName,
          'marketPlace': 'FanDuel',
          'is_nba_finals': true,
          'platform': 'FanDuel',
        },
      ]);
    } else {
      _events.clear();
    }
  }

  void _loadDraftkingsNbaOdds() {
    _draftkingsEvents.assignAll([
      {
        'event_id': 'dk1',
        'title': 'NBA Championship Odds 2026',
        'subtitle': 'Warriors Vs Suns',
        'endDate': '2026-06-15T00:00:00',
        'marketPercentage': '750',
        'aiPercentage': '800',
        'team': 'Warriors',
        'marketPlace': 'Draftkings',
      },
      {
        'event_id': 'dk2',
        'title': 'NBA Championship Odds 2026',
        'subtitle': 'Bucks Vs 76ers',
        'endDate': '2026-06-15T00:00:00',
        'marketPercentage': '650',
        'aiPercentage': '700',
        'team': 'Bucks',
        'marketPlace': 'Draftkings',
      },
    ]);
  }

  void _loadDraftkingsNbaFinals() {
    // Get the team with lowest odds from API
    final lowestTeam = nbaFinalsController?.getLowestOddsTeam('DraftKings');

    if (lowestTeam != null) {
      // Get AI prediction from the updated odds in controller
      final aiPrediction = lowestTeam.aiPrediction;
      final isLoadingAi = aiPrediction == null;

      _draftkingsEvents.assignAll([
        {
          'event_id': 'dk3',
          'title': '2025-26 NBA Finals Winner',
          'subtitle': '',
          'endDate': lowestTeam.date,
          'marketPercentage': lowestTeam.price,
          'aiPercentage': isLoadingAi ? null : aiPrediction,
          'team': lowestTeam.teamName,
          'marketPlace': 'DraftKings',
          'is_nba_finals': true,
          'platform': 'DraftKings',
        },
      ]);
    } else {
      _draftkingsEvents.clear();
    }
  }

  void _loadBetMgmNbaOdds() {
    _betmgmEvents.assignAll([
      {
        'event_id': 'mgm1',
        'title': 'NBA Championship Odds 2026',
        'subtitle': 'Heat Vs Mavericks',
        'endDate': '2026-06-15T00:00:00',
        'marketPercentage': '900',
        'aiPercentage': '950',
        'team': 'Heat',
        'marketPlace': 'BetMGM',
      },
      {
        'event_id': 'mgm2',
        'title': 'NBA Championship Odds 2026',
        'subtitle': 'Nuggets Vs Clippers',
        'endDate': '2026-06-15T00:00:00',
        'marketPercentage': '800',
        'aiPercentage': '850',
        'team': 'Nuggets',
        'marketPlace': 'BetMGM',
      },
    ]);
  }

  void _loadBetMgmNbaFinals() {
    // Get the team with lowest odds from API
    final lowestTeam = nbaFinalsController?.getLowestOddsTeam('BetMGM');
    print('=== _loadBetMgmNbaFinals: lowestTeam = ${lowestTeam?.teamName ?? "null"} ===');

    if (lowestTeam != null) {
      // Get AI prediction from the updated odds in controller
      final aiPrediction = lowestTeam.aiPrediction;
      final isLoadingAi = aiPrediction == null;

      _betmgmEvents.assignAll([
        {
          'event_id': 'mgm3',
          'title': '2025-26 NBA Finals Winner',
          'subtitle': '',
          'endDate': lowestTeam.date,
          'marketPercentage': lowestTeam.price,
          'aiPercentage': isLoadingAi ? null : aiPrediction,
          'team': lowestTeam.teamName,
          'marketPlace': 'BetMGM',
          'is_nba_finals': true,
          'platform': 'BetMGM',
        },
      ]);
      print('=== BetMGM NBA Finals event loaded with ${_betmgmEvents.length} items ===');
    } else {
      _betmgmEvents.clear();
      print('=== BetMGM NBA Finals: No lowest team found, clearing events ===');
    }
  }

  bool isEventSaved(int eventId) => _savedFanduelEventIds.contains(eventId);

  void saveEvent({required int eventId}) {
    if (_savedFanduelEventIds.contains(eventId)) {
      _savedFanduelEventIds.remove(eventId);
    } else {
      _savedFanduelEventIds.add(eventId);
    }
  }
}
