import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murcin/const/theme/app_color.dart';
import 'package:murcin/const/utils/platform_helper.dart';
import 'package:murcin/features/sports/home/screens/sports_home_screen.dart';
import 'package:murcin/features/sports/events/screens/sports_events_screen.dart';
import 'package:murcin/features/sports/home/controllers/sports_home_controller.dart';
import 'package:murcin/features/navbar/navbar_controller.dart';
import 'package:murcin/features/profile/screens/profile_screen.dart';
import 'package:murcin/features/sports/saved/screens/sports_saved_screen.dart';

class SportsNavbarScreen extends StatelessWidget {
  SportsNavbarScreen({super.key});

  List<Widget> get pages {
    if (PlatformHelper.isBookmarkEnabled && PlatformHelper.isProfileEnabled) {
      return const [
        SportsHomeScreen(),
        SportsEventsScreen(),
        SportsSavedScreen(),
        ProfileScreen(),
      ];
    }
    // iOS: Only Home and Events
    return const [
      SportsHomeScreen(),
      SportsEventsScreen(),
    ];
  }

  List<String> get normalIcons {
    if (PlatformHelper.isBookmarkEnabled && PlatformHelper.isProfileEnabled) {
      return const [
        'assets/icons/home.png',
        'assets/icons/events.png',
        'assets/icons/saved.png',
        'assets/icons/profile.png',
      ];
    }
    // iOS icons
    return const [
      'assets/icons/home.png',
      'assets/icons/events.png',
    ];
  }

  List<String> get filledIcons {
    if (PlatformHelper.isBookmarkEnabled && PlatformHelper.isProfileEnabled) {
      return const [
        'assets/icons/home_active.png',
        'assets/icons/events_active.png',
        'assets/icons/saved_active.png',
        'assets/icons/profile_active.png',
      ];
    }
    // iOS active icons
    return const [
      'assets/icons/home_active.png',
      'assets/icons/events_active.png',
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    final navController = Get.put(BottomNavbarController());
    Get.put(SportsHomeController());

    final currentPages = pages;
    if (navController.currentIndex.value >= currentPages.length) {
      navController.currentIndex.value = 1;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        final index = navController.currentIndex.value;
        final safeIndex = (index >= 0 && index < currentPages.length) ? index : 0;
        return currentPages[safeIndex];
      }),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final BottomNavbarController controller = Get.find<BottomNavbarController>();
    final currentNormalIcons = normalIcons;
    final currentFilledIcons = filledIcons;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(currentNormalIcons.length, (index) {
              return Obx(() {
                final isSelected = controller.currentIndex.value == index;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.changeIndex(index),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Image.asset(
                      isSelected
                          ? currentFilledIcons[index]
                          : currentNormalIcons[index],
                      width: 38.w,
                      height: 45.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              });
            }),
          ),
        ),
      ),
    );
  }
}
