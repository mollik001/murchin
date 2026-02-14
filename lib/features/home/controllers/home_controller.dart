// lib/features/home/controllers/home_controller.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class HomeController extends GetxController {
  final selectedPlatform = 0.obs;
  final isLoading = false.obs;

  RxList<Map<String, dynamic>> events = <Map<String, dynamic>>[].obs;

  String? nextPageUrl; // Track the next page URL

  final polymarketBgColor = const Color(0xFF607D3B);

  @override
  void onInit() {
    super.onInit();
    fetchPolymarketEvents(); // fetch first page
  }

  void selectPlatform(int index) {
    selectedPlatform.value = index;
  }

  /// Fetch Polymarket events
  Future<void> fetchPolymarketEvents({String? url}) async {
    final requestUrl = url ??
        'https://5108-2401-f40-1503-7-b817-4727-d299-219d.ngrok-free.app/api/trade/polymarket-event-list/';
    
    print("🔹 Attempting to fetch Polymarket events from: $requestUrl");

    try {
      isLoading.value = true;

      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {'Content-Type': 'application/json'},
      );

      print("🔹 HTTP STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print("🔹 Server ONLINE. Parsing events...");

        final List<Map<String, dynamic>> fetchedEvents = [];

        if (data['results'] != null && data['results']['events'] != null) {
          for (var event in data['results']['events']) {
            final outcomes = event['question_outcome'] as List<dynamic>;
            String highestTeam = '';
            double highestProb = -1;

            for (var outcome in outcomes) {
              final prob = double.tryParse(outcome['probability'].toString()) ?? 0;
              if (prob > highestProb) {
                highestProb = prob;
                highestTeam = outcome['group_item_title'] ?? '';
              }
            }

            fetchedEvents.add({
              'title': event['title'] ?? '',
              'endDate': event['end_date'] ?? '',
              'team': highestTeam,
              'marketPercentage': highestProb.toStringAsFixed(0),
              'aiPercentage': '68%',
            });
          }
        }

        if (url != null) {
          events.addAll(fetchedEvents);
        } else {
          events.value = fetchedEvents;
        }

        // Save next page URL
        nextPageUrl = data['results']['next'];
        print("🔹 Fetched ${fetchedEvents.length} events. Next page: $nextPageUrl");
      } else {
        print("❌ Server responded with status code ${response.statusCode}");
      }
    } on SocketException {
      print("❌ No Internet connection or server is offline!");
    } catch (e) {
      print("❌ Error fetching Polymarket events: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Load next page if available
  Future<void> loadNextPage() async {
    if (nextPageUrl != null && !isLoading.value) {
      print("🔹 Loading next page: $nextPageUrl");
      await fetchPolymarketEvents(url: nextPageUrl);
    } else {
      print("🔹 No next page or already loading");
    }
  }
}
