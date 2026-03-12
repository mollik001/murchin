import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:murchin/const/service/endpoint.dart';

class AiPredictionController extends GetxController {
  final isLoading = false.obs;
  final RxMap<String, String> aiPredictions = <String, String>{}.obs;

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

      final response = await http.post(
        Uri.parse(Urls.aiSportsbookGameLinesUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print("AI Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
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

          // Format moneyline values - no '+' sign for positive values
          String aiMoneylineAwayValue = 'N/A';
          String aiMoneylineHomeValue = 'N/A';
          if (aiMoneyline != null && aiMoneyline.length == 2) {
            final awayValue = aiMoneyline[0] is int ? aiMoneyline[0] : (aiMoneyline[0] as num).toInt();
            final homeValue = aiMoneyline[1] is int ? aiMoneyline[1] : (aiMoneyline[1] as num).toInt();
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

          print("AI Predictions: Spread[$aiSpreadAwayValue, $aiSpreadHomeValue] Money[$aiMoneylineAwayValue, $aiMoneylineHomeValue] Total[$aiTotalOverValue, $aiTotalUnderValue]");

          return {
            'aiSpreadAway': aiSpreadAwayValue,
            'aiSpreadHome': aiSpreadHomeValue,
            'aiMoneylineAway': aiMoneylineAwayValue,
            'aiMoneylineHome': aiMoneylineHomeValue,
            'aiTotalOver': aiTotalOverValue,
            'aiTotalUnder': aiTotalUnderValue,
          };
        }
      }

      print("AI prediction failed or returned invalid data");
      return null;
    } catch (e) {
      print("Error fetching AI predictions: $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
