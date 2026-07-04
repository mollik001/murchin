// lib/features/market/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murcin/const/theme/app_color.dart';
import 'package:murcin/const/widgets/custom_appbar.dart';
import 'package:murcin/features/market/home/controllers/home_controller.dart';
import 'package:murcin/features/market/home/widgets/polymarket_card.dart';
import 'package:murcin/features/market/home/widgets/kalshi_card.dart';
import 'package:murcin/features/selection/selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.put(HomeController());
  final ScrollController scrollController = ScrollController();
  final ScrollController kalshiScrollController = ScrollController();

  final Color unselectedBgColor = const Color(0xFF8D9AB1);
  final Color polymarketBgColor = AppColors.polymarketColor;
  final Color kalshiBgColor = AppColors.kalshiCardBg;

  @override
  void initState() {
    super.initState();
    // No manual pagination - auto-loads 2 pages (10 events total)
  }

  @override
  void dispose() {
    scrollController.dispose();
    kalshiScrollController.dispose();
    super.dispose();
  }

  /// ✅ Pretty Date Format
  String formatPrettyDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
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
      //appBar: CustomAppBar(imageAsset: 'assets/images/name_2.png'),
      body: const SelectionScreen(),
      // COMMENTED OUT - Old homepage content replaced with SelectionScreen
      // body: Column(
      //   children: [
      //     SizedBox(height: 20.h),
      //     Padding(
      //       padding: EdgeInsets.symmetric(horizontal: 20.w),
      //       child: _buildSearchBar(),
      //     ),
      //     SizedBox(height: 30.h),
      //     Obx(() => controller.isSearching.value
      //         ? Padding(
      //             padding: EdgeInsets.symmetric(horizontal: 20.w),
      //             child: Row(
      //               children: [
      //                 const Text(
      //                   'Search Results',
      //                   style: TextStyle(
      //                     fontSize: 16,
      //                     fontWeight: FontWeight.bold,
      //                   ),
      //                 ),
      //                 const Spacer(),
      //                 GestureDetector(
      //                   onTap: controller.clearSearch,
      //                   child: const Text(
      //                     'Clear',
      //                     style: TextStyle(
      //                       color: AppColors.primary,
      //                       fontSize: 14,
      //                     ),
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           )
      //         : Padding(
      //             padding: EdgeInsets.symmetric(horizontal: 20.w),
      //             child: _buildSeparatePlatformTabs(),
      //           )),
      //     SizedBox(height: 30.h),
      //     Expanded(
      //       child: Obx(() {
      //         // Show cached/local events immediately
      //         if (controller.events.isEmpty && controller.isLoading.value) {
      //           return const Center(child: CircularProgressIndicator());
      //         }

      //         // Search results or Polymarket tab
      //         if (controller.isSearching.value ||
      //             controller.selectedPlatform.value == 1) {
      //           return ListView.builder(
      //             controller: scrollController,
      //             padding: EdgeInsets.symmetric(horizontal: 20.w),
      //             itemCount: controller.events.length + (controller.isPageLoading.value ? 1 : 0),
      //             itemBuilder: (context, index) {
      //               if (index < controller.events.length) {
      //                 final e = controller.events[index];
      //                 final eventId = e['event_id'] as int?;
      //                 final slug = e['slug'] as String?;
      //                 return Obx(() => Padding(
      //                   padding: EdgeInsets.only(bottom: 20.h),
      //                   child: PolymarketCard(
      //                     eventId: eventId,
      //                     title: e['title'],
      //                     subtitle: formatPrettyDate(e['endDate']),
      //                     date: formatPrettyDate(e['endDate']),
      //                     marketPercentage: e['marketPercentage'],
      //                     aiPercentage: e['aiPercentage'],
      //                     team: e['team'],
      //                     bgColor: polymarketBgColor,
      //                     borderColor: polymarketBgColor,
      //                     platformTagBgColor: AppColors.polymarketColor,
      //                     platformTagBorderColor: Colors.grey,
      //                     slug: slug,
      //                     isSaved: eventId != null && controller.isEventSaved(eventId),
      //                     optionTitles: e['optionTitles'] != null ? List<String>.from(e['optionTitles']) : null,
      //                     marketProbs: e['marketProbs'] != null ? List<double>.from(e['marketProbs']) : null,
      //                     aiPercentages: e['aiPercentages'] != null ? List<double>.from(e['aiPercentages']) : null,
      //                     aiExplanation: e['aiExplanation'] as String?,
      //                   ),
      //                 ));
      //               } else {
      //                 // Loading spinner for auto-pagination
      //                 return controller.isPageLoading.value
      //                     ? const Padding(
      //                         padding: EdgeInsets.all(16),
      //                         child: Center(child: CircularProgressIndicator()),
      //                       )
      //                     : const SizedBox();
      //               }
      //             },
      //           );
      //         }

      //         // Kalshi tab (dynamic)
      //         if (controller.selectedPlatform.value == 2) {
      //           if (controller.kalshiEvents.isEmpty && controller.isLoading.value) {
      //             return const Center(child: CircularProgressIndicator());
      //           }
      //           return ListView.builder(
      //             controller: kalshiScrollController,
      //             padding: EdgeInsets.symmetric(horizontal: 20.w),
      //             itemCount: controller.kalshiEvents.length + (controller.isPageLoading.value ? 1 : 0),
      //             itemBuilder: (context, index) {
      //               if (index < controller.kalshiEvents.length) {
      //                 final e = controller.kalshiEvents[index];
      //                 final eventId = e['event_id'] as String?;
      //                 final seriesTicker = e['series_ticker'] as String?;
      //                 return Padding(
      //                   padding: EdgeInsets.only(bottom: 20.h),
      //                   child: KalshiCard(
      //                     eventId: eventId,
      //                     title: e['title'],
      //                     subtitle: formatPrettyDate(e['endDate']),
      //                     date: formatPrettyDate(e['endDate']),
      //                     marketPercentage: e['marketPercentage'],
      //                     aiPercentage: e['aiPercentage'],
      //                     team: e['team'],
      //                     bgColor: kalshiBgColor,
      //                     borderColor: kalshiBgColor,
      //                     platformTagBgColor: AppColors.kalshiColor,
      //                     platformTagBorderColor: Colors.black,
      //                     seriesTicker: seriesTicker,
      //                     isSaved: false, // TODO: Implement Kalshi save functionality
      //                     optionTitles: e['optionTitles'] != null ? List<String>.from(e['optionTitles']) : null,
      //                     marketProbs: e['marketProbs'] != null ? List<double>.from(e['marketProbs']) : null,
      //                     aiPercentages: e['aiPercentages'] != null ? List<double>.from(e['aiPercentages']) : null,
      //                     aiExplanation: e['aiExplanation'] as String?,
      //                   ),
      //                 );
      //               } else {
      //                 // Loading spinner for auto-pagination
      //                 return controller.isPageLoading.value
      //                     ? const Padding(
      //                         padding: EdgeInsets.all(16),
      //                         child: Center(child: CircularProgressIndicator()),
      //                       )
      //                     : const SizedBox();
      //               }
      //             },
      //           );
      //         }

      //         // All tab (mix of Polymarket + Kalshi)
      //         return ListView(
      //           padding: EdgeInsets.symmetric(horizontal: 20.w),
      //           children: [
      //             ...controller.events
      //                 .take(3)
      //                 .map(
      //                   (e) {
      //                     final eventId = e['event_id'] as int?;
      //                     final slug = e['slug'] as String?;
      //                     return Obx(() => Padding(
      //                       padding: EdgeInsets.only(bottom: 20.h),
      //                       child: PolymarketCard(
      //                         eventId: eventId,
      //                         title: e['title'],
      //                         subtitle: formatPrettyDate(e['endDate']),
      //                         date: formatPrettyDate(e['endDate']),
      //                         marketPercentage: e['marketPercentage'],
      //                         aiPercentage: e['aiPercentage'],
      //                         team: e['team'],
      //                         bgColor: polymarketBgColor,
      //                         borderColor: polymarketBgColor,
      //                         platformTagBgColor: AppColors.polymarketColor,
      //                         platformTagBorderColor: Colors.grey,
      //                         slug: slug,
      //                         isSaved: eventId != null && controller.isEventSaved(eventId),
      //                         optionTitles: e['optionTitles'] != null ? List<String>.from(e['optionTitles']) : null,
      //                         marketProbs: e['marketProbs'] != null ? List<double>.from(e['marketProbs']) : null,
      //                         aiPercentages: e['aiPercentages'] != null ? List<double>.from(e['aiPercentages']) : null,
      //                         aiExplanation: e['aiExplanation'] as String?,
      //                       ),
      //                     ));
      //                   },
      //                 ),
      //             ...controller.kalshiEvents
      //                 .take(3)
      //                 .map(
      //                   (e) {
      //                     final eventId = e['event_id'] as String?;
      //                     final seriesTicker = e['series_ticker'] as String?;
      //                     return Padding(
      //                       padding: EdgeInsets.only(bottom: 20.h),
      //                       child: KalshiCard(
      //                         eventId: eventId,
      //                         title: e['title'],
      //                         subtitle: formatPrettyDate(e['endDate']),
      //                         date: formatPrettyDate(e['endDate']),
      //                         marketPercentage: e['marketPercentage'],
      //                         aiPercentage: e['aiPercentage'],
      //                         team: e['team'],
      //                         bgColor: kalshiBgColor,
      //                         borderColor: kalshiBgColor,
      //                         platformTagBgColor: AppColors.kalshiColor,
      //                         platformTagBorderColor: Colors.black,
      //                         seriesTicker: seriesTicker,
      //                         isSaved: false, // TODO: Implement Kalshi save functionality
      //                         optionTitles: e['optionTitles'] != null ? List<String>.from(e['optionTitles']) : null,
      //                         marketProbs: e['marketProbs'] != null ? List<double>.from(e['marketProbs']) : null,
      //                         aiPercentages: e['aiPercentages'] != null ? List<double>.from(e['aiPercentages']) : null,
      //                         aiExplanation: e['aiExplanation'] as String?,
      //                       ),
      //                     );
      //                   },
      //                 ),
      //           ],
      //         );
      //       }),
      //     ),
      //   ],
      // ),
    );
  }

  // COMMENTED OUT - Helper methods no longer used
  // Widget _buildSearchBar() {
  //   final hasText = controller.searchController.text.isNotEmpty;

  //   return Obx(() {
  //     final isSearching = controller.isSearching.value;
  //     return Container(
  //       height: 42.h,
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(25.r),
  //         border: Border.all(color: const Color(0xffE6E6E6)),
  //       ),
  //       child: Row(
  //         children: [
  //           Padding(
  //             padding: EdgeInsets.only(left: 16.w, right: 12.w),
  //             child: Image.asset('assets/icons/search.png', width: 20.w),
  //           ),
  //           Expanded(
  //             child: TextField(
  //               controller: controller.searchController,
  //               decoration: InputDecoration(
  //                 hintText: isSearching ? 'Searching...' : 'Search',
  //                 border: InputBorder.none,
  //               ),
  //               onChanged: controller.onSearchQueryChanged,
  //             ),
  //           ),
  //           if (hasText && !isSearching)
  //             GestureDetector(
  //               onTap: controller.clearSearch,
  //               child: Padding(
  //                 padding: EdgeInsets.only(right: 12.w),
  //                 child: Icon(
  //                   Icons.clear,
  //                   size: 18.sp,
  //                   color: Colors.grey,
  //                 ),
  //               ),
  //             ),
  //           if (isSearching)
  //             Padding(
  //               padding: EdgeInsets.only(right: 12.w),
  //               child: SizedBox(
  //                 width: 16.w,
  //                 height: 16.w,
  //                 child: const CircularProgressIndicator(
  //                   strokeWidth: 2,
  //                   valueColor: AlwaysStoppedAnimation<Color>(
  //                     AppColors.primary,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //         ],
  //       ),
  //     );
  //   });
  // }

  // Widget _buildSeparatePlatformTabs() {
  //   return Row(
  //     children: [
  //       _buildTab(0, "All"),
  //       SizedBox(width: 10.w),
  //       _buildTab(1, "Polymarket"),
  //       SizedBox(width: 10.w),
  //       _buildTab(2, "Kalshi"),
  //     ],
  //   );
  // }

  // Widget _buildTab(int index, String text) {
  //   return Expanded(
  //     child: Obx(() {
  //       final selected = controller.selectedPlatform.value == index;
  //       return GestureDetector(
  //         onTap: () => controller.selectPlatform(index),
  //         child: Container(
  //           height: 30.h,
  //           decoration: BoxDecoration(
  //             color: selected ? AppColors.primary : unselectedBgColor,
  //             borderRadius: BorderRadius.circular(10.r),
  //           ),
  //           child: Center(
  //             child: Text(text, style: const TextStyle(color: Colors.white)),
  //           ),
  //         ),
  //       );
  //     }),
  //   );
  // }
}
