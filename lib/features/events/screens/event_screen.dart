// lib/features/events/screens/events_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';
import 'package:murchin/features/home/screens/card_details_screen.dart'; // Add this import

class EventsScreen extends StatelessWidget {
  EventsScreen({super.key});

  // Controller for the platform tabs
  final EventsController controller = Get.put(EventsController());

  // Color constants
  final Color unselectedBgColor = const Color(0xFFBDC4D2);
  final Color polymarketBgColor = const Color(0xff607D3B); // Green
  final Color kalshiBgColor = const Color(0xFF6678F3); // Blue

  // Categories list
  final List<String> categories = [
    'Trending',
    'Breaking',
    'New',
    'Politics',
    'Sports',
    'Crypto',
    'Finance',
    'Geopolitics',
    'Earnings',
    'Tech',
    'Culture',
    'World',
    'Economy',
    'Elections',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(imageAsset: 'assets/images/name.png'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              
              // Platform Tabs
              _buildSeparatePlatformTabs(),
              
              SizedBox(height: 10.h),
              
              // Horizontal Categories
              _buildCategoriesRow(),
              
              SizedBox(height: 16.h),
              
              // SINGLE Gradient Card - Make tappable too
              GestureDetector(
                onTap: () {
                  Get.to(() => CardDetailScreen(
                    title: 'Featured Event',
                    subtitle: 'Premium Prediction',
                    date: 'Feb 8, 2026',
                    marketPercentage: '38%',
                    aiPercentage: '65%',
                    team: 'Featured Team',
                    isPolymarket: true,
                    bgColor: AppColors.primary,
                  ));
                },
                child: _buildSingleGradientCard(),
              ),
              
              SizedBox(height: 24.h),
              
              // Cards List
              _buildCardsList(),
              
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  // Platform Tabs
  Widget _buildSeparatePlatformTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSeparateTab(0, 'All Platforms'),
        SizedBox(width: 12.w),
        _buildSeparateTab(1, 'Polymarket'),
        SizedBox(width: 12.w),
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

  // Horizontal Categories
  Widget _buildCategoriesRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Obx(() {
        return Row(
          children: categories.map((category) {
            final isSelected = controller.selectedCategory.value == category;
            return Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: GestureDetector(
                onTap: () => controller.selectCategory(category),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Text
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
                    
                    // Underline (only for selected)
                    if (isSelected)
                      Container(
                        width: 30.w, // Width of the underline
                        height: 2.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary, // You can change this color
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

  // SINGLE Gradient Card
  Widget _buildSingleGradientCard() {
    return Container(
      width: double.infinity,
      height: 123.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        image: DecorationImage(
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
            // Title
            Text(
              'Featured Event',
              style: AppTextStyles.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Bottom row with date
            Row(
              children: [
                // Date
                Text(
                  'Feb 8, 2026',
                  style: AppTextStyles.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                  ),
                ),
                
                Spacer(),
                
                // Arrow icon
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
    );
  }

  // Cards List
  Widget _buildCardsList() {
    // Sample data for cards - updated with team names
    final List<Map<String, dynamic>> cardsData = [
      {
        'title': 'Super Bowl Champion 2026',
        'subtitle': 'Championship Prediction',
        'topPick': 'Top pick : JD Vance',
        'marketPercent': '27%',
        'aiPercent': '31%',
        'team': 'Chiefs',
        'platform': 'polymarket',
        'isPolymarket': true,
      },
      {
        'title': 'US Presidential Election 2024',
        'subtitle': 'Election Outcome',
        'topPick': 'Top pick : Kamala Harris',
        'marketPercent': '42%',
        'aiPercent': '45%',
        'team': 'Democratic',
        'platform': 'polymarket',
        'isPolymarket': true,
      },
      {
        'title': 'Bitcoin Price by End of 2024',
        'subtitle': 'Cryptocurrency Forecast',
        'topPick': 'Top pick : Above 70K',
        'marketPercent': '52%',
        'aiPercent': '56%',
        'team': 'Bull Market',
        'platform': 'kalshi',
        'isPolymarket': false,
      },
      {
        'title': 'Tesla Stock Performance',
        'subtitle': 'Stock Market Analysis',
        'topPick': 'Top pick : Will rise 20%',
        'marketPercent': '33%',
        'aiPercent': '41%',
        'team': 'Growth Stock',
        'platform': 'kalshi',
        'isPolymarket': false,
      },
    ];

    return Obx(() {
      // Filter cards based on selected platform
      final filteredCards = cardsData.where((card) {
        final selectedPlatform = controller.selectedPlatform.value;
        final cardPlatform = card['platform'];
        
        if (selectedPlatform == 0) {
          return true; // All Platforms - show all
        } else if (selectedPlatform == 1) {
          return cardPlatform == 'polymarket'; // Only Polymarket
        } else if (selectedPlatform == 2) {
          return cardPlatform == 'kalshi'; // Only Kalshi
        }
        return false;
      }).toList();

      return Column(
        children: filteredCards.map((cardData) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: _buildEventCard(cardData),
          );
        }).toList(),
      );
    });
  }

  // Individual Event Card
  Widget _buildEventCard(Map<String, dynamic> cardData) {
    return GestureDetector(
      onTap: () {
        // Navigate to CardDetailScreen when tapped
        Get.to(() => CardDetailScreen(
          title: cardData['title'],
          subtitle: cardData['subtitle'],
          date: 'Feb 8, 2026', // You can make this dynamic if needed
          marketPercentage: cardData['marketPercent'],
          aiPercentage: cardData['aiPercent'],
          team: cardData['team'],
          isPolymarket: cardData['isPolymarket'],
          bgColor: cardData['platform'] == 'polymarket' ? polymarketBgColor : kalshiBgColor,
        ));
      },
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
            // Top row with platform tag and iOS button
            Row(
              children: [
                // Platform tag
                _buildPlatformTag(cardData['platform']),
                
                Spacer(),
                
                // iOS right button
                Container(
                  padding: EdgeInsets.all(0.w),
                  child: Icon(
                    Icons.chevron_right,
                    size: 24.w,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Title
            Text(
              cardData['title'],
              style: AppTextStyles.bodyLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
            
            SizedBox(height: 8.h),
            
            // Top pick text
            Text(
              cardData['topPick'],
              style: AppTextStyles.bodySmall?.copyWith(
                color: Color(0xff848484),
                fontSize: 12.sp,
                fontWeight: FontWeight.w700
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Bottom row with percentages (70% width total)
            Container(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Market percentage
                  Container(
                    width: 120.w, // Fixed width instead of Expanded
                    padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3CB043), // #3CB043
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Center(
                      child: Text(
                        'Market : ${cardData['marketPercent']}',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 8.w),
                  
                  // AI percentage
                  Container(
                    width: 120.w, // Fixed width instead of Expanded
                    padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFD2400), // #FD2400
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Center(
                      child: Text(
                        'AI : ${cardData['aiPercent']}',
                        style: AppTextStyles.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  // Platform Tag Widget (simplified - only one platform per card)
  Widget _buildPlatformTag(String platform) {
    Color bgColor;
    Color borderColor;
    String displayText;
    
    if (platform == 'polymarket') {
      bgColor = polymarketBgColor;
      borderColor = AppColors.primary; // Using primary as notBlue
      displayText = 'Polymarket';
    } else {
      // kalshi
      bgColor = kalshiBgColor;
      borderColor = const Color(0xFF007AFF); // Blue
      displayText = 'Kalshi';
    }
    
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
}

// Events Controller
class EventsController extends GetxController {
  final selectedPlatform = 0.obs; // 0: All Platforms, 1: Polymarket, 2: Kalshi
  final selectedCategory = 'Trending'.obs; // Default selected category
  
  void selectPlatform(int index) {
    selectedPlatform.value = index;
  }
  
  void selectCategory(String category) {
    selectedCategory.value = category;
  }
}