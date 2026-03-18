import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:murchin/const/service/endpoint.dart';

class AiPredictionController extends GetxController {
  final isLoading = false.obs;
  final RxMap<String, String> aiPredictions = <String, String>{}.obs;

  // Singleton HTTP client for connection reuse (keep-alive)
  final http.Client _httpClient = http.Client();

  // Request deduplication
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, Future<http.Response>> _pendingRequests = {};

  /// Fetch AI prediction for a specific event and platform
  Future<Map<String, String>?> fetchAiPredictions({
    required String awayTeam,
    required String homeTeam,
    required String? spreadAway,
    required String? spreadHome,
    required String? moneylineAway,
    required String? moneylineHome,
    required String? totalOver,
    required String? totalUnder,
  }) async {
    // Create cache key for deduplication
    final cacheKey = '${awayTeam}_vs_${homeTeam}';

    // Check if request is already in progress
    if (_pendingRequests.containsKey(cacheKey)) {
      print("⏳ Waiting for pending AI request: $cacheKey");
      try {
        final response = await _pendingRequests[cacheKey]!.timeout(
          const Duration(seconds: 30),
        );
        return _processResponse(response);
      } on TimeoutException {
        print("⚠️ AI API timeout after 30s for $cacheKey");
        return null;
      }
    }

    // Check if we made a recent request (within 3 seconds)
    final now = DateTime.now();
    if (_lastRequestTime.containsKey(cacheKey)) {
      final timeDiff = now.difference(_lastRequestTime[cacheKey]!);
      if (timeDiff.inSeconds < 3) {
        print("⚡ Skipping duplicate AI request (too soon): $cacheKey");
        return null;
      }
    }

    isLoading.value = true;

    try {
      // Build team names list
      final teamNames = [awayTeam, homeTeam];

      // Build market values
      final marketValues = <String, List<dynamic>>{};

      // H2H (moneyline) values
      if (moneylineAway != null && moneylineAway != '-' && moneylineAway != 'N/A') {
        marketValues['moneyline'] = [
          int.tryParse(moneylineAway) ?? 0,
          int.tryParse(moneylineHome ?? '0') ?? 0,
        ];
      }

      // Spread values
      if (spreadAway != null && spreadAway != '-' && spreadAway != 'N/A') {
        marketValues['spread'] = [
          int.tryParse(spreadAway) ?? 0,
          int.tryParse(spreadHome ?? '0') ?? 0,
        ];
      }

      // Totals values
      if (totalOver != null && totalOver != '-' && totalOver != 'N/A') {
        marketValues['totals'] = [
          int.tryParse(totalOver) ?? 0,
          int.tryParse(totalUnder ?? '0') ?? 0,
        ];
      }

      // Prepare request body
      final requestBody = {
        'team_names': teamNames,
        'market_values': marketValues,
      };

      print("=== Fetching AI Predictions ===");
      print("URL: ${Urls.aiSportsbookGameLinesUrl}");
      print("Request Body: $requestBody");

      // Mark request as pending
      final future = _httpClient.post(
        Uri.parse(Urls.aiSportsbookGameLinesUrl),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
        },
        body: jsonEncode(requestBody),
      );

      _pendingRequests[cacheKey] = future;
      _lastRequestTime[cacheKey] = now;

      http.Response response;
      try {
        response = await future.timeout(const Duration(seconds: 30));
      } on TimeoutException {
        print("⚠️ AI API timeout after 30s for $cacheKey");
        response = http.Response('{"error": "timeout"}', 408);
      }

      print("AI Response Status: ${response.statusCode}");

      return _processResponse(response);
    } catch (e) {
      print("❌ Error fetching AI predictions: $e");
      return null;
    } finally {
      isLoading.value = false;
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Process AI response and extract predictions
  Map<String, String>? _processResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final aiPrediction = data['AI_prediction'];

        if (aiPrediction != null) {
          final aiSpread = aiPrediction['spread'] as List<dynamic>?;
          final aiMoneyline = aiPrediction['moneyline'] as List<dynamic>?;
          final aiTotals = aiPrediction['totals'] as List<dynamic>?;

          // Format spread values
          String aiSpreadAwayValue = 'N/A';
          String aiSpreadHomeValue = 'N/A';
          if (aiSpread != null && aiSpread.length == 2) {
            aiSpreadAwayValue = aiSpread[0].toString();
            aiSpreadHomeValue = aiSpread[1].toString();
          }

          // Format moneyline values
          String aiMoneylineAwayValue = 'N/A';
          String aiMoneylineHomeValue = 'N/A';
          if (aiMoneyline != null && aiMoneyline.length == 2) {
            final awayValue = aiMoneyline[0] is int
                ? aiMoneyline[0]
                : (aiMoneyline[0] as num).toInt();
            final homeValue = aiMoneyline[1] is int
                ? aiMoneyline[1]
                : (aiMoneyline[1] as num).toInt();
            aiMoneylineAwayValue = awayValue.toString();
            aiMoneylineHomeValue = homeValue.toString();
          }

          // Format totals values
          String aiTotalOverValue = 'N/A';
          String aiTotalUnderValue = 'N/A';
          if (aiTotals != null && aiTotals.length == 2) {
            aiTotalOverValue = aiTotals[0].toString();
            aiTotalUnderValue = aiTotals[1].toString();
          }

          print(
              "✅ AI Predictions: Spread[$aiSpreadAwayValue, $aiSpreadHomeValue] Money[$aiMoneylineAwayValue, $aiMoneylineHomeValue] Total[$aiTotalOverValue, $aiTotalUnderValue]");

          return {
            'aiSpreadAway': aiSpreadAwayValue,
            'aiSpreadHome': aiSpreadHomeValue,
            'aiMoneylineAway': aiMoneylineAwayValue,
            'aiMoneylineHome': aiMoneylineHomeValue,
            'aiTotalOver': aiTotalOverValue,
            'aiTotalUnder': aiTotalUnderValue,
          };
        }
      } catch (e) {
        print("❌ Error decoding AI response: $e");
      }
    }

    print("❌ AI prediction failed or returned invalid data");
    return null;
  }

  /// Fetch with retry logic for critical predictions
  Future<Map<String, String>?> fetchAiPredictionsWithRetry({
    required String awayTeam,
    required String homeTeam,
    required String? spreadAway,
    required String? spreadHome,
    required String? moneylineAway,
    required String? moneylineHome,
    required String? totalOver,
    required String? totalUnder,
    int maxRetries = 2,
  }) async {
    int attempt = 0;
    Duration delay = const Duration(seconds: 2);

    while (attempt <= maxRetries) {
      final result = await fetchAiPredictions(
        awayTeam: awayTeam,
        homeTeam: homeTeam,
        spreadAway: spreadAway,
        spreadHome: spreadHome,
        moneylineAway: moneylineAway,
        moneylineHome: moneylineHome,
        totalOver: totalOver,
        totalUnder: totalUnder,
      );

      if (result != null) {
        return result;
      }

      attempt++;
      if (attempt <= maxRetries) {
        print("🔄 AI Retry attempt $attempt/$maxRetries after ${delay.inSeconds}s");
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }

    return null;
  }

  @override
  void onClose() {
    _httpClient.close();
    super.onClose();
  }
}
