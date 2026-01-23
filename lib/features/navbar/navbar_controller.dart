// lib/features/navbar/navbar_controller.dart
import 'package:get/get.dart';

class BottomNavbarController extends GetxController {
  var currentIndex = 0.obs;

  void changeIndex(int index) {
    if (currentIndex.value != index) {
      currentIndex.value = index;
      update(); // Call update to trigger GetBuilder rebuild
    }
  }
  
  @override
  void onInit() {
    super.onInit();
    // Initialize any data here
  }
}