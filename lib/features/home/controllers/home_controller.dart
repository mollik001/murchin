// Home Controller
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class HomeController extends GetxController {
  final selectedPlatform = 0.obs; // 0: All Platforms, 1: Polymarket, 2: Kalshi
  
  void selectPlatform(int index) {
    selectedPlatform.value = index;
  }
}