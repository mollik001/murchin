// lib/features/market/events/screens/event_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';
import 'package:murchin/features/market/home/controllers/home_controller.dart';
import 'package:murchin/features/market/home/screens/card_details_screen.dart';
import 'package:shimmer/shimmer.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final EventsController controller = Get.put(EventsController());
  late final HomeController homeController;
  final ScrollController _scrollController = ScrollController();

  final Color unselectedBgColor = const Color(0xFF8D9AB1);
  final Color polymarketBgColor = AppColors.polymarketColor;
  final Color kalshiBgColor = AppColors.kalshiCardBg;

  @override
  void initState() {
    super.initState();
    // Get or create HomeController
    if (Get.isRegistered<HomeController>()) {
      homeController = Get.find<HomeController>();
    } else {
      homeController = Get.put(HomeController());
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final platform = controller.selectedPlatform.value;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    print('=== Scroll Debug ===');
    print('Platform: $platform');
    print('Current scroll: $currentScroll');
    print('Max scroll: $maxScroll');
    print('Threshold: ${maxScroll - 200}');
    print('Polymarket next: ${controller.polymarketNextPageUrl}');
    print('Kalshi next: ${controller.kalshiNextPageUrl}');
    print('Polymarket loading: ${controller.isPolymarketLoading.value}');
    print('Kalshi loading: ${controller.isKalshiLoading.value}');

    if (currentScroll >= maxScroll - 200) {
      print('Triggering load more!');
      // Load more from both APIs when in "All" tab (platform == 0)
      if ((platform == 0 || platform == 1) && !controller.isPolymarketLoading.value) {
        print('Loading Polymarket next page');
        controller.loadPolymarketNextPage();
      }
      if ((platform == 0 || platform == 2) && !controller.isKalshiLoading.value) {
        print('Loading Kalshi next page');
        controller.loadKalshiNextPage();
      }
    }
  }

  Widget _buildSearchBar() {
    return Obx(() {
      final hasText = homeController.searchController.text.isNotEmpty;
      final isSearching = homeController.isSearching.value;
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
                controller: homeController.searchController,
                decoration: InputDecoration(
                  hintText: isSearching ? 'Searching...' : 'Search',
                  border: InputBorder.none,
                ),
                onChanged: homeController.onSearchQueryChanged,
              ),
            ),
            if (hasText)
              GestureDetector(
                onTap: homeController.clearSearch,
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Icon(
                    Icons.clear,
                    size: 18.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Map<String, dynamic> _buildFilteredOptions(Map<String, dynamic> e) {
    List<String> filteredOptions = [];
    List<double> filteredMarketProbs = [];
    List<int> originalIndices = [];

    final optionTitles = e['optionTitles'] as List<dynamic>? ?? [];
    final marketProbs = e['marketProbs'] as List<dynamic>? ?? [];

    for (int j = 0; j < optionTitles.length && j < marketProbs.length; j++) {
      final marketProb = marketProbs[j] is double ? marketProbs[j] as double : double.tryParse(marketProbs[j].toString()) ?? 0;
      if (marketProb <= 0) continue;
      filteredOptions.add(optionTitles[j].toString());
      filteredMarketProbs.add(marketProb);
      originalIndices.add(j);
    }

    String highestMarketTeam = e['team'] ?? '';
    int highestMarketIndex = filteredOptions.indexOf(highestMarketTeam);

    if (highestMarketIndex != -1 && highestMarketIndex != 0) {
      final topOption = filteredOptions.removeAt(highestMarketIndex);
      final topProb = filteredMarketProbs.removeAt(highestMarketIndex);
      final topIndex = originalIndices.removeAt(highestMarketIndex);

      filteredOptions.insert(0, topOption);
      filteredMarketProbs.insert(0, topProb);
      originalIndices.insert(0, topIndex);
    }

    return {
      "options": filteredOptions,
      "marketProbs": filteredMarketProbs,
      "originalIndices": originalIndices,
    };
  }

  List<String> get categories {
    final selectedPlatform = controller.selectedPlatform.value;
    if (selectedPlatform == 1) {
      return [
        'Trending',
        'Politics',
        'Sports',
        'Crypto',
        'Finance',
        'Geopolitics',
        'Tech',
        'Culture',
        'World',
        'Economy',
        'Climate & Science',
      ];
    } else if (selectedPlatform == 2) {
      return [
        'Trending',
        'Politics',
        'Sports',
        'Culture',
        'Crypto',
        'Climate',
        'Economics',
        'Companies',
        'Financials',
        'Tech & Science',
      ];
    } else {
      return [
        'Trending',
        'Politics',
        'Sports',
        'Culture',
        'Crypto',
        'Climate',
        'Climate & Science',
        'Economics',
        'Companies',
        'Financials',
        'Tech & Science',
        'Finance',
        'Geopolitics',
        'Tech',
        'World',
        'Economy',
      ];
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(imageAsset: 'assets/images/name_2.png'),
      body: Column(
        children: [
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildSearchBar(),
          ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                _buildSeparatePlatformTabs(),
                SizedBox(height: 10.h),
                _buildCategoriesRow(),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: Obx(() {
              // Check if there's an active search
              if (homeController.isSearching.value) {
                // Show search results
                final searchResults = homeController.events;
                
                if (searchResults.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo_2.jpg',
                            width: 120.w,
                            height: 120.h,
                            fit: BoxFit.contain,
                            color: AppColors.gray400,
                          ),
                          SizedBox(height: 32.h),
                          Text(
                            'No search results found',
                            style: AppTextStyles.bodyLarge?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 18.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Try a different search term',
                            style: AppTextStyles.bodyMedium?.copyWith(
                              color: AppColors.gray600,
                              fontSize: 14.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          GestureDetector(
                            onTap: homeController.clearSearch,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 32.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              child: Text(
                                'Clear Search',
                                style: AppTextStyles.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final event = searchResults[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: _buildSearchResultCard(event),
                    );
                  },
                );
              }

              if (controller.isLoading.value && controller.events.isEmpty && controller.kalshiEvents.isEmpty) {
                // Show loading state
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60.w,
                        height: 60.h,
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

              // Check if data loaded but no events to show for the selected platform
              final isNotLoading = !controller.isLoading.value;
              final platform = controller.selectedPlatform.value;
              final hasNoEvents = platform == 1 
                  ? controller.events.isEmpty  // Polymarket tab
                  : platform == 2 
                      ? controller.kalshiEvents.isEmpty  // Kalshi tab
                      : controller.events.isEmpty && controller.kalshiEvents.isEmpty;  // All tab
              
              if (isNotLoading && hasNoEvents) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () => controller.refreshEvents(),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification) {
                      _onScroll();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        _buildFeaturedCard(),
                        SizedBox(height: 24.h),
                        _buildCardsList(),
                        if (controller.isPolymarketLoading.value ||
                            controller.isKalshiLoading.value)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child:
                                Center(child: CircularProgressIndicator()),
                          ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> event) {
    final isKalshi = event['market_place'] == 'Kalshi';
    final marketPercent =
        double.tryParse(event['marketPercentage']?.replaceAll('%', '') ?? '0') ??
            0;
    final marketPercentDecimal = marketPercent / 100;

    return GestureDetector(
      onTap: () => _navigateToDetail(event),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.gray300 ?? Colors.grey[300]!,
            width: 1.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPlatformTag(isKalshi),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 24.w,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              event['title'] ?? '',
              style: AppTextStyles.bodyLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Top pick : ${event['team'] ?? 'N/A'}',
              style: AppTextStyles.bodySmall?.copyWith(
                color: const Color(0xffDC732D),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market : ${event['marketPercentage'] ?? '0%'}',
                  style: AppTextStyles.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                _buildMarketSlider(marketPercentDecimal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeparatePlatformTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSeparateTab(0, 'All'),
        SizedBox(width: 8.w),
        _buildSeparateTab(1, 'Polymarket'),
        SizedBox(width: 8.w),
        _buildSeparateTab(2, 'Kalshi'),
      ],
    );
  }

  Widget _buildSeparateTab(int index, String text) {
    return Obx(() {
      final isSelected = controller.selectedPlatform.value == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => controller.selectPlatform(index),
          child: Container(
            height: 29.h,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : unselectedBgColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCategoriesRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Obx(() {
        final currentCategories = categories;
        final selectedCategory = controller.selectedCategory.value;

        return Row(
          children: currentCategories.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: GestureDetector(
                onTap: () => controller.selectCategory(category),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                      child: Text(
                        category,
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
          }).toList(),
        );
      }),
    );
  }

  Widget _buildFeaturedCard() {
    return Obx(() {
      final events = _getCurrentEvents();
      
      // Show shimmer loading state while data is loading
      if (events.isEmpty && controller.isLoading.value) {
        return _buildFeaturedCardShimmer();
      }
      
      if (events.isEmpty) {
        return const SizedBox.shrink();
      }

      final featuredEvent = events.first;
      final isKalshi = featuredEvent['market_place'] == 'Kalshi';

      return GestureDetector(
        onTap: () => _navigateToDetail(featuredEvent),
        child: Container(
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
                Row(
                  children: [
                    Text(
                      formatPrettyDate(featuredEvent['endDate'] ?? ''),
                      style: AppTextStyles.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward,
                      size: 16.w,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFeaturedCardShimmer() {
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
            Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 200.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: 120.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
            Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.5),
              child: Row(
                children: [
                  Container(
                    width: 80.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 24.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state widget for when no events are available
  Widget _buildEmptyState() {
    final platform = controller.selectedPlatform.value;
    final category = controller.selectedCategory.value;
    
    String platformText = 'All Platforms';
    if (platform == 1) {
      platformText = 'Polymarket';
    } else if (platform == 2) {
      platformText = 'Kalshi';
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_2.png',
              width: 120.w,
              height: 120.h,
              fit: BoxFit.contain,
              color: AppColors.gray400,
            ),
            SizedBox(height: 32.h),
            Text(
              'No events available',
              style: AppTextStyles.bodyLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'No upcoming events found for\n$platformText in $category',
              style: AppTextStyles.bodyMedium?.copyWith(
                color: AppColors.gray600,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getCurrentEvents() {
    final platform = controller.selectedPlatform.value;
    if (platform == 1) {
      // Polymarket tab - show all loaded events
      return controller.events.toList();
    } else if (platform == 2) {
      // Kalshi tab - show all loaded events
      return controller.kalshiEvents.toList();
    } else {
      // All tab - show all events from both platforms
      return [...controller.events, ...controller.kalshiEvents];
    }
  }

  Widget _buildCardsList() {
    return Obx(() {
      final events = _getCurrentEvents();

      return Column(
        children: events.map((event) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: _buildEventCard(event),
          );
        }).toList(),
      );
    });
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final isKalshi = event['market_place'] == 'Kalshi';
    final marketPercent = double.tryParse(event['marketPercentage']?.replaceAll('%', '') ?? '0') ?? 0;
    final marketPercentDecimal = marketPercent / 100;

    return GestureDetector(
      onTap: () => _navigateToDetail(event),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.gray300 ?? Colors.grey[300]!,
            width: 1.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPlatformTag(isKalshi),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 24.w,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              event['title'] ?? '',
              style: AppTextStyles.bodyLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Top pick : ${event['team'] ?? 'N/A'}',
              style: AppTextStyles.bodySmall?.copyWith(
                color: const Color(0xffDC732D),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market : ${event['marketPercentage'] ?? '0%'}',
                  style: AppTextStyles.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                _buildMarketSlider(marketPercentDecimal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformTag(bool isKalshi) {
    final bgColor = isKalshi ? AppColors.kalshiColor : AppColors.polymarketColor;
    final borderColor = isKalshi ? Colors.black : Colors.grey;
    final displayText = isKalshi ? 'Kalshi' : 'Polymarket';

    return Container(
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
        displayText,
        style: AppTextStyles.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMarketSlider(double percentage) {
    return Container(
      height: 24.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Stack(
        children: [
          Container(
            width: percentage * (Get.width - 72.w),
            height: 24.h,
            decoration: BoxDecoration(
              color: const Color(0xFF1493FF),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 6.w,
                  top: 4.h,
                  child: Container(
                    width: 2.w,
                    height: 16.h,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> event) {
    final isKalshi = event['market_place'] == 'Kalshi';

    // Navigate with basic data - AI will be fetched fresh in detail screen
    Get.to(() => CardDetailScreen(
      title: event['title'] ?? '',
      subtitle: formatPrettyDate(event['endDate'] ?? ''),
      date: formatPrettyDate(event['endDate'] ?? ''),
      marketPercentage: event['marketPercentage'] ?? '0%',
      aiPercentage: event['aiPercentage'] ?? 'N/A', // Will be refetched in detail screen
      team: event['team'] ?? '',
      isPolymarket: !isKalshi,
      bgColor: isKalshi ? kalshiBgColor : polymarketBgColor,
      eventId: event['event_id'] is int ? event['event_id'] as int? : int.tryParse(event['event_id']?.toString() ?? ''),
      eventIdString: event['event_ticker'] as String?,
      slug: event['slug'] as String?,
      seriesTicker: event['series_ticker'] as String?,
      optionTitles: event['optionTitles'] != null ? List<String>.from(event['optionTitles']) : null,
      marketProbs: event['marketProbs'] != null ? List<double>.from(event['marketProbs']) : null,
      aiPercentages: event['aiPercentages'] != null ? List<double>.from(event['aiPercentages']) : null,
      aiExplanation: event['aiExplanation'] as String?,
    ));
  }
}

class EventsController extends GetxController {
  final selectedPlatform = 0.obs;
  final selectedCategory = 'Trending'.obs;
  final isLoading = false.obs;

  final RxList<Map<String, dynamic>> _events = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _kalshiEvents = <Map<String, dynamic>>[].obs;

  List<Map<String, dynamic>> get events => _events;
  List<Map<String, dynamic>> get kalshiEvents => _kalshiEvents;

  final RxMap<String, String?> _polymarketNextPageUrls = <String, String?>{}.obs;
  final RxMap<String, String?> _kalshiNextPageUrls = <String, String?>{}.obs;
  final isPolymarketLoading = false.obs;
  final isKalshiLoading = false.obs;

  String? _polymarketNextPageUrl;
  String? _kalshiNextPageUrl;

  static const String _polymarketCacheKey = 'events_polymarket_';
  static const String _kalshiCacheKey = 'events_kalshi_';
  static const String _cacheTimestampKey = 'events_cache_timestamp_';
  static const Duration _cacheDuration = Duration(hours: 12);

  String _getCategoryKey(String category) {
    return category.toLowerCase().replaceAll(' & ', ' ').replaceAll(' ', '_');
  }

  String? get polymarketNextPageUrl {
    final categoryKey = _getCategoryKey(selectedCategory.value);
    return _polymarketNextPageUrls[categoryKey];
  }

  String? get kalshiNextPageUrl {
    final categoryKey = _getCategoryKey(selectedCategory.value);
    return _kalshiNextPageUrls[categoryKey];
  }

  void setPolymarketNextPageUrl(String category, String? url) {
    final categoryKey = _getCategoryKey(category);
    _polymarketNextPageUrls[categoryKey] = url;
  }

  void setKalshiNextPageUrl(String category, String? url) {
    final categoryKey = _getCategoryKey(category);
    _kalshiNextPageUrls[categoryKey] = url;
  }

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  void _loadInitialData() {
    Future.delayed(Duration.zero, () {
      fetchPolymarketEvents();
      fetchKalshiEvents();
    });
  }

  void selectPlatform(int index) {
    selectedPlatform.value = index;
    selectedCategory.value = 'Trending';
    _loadEventsForCurrentSelection();
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    _loadEventsForCurrentSelection();
  }

  void _loadEventsForCurrentSelection() {
    final platform = selectedPlatform.value;
    final category = selectedCategory.value;
    
    print("=== Load Events For Current Selection ===");
    print("Platform: $platform");
    print("Category: $category");

    if (platform == 0 || platform == 1) {
      _fetchPolymarketWithCategory(category);
    }
    if (platform == 0 || platform == 2) {
      _fetchKalshiWithCategory(category);
    }
  }

  Future<void> _fetchPolymarketWithCategory(String category) async {
    print("=== Fetch Polymarket With Category ===");
    print("Category: $category");
    
    // Always fetch from API, no caching
    await fetchPolymarketEvents(category: category);
  }

  Future<void> _fetchKalshiWithCategory(String category) async {
    print("=== Fetch Kalshi With Category ===");
    print("Category: $category");
    
    // Always fetch from API, no caching
    await fetchKalshiEvents(category: category);
  }

  Future<List<Map<String, dynamic>>?> _getCachedEvents(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      final timestampStr = prefs.getString('${_cacheTimestampKey}${key}');

      if (cached == null || timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      final difference = DateTime.now().difference(timestamp);

      if (difference > _cacheDuration) return null;

      final List decoded = jsonDecode(cached);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheEvents(String key, List<Map<String, dynamic>> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(events));
      await prefs.setString(
        '${_cacheTimestampKey}${key}',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print("Error caching events: $e");
    }
  }

  /// Helper method to check if a date string is today or in the future
  /// Returns true if the date is today or upcoming, false if it's in the past
  bool _isCurrentOrUpcomingDate(String dateStr) {
    try {
      // Parse the date string (handles ISO 8601 format)
      final eventDate = DateTime.parse(dateStr);
      final now = DateTime.now();
      
      // Compare only the date parts (ignore time)
      final eventDateOnly = DateTime(eventDate.year, eventDate.month, eventDate.day);
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      
      return eventDateOnly.isAtSameMomentAs(nowDateOnly) || eventDateOnly.isAfter(nowDateOnly);
    } catch (e) {
      // If parsing fails, include the event to be safe
      print("Error parsing date '$dateStr': $e");
      return true;
    }
  }

  Future<void> fetchPolymarketEvents({String category = 'Trending'}) async {
    isLoading.value = true;

    try {
      // Map category to API parameter format
      String categoryParam;
      switch (category) {
        case 'Trending':
          categoryParam = 'trending';
          break;
        case 'Politics':
          categoryParam = 'politics';
          break;
        case 'Sports':
          categoryParam = 'sports';
          break;
        case 'Crypto':
          categoryParam = 'crypto';
          break;
        case 'Finance':
          categoryParam = 'finance';
          break;
        case 'Geopolitics':
          categoryParam = 'geopolitics';
          break;
        case 'Tech':
          categoryParam = 'tech';
          break;
        case 'Culture':
          categoryParam = 'culture';
          break;
        case 'World':
          categoryParam = 'world';
          break;
        case 'Economy':
          categoryParam = 'economy';
          break;
        case 'Climate & Science':
          categoryParam = 'climate_science';
          break;
        case 'Climate':
          categoryParam = 'climate';
          break;
        case 'Economics':
          categoryParam = 'economics';
          break;
        case 'Companies':
          categoryParam = 'companies';
          break;
        case 'Financials':
          categoryParam = 'financials';
          break;
        case 'Tech & Science':
          categoryParam = 'tech_science';
          break;
        default:
          categoryParam = 'trending';
      }

      final url = 'https://api.pickfair.ai/api/trade/polymarket-event-list/?catagory=$categoryParam';

      print("=== Events Screen: Fetching Polymarket ===");
      print("Category: $category");
      print("Category Param: $categoryParam");
      print("URL: $url");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final eventsList = data['results']?['events'];

        if (eventsList == null || eventsList.isEmpty) {
          isLoading.value = false;
          return;
        }

        List<Map<String, dynamic>> tempEvents = [];

        for (var event in eventsList) {
          final outcomes = event['question_outcome'] as List<dynamic>?;

          if (event['title'] == null || event['title'].toString().isEmpty) continue;
          if (outcomes == null || outcomes.isEmpty) continue;

          // Filter by date: only include current or upcoming events
          final endDate = event['end_date']?.toString() ?? '';
          if (endDate.isNotEmpty && !_isCurrentOrUpcomingDate(endDate)) {
            continue; // Skip past events
          }

          final validOutcomes = outcomes.where((o) {
            final title = o['group_item_title']?.toString() ?? '';
            final probStr = o['probability']?.toString() ?? '';
            final prob = double.tryParse(probStr) ?? -1;
            return title.isNotEmpty && prob >= 0;
          }).toList();

          if (validOutcomes.isEmpty) continue;

          String highestTeam = '';
          double highestProb = -1;

          List<String> optionTitles = [];
          List<double> marketProbs = [];

          for (var outcome in validOutcomes) {
            final prob = double.tryParse(outcome['probability'].toString()) ?? 0;
            final title = outcome['group_item_title'] ?? '';

            if (prob <= 0) continue;

            optionTitles.add(title);
            marketProbs.add(prob);

            if (prob > highestProb) {
              highestProb = prob;
              highestTeam = title;
            }
          }

          if (optionTitles.isEmpty) continue;

          int roundedPercentage = highestProb.floor();
          if (highestProb - roundedPercentage >= 0.5) {
            roundedPercentage += 1;
          }

          final marketPercentage = '${roundedPercentage}%';

          tempEvents.add({
            'event_id': event['event_id'],
            'title': event['title'],
            'slug': event['slug'] ?? '',
            'imageUrl': event['image_url'] ?? '',
            'endDate': event['end_date'] ?? '',
            'team': highestTeam,
            'marketPercentage': marketPercentage,
            'aiPercentage': null,
            'aiExplanation': '',
            'optionTitles': optionTitles,
            'marketProbs': marketProbs,
            'aiPercentages': [],
            'market_place': 'Polymarket',
          });
        }

        // Always replace events list when switching categories
        _events.assignAll(tempEvents);

        print("=== Polymarket Events Loaded ===");
        print("Total Events (after date filter): ${_events.length}");
        print("Category: $category");
        print("✅ Events screen using cached AI data only (AI fetched on detail view only)");

        update(); // Trigger UI refresh

        final nextPageUrl = data['next'];
        setPolymarketNextPageUrl(category, nextPageUrl);

        // NO AI calls here - only fetch AI when user opens detail page
      }
    } catch (e) {
      print("Error fetching Polymarket events: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchKalshiEvents({String category = 'Trending'}) async {
    isLoading.value = true;

    try {
      // Map category to API parameter format
      String categoryParam;
      switch (category) {
        case 'Trending':
          categoryParam = 'trending';
          break;
        case 'Politics':
          categoryParam = 'politics';
          break;
        case 'Sports':
          categoryParam = 'sports';
          break;
        case 'Crypto':
          categoryParam = 'crypto';
          break;
        case 'Finance':
          categoryParam = 'finance';
          break;
        case 'Geopolitics':
          categoryParam = 'geopolitics';
          break;
        case 'Tech':
          categoryParam = 'tech';
          break;
        case 'Culture':
          categoryParam = 'culture';
          break;
        case 'World':
          categoryParam = 'world';
          break;
        case 'Economy':
          categoryParam = 'economy';
          break;
        case 'Climate & Science':
          categoryParam = 'climate_science';
          break;
        case 'Climate':
          categoryParam = 'climate';
          break;
        case 'Economics':
          categoryParam = 'economics';
          break;
        case 'Companies':
          categoryParam = 'companies';
          break;
        case 'Financials':
          categoryParam = 'financials';
          break;
        case 'Tech & Science':
          categoryParam = 'tech_science';
          break;
        default:
          categoryParam = 'trending';
      }

      final url = 'https://api.pickfair.ai/api/trade/kalshi-event-list/?catagory=$categoryParam';
      
      print("=== Events Screen: Fetching Kalshi ===");
      print("Category: $category");
      print("Category Param: $categoryParam");
      print("URL: $url");

      final response = await http.get(Uri.parse(url));
      
      print("Kalshi Response Status: ${response.statusCode}");
      print("Kalshi Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final eventsList = data['results']?['events'];

        if (eventsList == null || eventsList.isEmpty) {
          isLoading.value = false;
          return;
        }

        List<Map<String, dynamic>> tempEvents = [];

        for (var event in eventsList) {
          final outcomes = event['outcomes'] as List<dynamic>?;

          if (event['title'] == null || event['title'].toString().isEmpty) continue;
          if (outcomes == null || outcomes.isEmpty) continue;

          // Filter by date: only include current or upcoming events
          final endDate = event['end_date']?.toString() ?? '';
          if (endDate.isNotEmpty && !_isCurrentOrUpcomingDate(endDate)) {
            continue; // Skip past events
          }

          String highestTeam = '';
          double highestProb = -1;

          List<String> optionTitles = [];
          List<double> marketProbs = [];

          if (outcomes.length == 1) {
            final outcome = outcomes[0];
            final probYes = double.tryParse(outcome['probability_yes'].toString()) ?? -1;
            final titleYes = outcome['group_item_title_yes']?.toString() ?? '';

            if (probYes > 0 && probYes < 100 && titleYes.isNotEmpty) {
              highestTeam = titleYes;
              highestProb = probYes;
              optionTitles.add(titleYes);
              marketProbs.add(probYes);
            }
          } else {
            for (var outcome in outcomes) {
              final probYes = double.tryParse(outcome['probability_yes'].toString()) ?? -1;
              final titleYes = outcome['group_item_title_yes']?.toString() ?? '';

              if (probYes <= 0 || probYes >= 100) continue;
              if (titleYes.isEmpty) continue;

              optionTitles.add(titleYes);
              marketProbs.add(probYes);

              if (probYes > highestProb) {
                highestProb = probYes;
                highestTeam = titleYes;
              }
            }
          }

          if (optionTitles.isEmpty) continue;

          int roundedPercentage = highestProb.floor();
          if (highestProb - roundedPercentage >= 0.5) {
            roundedPercentage += 1;
          }

          final marketPercentage = '${roundedPercentage}%';

          tempEvents.add({
            'event_id': event['event_ticker'],
            'series_ticker': event['series_ticker'] ?? '',
            'title': event['title'],
            'endDate': event['end_date'] ?? '',
            'team': highestTeam,
            'marketPercentage': marketPercentage,
            'aiPercentage': null,
            'aiExplanation': '',
            'optionTitles': optionTitles,
            'marketProbs': marketProbs,
            'aiPercentages': [],
            'market_place': 'Kalshi',
          });
        }

        // Always replace events list when switching categories
        _kalshiEvents.assignAll(tempEvents);
        
        print("=== Kalshi Events Loaded ===");
        print("Total Events (after date filter): ${_kalshiEvents.length}");
        print("Category: $category");
        print("✅ Events screen using cached AI data only (AI fetched on detail view only)");
        
        update(); // Trigger UI refresh

        final nextPageUrl = data['next'];
        setKalshiNextPageUrl(category, nextPageUrl);

        // NO AI calls here - only fetch AI when user opens detail page
      }
    } catch (e) {
      print("Error fetching Kalshi events: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _buildFilteredOptions(Map<String, dynamic> e) {
    List<String> filteredOptions = [];
    List<double> filteredMarketProbs = [];
    List<int> originalIndices = [];

    for (int j = 0; j < e['optionTitles'].length; j++) {
      final marketProb = e['marketProbs'][j] as double;
      if (marketProb <= 0) continue;
      filteredOptions.add(e['optionTitles'][j]);
      filteredMarketProbs.add(marketProb);
      originalIndices.add(j);
    }

    String highestMarketTeam = e['team'];
    int highestMarketIndex = filteredOptions.indexOf(highestMarketTeam);

    if (highestMarketIndex != -1 && highestMarketIndex != 0) {
      final topOption = filteredOptions.removeAt(highestMarketIndex);
      final topProb = filteredMarketProbs.removeAt(highestMarketIndex);
      final topIndex = originalIndices.removeAt(highestMarketIndex);

      filteredOptions.insert(0, topOption);
      filteredMarketProbs.insert(0, topProb);
      originalIndices.insert(0, topIndex);
    }

    return {
      "options": filteredOptions,
      "marketProbs": filteredMarketProbs,
      "originalIndices": originalIndices,
    };
  }

  Future<void> refreshEvents() async {
    _loadEventsForCurrentSelection();
  }

  Future<void> loadPolymarketNextPage() async {
    final nextPageUrl = polymarketNextPageUrl;
    print('=== loadPolymarketNextPage ===');
    print('nextPageUrl: $nextPageUrl');
    print('isPageLoading: ${isPolymarketLoading.value}');

    if (nextPageUrl != null && !isPolymarketLoading.value) {
      isPolymarketLoading.value = true;
      try {
        print('Fetching Polymarket page from: $nextPageUrl');
        final response = await http.get(Uri.parse(nextPageUrl));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final eventsList = data['results']?['events'];

          if (eventsList == null || eventsList.isEmpty) {
            isPolymarketLoading.value = false;
            return;
          }

          List<Map<String, dynamic>> tempEvents = [];
          for (var event in eventsList) {
            final outcomes = event['question_outcome'] as List<dynamic>?;
            if (event['title'] == null || event['title'].toString().isEmpty) continue;
            if (outcomes == null || outcomes.isEmpty) continue;

            final validOutcomes = outcomes.where((o) {
              final title = o['group_item_title']?.toString() ?? '';
              final probStr = o['probability']?.toString() ?? '';
              final prob = double.tryParse(probStr) ?? -1;
              return title.isNotEmpty && prob >= 0;
            }).toList();

            if (validOutcomes.isEmpty) continue;

            String highestTeam = '';
            double highestProb = -1;
            List<String> optionTitles = [];
            List<double> marketProbs = [];

            for (var outcome in validOutcomes) {
              final prob = double.tryParse(outcome['probability'].toString()) ?? 0;
              final title = outcome['group_item_title'] ?? '';
              if (prob <= 0) continue;
              optionTitles.add(title);
              marketProbs.add(prob);
              if (prob > highestProb) {
                highestProb = prob;
                highestTeam = title;
              }
            }

            if (optionTitles.isEmpty) continue;

            int roundedPercentage = highestProb.floor();
            if (highestProb - roundedPercentage >= 0.5) {
              roundedPercentage += 1;
            }

            tempEvents.add({
              'event_id': event['event_id'],
              'title': event['title'],
              'slug': event['slug'] ?? '',
              'endDate': event['end_date'] ?? '',
              'team': highestTeam,
              'marketPercentage': '${roundedPercentage}%',
              'aiPercentage': null,
              'aiExplanation': '',
              'optionTitles': optionTitles,
              'marketProbs': marketProbs,
              'aiPercentages': [],
              'market_place': 'Polymarket',
            });
          }

          _events.addAll(tempEvents);
          setPolymarketNextPageUrl(selectedCategory.value, data['next']);

          final cachedKey = '${_polymarketCacheKey}${selectedCategory.value.toLowerCase()}';
          await _cacheEvents(cachedKey, _events);
        }
      } catch (e) {
        print("Error loading Polymarket next page: $e");
      } finally {
        isPolymarketLoading.value = false;
      }
    }
  }

  Future<void> loadKalshiNextPage() async {
    final nextPageUrl = kalshiNextPageUrl;
    print('=== loadKalshiNextPage ===');
    print('nextPageUrl: $nextPageUrl');
    print('isPageLoading: ${isKalshiLoading.value}');

    if (nextPageUrl != null && !isKalshiLoading.value) {
      isKalshiLoading.value = true;
      try {
        print('Fetching Kalshi page from: $nextPageUrl');
        final response = await http.get(Uri.parse(nextPageUrl));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final eventsList = data['results']?['events'];

          if (eventsList == null || eventsList.isEmpty) {
            isKalshiLoading.value = false;
            return;
          }

          List<Map<String, dynamic>> tempEvents = [];
          for (var event in eventsList) {
            final outcomes = event['outcomes'] as List<dynamic>?;
            if (event['title'] == null || event['title'].toString().isEmpty) continue;
            if (outcomes == null || outcomes.isEmpty) continue;

            String highestTeam = '';
            double highestProb = -1;
            List<String> optionTitles = [];
            List<double> marketProbs = [];

            if (outcomes.length == 1) {
              final outcome = outcomes[0];
              final probYes = double.tryParse(outcome['probability_yes'].toString()) ?? -1;
              final titleYes = outcome['group_item_title_yes']?.toString() ?? '';
              if (probYes > 0 && probYes < 100 && titleYes.isNotEmpty) {
                highestTeam = titleYes;
                highestProb = probYes;
                optionTitles.add(titleYes);
                marketProbs.add(probYes);
              }
            } else {
              for (var outcome in outcomes) {
                final probYes = double.tryParse(outcome['probability_yes'].toString()) ?? -1;
                final titleYes = outcome['group_item_title_yes']?.toString() ?? '';
                if (probYes <= 0 || probYes >= 100) continue;
                if (titleYes.isEmpty) continue;
                optionTitles.add(titleYes);
                marketProbs.add(probYes);
                if (probYes > highestProb) {
                  highestProb = probYes;
                  highestTeam = titleYes;
                }
              }
            }

            if (optionTitles.isEmpty) continue;

            int roundedPercentage = highestProb.floor();
            if (highestProb - roundedPercentage >= 0.5) {
              roundedPercentage += 1;
            }

            tempEvents.add({
              'event_id': event['event_ticker'],
              'series_ticker': event['series_ticker'] ?? '',
              'title': event['title'],
              'imageUrl': event['img_url'] ?? '',
              'endDate': event['end_date'] ?? '',
              'team': highestTeam,
              'marketPercentage': '${roundedPercentage}%',
              'aiPercentage': null,
              'aiExplanation': '',
              'optionTitles': optionTitles,
              'marketProbs': marketProbs,
              'aiPercentages': [],
              'market_place': 'Kalshi',
            });
          }

          _kalshiEvents.addAll(tempEvents);
          setKalshiNextPageUrl(selectedCategory.value, data['next']);

          final cachedKey = '${_kalshiCacheKey}${selectedCategory.value.toLowerCase()}';
          await _cacheEvents(cachedKey, _kalshiEvents);
        }
      } catch (e) {
        print("Error loading Kalshi next page: $e");
      } finally {
        isKalshiLoading.value = false;
      }
    }
  }
}
