import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/features/home/screens/home_screen.dart';
import 'package:murchin/features/navbar/navbar_controller.dart';

class CustomNavbar extends StatelessWidget {
  CustomNavbar({super.key});

  final List<Widget> pages = [
HomeScreen(),
Placeholder(),
Placeholder(),
Placeholder(),
  ];

  final List<String> normalIcons = const [
    'assets/icons/home.png',
    'assets/icons/events.png',
    'assets/icons/saved.png',
    'assets/icons/profile.png',
  ];

  final List<String> filledIcons = const [
    'assets/icons/home_active.png',
    'assets/icons/events_active.png',
    'assets/icons/saved_active.png',
    'assets/icons/profile_active.png',
  ];

  @override
  Widget build(BuildContext context) {
    final BottomNavbarController controller =
        Get.put(BottomNavbarController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() => pages[controller.currentIndex.value]),
      bottomNavigationBar: _buildBottomNavBar(controller),
    );
  }

  Widget _buildBottomNavBar(BottomNavbarController controller) {
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
        top: false, // 👈 only care about bottom
        child: SizedBox(
          height: 72.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(normalIcons.length, (index) {
              return Obx(() {
                final isSelected =
                    controller.currentIndex.value == index;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.changeIndex(index),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Image.asset(
                      isSelected
                          ? filledIcons[index]
                          : normalIcons[index],
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
