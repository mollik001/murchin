import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:murchin/const/service/endpoint.dart';
import 'package:murchin/features/sports/model/player_props_model.dart';

class PlayerPropsController extends GetxController {
  final isLoading = false.obs;
  final Rx<PlayerPropsResponse?> _playerProps = Rx<PlayerPropsResponse?>(null);

  PlayerPropsResponse? get playerProps => _playerProps.value;

  // AI predictions cache: {category: {playerName: aiValue}}
  final RxMap<String, Map<String, String>> _aiPredictions = <String, Map<String, String>>{}.obs;
  
  // Track which categories have completed AI fetch
  final RxSet<String> _aiLoadedCategories = <String>{}.obs;

  Map<String, String> getAiPredictions(String category) => _aiPredictions[category] ?? {};
  
  /// Check if AI predictions are loaded for a category
  bool isAiLoaded(String category) => _aiLoadedCategories.contains(category);
  
  /// Mark a category as AI loaded
  void markAiLoaded(String category) {
    _aiLoadedCategories.add(category);
    _aiLoadedCategories.refresh();
  }

  @override
  void onInit() {
    super.onInit();
  }

  /// Fetch player props data
  Future<void> fetchPlayerProps({
    required String eventId,
    required String platform,
    bool isMlb = false,
  }) async {
    try {
      isLoading.value = true;
      print('=== Fetching Player Props ===');
      print('Event ID: $eventId, Platform: $platform, isMlb: $isMlb');

      final endpoint = isMlb 
          ? 'api/trade/mlb-players-data' 
          : 'api/trade/sportsbook-players-data';
          
      final url = '${Urls.baseUrl}/$endpoint/$eventId/$platform/';
      print('URL: $url');

      final response = await http.get(Uri.parse(url));

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _playerProps.value = PlayerPropsResponse.fromJson(data);
        print('Player props loaded successfully!');
      } else {
        print('Failed to fetch player props: ${response.statusCode}');
        _playerProps.value = null;
      }
    } catch (e) {
      print('Error fetching player props: $e');
      _playerProps.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get display title for category
  String getCategoryTitle(String category) {
    switch (category) {
      case 'First_Basket': return 'First Basket';
      case 'First_team_basket_scorer': return 'First Team Basket Scorer';
      case 'To_Score_10_Plus_Points': return 'To Score 10+ Points';
      case 'To_Score_25_Plus_Points': return 'To Score 25+ Points';
      case 'Five_Plus_Made_Threes': return '5+ Made Threes';
      case 'To_record_10_Plus_Rebounds': return 'To Record 10+ Rebounds';
      case 'To_record_10_Plus_Assist': return 'To Record 10+ Assists';
      case 'Player_Points': return 'Player Points';
      case 'Player_Made_Threes': return 'Player Made Threes';
      case 'Player_Rebounds': return 'Player Rebounds';
      case 'Player_Assists': return 'Player Assists';
      case 'Player_pts_plus_rebound': return 'Player Pts + Rebound';
      case 'Player_pts_plus_ast': return 'Player Pts + Ast';
      case 'Player_reb_plus_ast': return 'Player Reb + Ast';
      case 'To_record_a_triple_double': return 'To Record a Triple Double';
      // MLB Categories
      case 'batter_home_runs': return 'Batter Home Runs';
      case 'batter_hits': return 'Batter Hits';
      case 'batter_strikeouts': return 'Batter Strikeouts';
      case 'batter_singles': return 'Batter Singles';
      case 'batter_doubles': return 'Batter Doubles';
      case 'batter_triples': return 'Batter Triples';
      case 'totals_1st_1_innings': return 'Totals 1st 1 Inning';
      case 'totals_1st_5_innings': return 'Totals 1st 5 Innings';
      case 'batter_runs_scored': return 'Batter Runs Scored';
      case 'batter_hits_runs_rbis': return 'Batter Hits+Runs+RBIs';
      case 'batter_rbis': return 'Batter RBIs';
      case 'batter_stolen_bases': return 'Batter Stolen Bases';
      case 'pitcher_strikeouts': return 'Pitcher Strikeouts';
      case 'pitcher_outs': return 'Pitcher Outs';
      case 'pitcher_earned_runs': return 'Pitcher Earned Runs';
      case 'pitcher_hits_allowed': return 'Pitcher Hits Allowed';
      default: return category.replaceAll('_', ' ').capitalizeFirst ?? category;
    }
  }

  /// Get list of categories that have data
  List<String> getAvailableCategories() {
    final propsResponse = _playerProps.value;
    if (propsResponse == null) return [];

    // Filter categories that actually have data (not empty maps)
    return propsResponse.props.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList();
  }

  /// Clear player props data
  void clearPlayerProps() {
    _playerProps.value = null;
  }

  /// Fetch AI predictions for Type 1 player props (single value)
  Future<Map<String, String>?> fetchAiForPlayerProps({
    required String category,
    required List<String> teamNames,
    bool isMlb = false,
  }) async {
    try {
      final propsData = _playerProps.value?.getPropsByCategory(category);
      if (propsData == null || propsData.isEmpty) {
        print('No player props data for category: $category');
        return null;
      }

      // Extract player names and their sportsbook values
      final playerNames = <String>[];
      final playerValues = <int>[];

      // Special handling for MLB Inning Totals: Treat as separate Type 1 entries
      final bool isInningTotal = isMlb && (category == 'totals_1st_1_innings' || category == 'totals_1st_5_innings');

      if (isInningTotal) {
        // Doc says: Take over as one player "Over" and under as another "Under"
        final overVal = propsData['over']?.toString().replaceAll('+', '');
        final underVal = propsData['under']?.toString().replaceAll('+', '');
        
        if (overVal != null) {
          playerNames.add('Over');
          playerValues.add(int.tryParse(overVal) ?? 0);
        }
        if (underVal != null) {
          playerNames.add('Under');
          playerValues.add(int.tryParse(underVal) ?? 0);
        }
      } else {
        // Standard Player Mapping
        for (var entry in propsData.entries) {
          final playerName = entry.key;
          final playerData = entry.value;

          // Get sportsbook value (result or over)
          final sportsbookValue = PlayerPropsResponse.getSportsbookValue(playerData);
          if (sportsbookValue != null && sportsbookValue != '-') {
            // Remove '+' and parse
            final cleanValue = sportsbookValue.replaceAll('+', '');
            final parsedValue = int.tryParse(cleanValue);
            if (parsedValue != null) {
              playerNames.add(playerName);
              playerValues.add(parsedValue);
            }
          }
        }
      }

      // Skip if no valid players
      if (playerNames.isEmpty || playerValues.isEmpty) {
        print('No valid players with values for category: $category');
        markAiLoaded(category); // Mark as loaded to stop shimmer
        return null;
      }

      // Get endpoint and title for this category
      final endpoint = PlayerPropsResponse.getEndpointForCategory(category, isMlb: isMlb);
      final title = PlayerPropsResponse.getTitleForCategory(category, isMlb: isMlb);

      // Build request body
      final requestBody = {
        'team_names': teamNames,
        'title': title,
        'player_list': playerNames,
        'player_values': playerValues,
      };

      final mlbBaseUrl = 'https://ai.pickfair.ai/api/v1/mlb';
      final url = '${isMlb ? mlbBaseUrl : Urls.aiBaseUrl}$endpoint';

      print('=== Fetching AI for Player Props (Type 1) ===');
      print('Category: $category, MLB: $isMlb');
      print('URL: $url');
      print('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        print('AI API timeout for $category');
        return http.Response('{"error": "timeout"}', 408);
      });

      print('AI Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiPrediction = data['AI_prediction'] as List<dynamic>?;

        if (aiPrediction != null && aiPrediction.length == playerNames.length) {
          // Map AI predictions to player names
          final aiValues = <String, String>{};
          for (int i = 0; i < playerNames.length; i++) {
            final val = aiPrediction[i] is int ? aiPrediction[i] : (aiPrediction[i] as num).toInt();
            aiValues[playerNames[i]] = (val > 0 ? '+' : '') + val.toString();
          }

          print('AI Predictions for $category: $aiValues');

          // Cache the predictions
          _aiPredictions[category] = aiValues;
          _aiPredictions.refresh();
          
          // Mark this category as loaded
          markAiLoaded(category);

          return aiValues;
        } else {
          print('AI prediction length mismatch or null');
          markAiLoaded(category);
        }
      } else {
        print('AI API failed with status: ${response.statusCode}');
        markAiLoaded(category);
      }

      return null;
    } catch (e) {
      print('Error fetching AI for player props: $e');
      markAiLoaded(category); // Ensure shimmer stops on error
      return null;
    }
  }

  /// Fetch AI predictions for Type 2 player props (Over/Under values)
  Future<Map<String, Map<String, String>>?> fetchAiForType2PlayerProps({
    required String category,
    required List<String> teamNames,
    bool isMlb = false,
  }) async {
    try {
      final propsData = _playerProps.value?.getPropsByCategory(category);
      if (propsData == null || propsData.isEmpty) {
        print('No player props data for category: $category');
        return null;
      }

      // Extract player names and their over/under values
      final playerNames = <String>[];
      final overValues = <int>[];
      final underValues = <int>[];

      for (var entry in propsData.entries) {
        final playerName = entry.key;
        final playerData = entry.value;

        if (playerData is Map) {
          final overStr = playerData['over']?.toString().replaceAll('+', '');
          final underStr = playerData['under']?.toString().replaceAll('+', '');

          final overValue = overStr != null ? int.tryParse(overStr) : null;
          final underValue = underStr != null ? int.tryParse(underStr) : null;

          if (overValue != null && underValue != null) {
            playerNames.add(playerName);
            overValues.add(overValue);
            underValues.add(underValue);
          }
        }
      }

      // Skip if no valid players
      if (playerNames.isEmpty || overValues.isEmpty || underValues.isEmpty) {
        print('No valid players with over/under values for category: $category');
        markAiLoaded(category); // Mark as loaded to stop shimmer
        return null;
      }

      // Get endpoint and title for this category
      final endpoint = PlayerPropsResponse.getEndpointForCategory(category, isMlb: isMlb);
      final title = PlayerPropsResponse.getTitleForCategory(category, isMlb: isMlb);

      // Build request body
      final requestBody = {
        'team_names': teamNames,
        'title': title,
        'player_list': playerNames,
        'over_values': overValues,
        'under_values': underValues,
      };

      final mlbBaseUrl = 'https://ai.pickfair.ai/api/v1/mlb';
      final url = '${isMlb ? mlbBaseUrl : Urls.aiBaseUrl}$endpoint';

      print('=== Fetching AI for Player Props (Type 2) ===');
      print('Category: $category, MLB: $isMlb');
      print('URL: $url');
      print('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        print('AI API timeout for $category');
        return http.Response('{"error": "timeout"}', 408);
      });

      print('AI Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiPredictionOver = data['AI_prediction_over'] as List<dynamic>?;
        final aiPredictionUnder = data['AI_prediction_under'] as List<dynamic>?;

        if (aiPredictionOver != null && aiPredictionUnder != null &&
            aiPredictionOver.length == playerNames.length &&
            aiPredictionUnder.length == playerNames.length) {
          
          // Map AI predictions to player names with over/under keys
          final aiValues = <String, Map<String, String>>{};
          for (int i = 0; i < playerNames.length; i++) {
            final overVal = aiPredictionOver[i] is int ? aiPredictionOver[i] : (aiPredictionOver[i] as num).toInt();
            final underVal = aiPredictionUnder[i] is int ? aiPredictionUnder[i] : (aiPredictionUnder[i] as num).toInt();
            
            aiValues[playerNames[i]] = {
              'over': (overVal > 0 ? '+' : '') + overVal.toString(),
              'under': (underVal > 0 ? '+' : '') + underVal.toString(),
            };
          }

          print('AI Predictions for $category: $aiValues');

          // Cache the predictions - store as JSON string for proper retrieval
          final cachedMap = <String, String>{};
          for (var entry in aiValues.entries) {
            // Store as JSON string to preserve structure
            cachedMap[entry.key] = jsonEncode(entry.value);
          }
          _aiPredictions[category] = cachedMap;
          _aiPredictions.refresh();
          
          // Mark this category as loaded
          markAiLoaded(category);

          return aiValues;
        } else {
          print('AI prediction length mismatch or null');
          markAiLoaded(category);
        }
      } else {
        print('AI API failed with status: ${response.statusCode}');
        markAiLoaded(category);
      }

      return null;
    } catch (e) {
      print('Error fetching AI for Type 2 player props: $e');
      markAiLoaded(category); // Ensure shimmer stops on error
      return null;
    }
  }

  /// Fetch AI for all categories (Type 1 + Type 2) - Auto-detects type based on data structure
  Future<void> fetchAiForAllCategories({
    required List<String> teamNames,
    bool isMlb = false,
  }) async {
    final availableCategories = getAvailableCategories();

    final futures = <Future>[];

    for (var category in availableCategories) {
      final propsData = _playerProps.value?.getPropsByCategory(category);
      if (propsData == null || propsData.isEmpty) continue;

      // Special handling for MLB Inning Totals: Always Type 1 (split into Over/Under)
      final bool isInningTotal = isMlb && (category == 'totals_1st_1_innings' || category == 'totals_1st_5_innings');

      if (isInningTotal) {
        futures.add(fetchAiForPlayerProps(category: category, teamNames: teamNames, isMlb: isMlb));
        continue;
      }

      // Auto-detect type based on data structure
      final firstPlayerData = propsData.values.first;
      
      // If it's a direct prop (not player mapped) and not an inning total we missed
      final bool isDirectProp = propsData.containsKey('over') || propsData.containsKey('result');

      if (isDirectProp) {
        // Direct Props in MLB usually have Over/Under (Type 2) or Single (Type 1)
        final bool hasUnder = propsData.containsKey('under');
        if (hasUnder) {
           // We'll treat Direct Over/Under as Type 2 but wrap it
           // Actually, doc says totals-1st-inning is Type 2 in list API 3-21
           // but user asked to split them into Type 1 Over/Under players.
           // I already handled that in the isInningTotal check above.
        } else {
          futures.add(fetchAiForPlayerProps(category: category, teamNames: teamNames, isMlb: isMlb));
        }
      } else {
        // Player-Mapped Prop
        final isType2 = PlayerPropsResponse.hasOverUnder(firstPlayerData);
        if (isType2) {
          futures.add(fetchAiForType2PlayerProps(category: category, teamNames: teamNames, isMlb: isMlb));
        } else {
          futures.add(fetchAiForPlayerProps(category: category, teamNames: teamNames, isMlb: isMlb));
        }
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
      print('All AI predictions fetched for categories!');
    }
  }

  /// Get AI prediction for Type 2 (Over/Under)
  Map<String, String>? getAiPredictionForType2(String category, String playerName) {
    final aiPredictions = _aiPredictions[category];
    if (aiPredictions == null) return null;
    
    final aiValueStr = aiPredictions[playerName];
    if (aiValueStr == null) return null;
    
    // Parse the JSON string back to map
    try {
      final parsed = jsonDecode(aiValueStr) as Map<String, dynamic>;
      return {
        'over': parsed['over'].toString(),
        'under': parsed['under'].toString(),
      };
    } catch (e) {
      print('Error parsing AI prediction for $playerName: $e');
      return null;
    }
  }
}
