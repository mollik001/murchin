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
  }) async {
    try {
      isLoading.value = true;
      print('=== Fetching Player Props ===');
      print('Event ID: $eventId, Platform: $platform');

      final url = '${Urls.baseUrl}/api/trade/sportsbook-players-data/$eventId/$platform/';
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
      case 'First_Basket':
        return 'First Basket';
      case 'First_team_basket_scorer':
        return 'First Team Basket Scorer';
      case 'To_Score_10_Plus_Points':
        return 'To Score 10+ Points';
      case 'To_Score_25_Plus_Points':
        return 'To Score 25+ Points';
      case 'Five_Plus_Made_Threes':
        return '5+ Made Threes';
      case 'To_record_10_Plus_Rebounds':
        return 'To Record 10+ Rebounds';
      case 'To_record_10_Plus_Assist':
        return 'To Record 10+ Assists';
      case 'Player_Points':
        return 'Player Points';
      case 'Player_Made_Threes':
        return 'Player Made Threes';
      case 'Player_Rebounds':
        return 'Player Rebounds';
      case 'Player_Assists':
        return 'Player Assists';
      case 'Player_pts_plus_rebound':
        return 'Player Pts + Rebound';
      case 'Player_pts_plus_ast':
        return 'Player Pts + Ast';
      case 'Player_reb_plus_ast':
        return 'Player Reb + Ast';
      case 'To_record_a_triple_double':
        return 'To Record a Triple Double';
      default:
        return category;
    }
  }

  /// Get list of categories that have data
  List<String> getAvailableCategories() {
    final props = _playerProps.value;
    if (props == null) return [];

    final categories = <String>[];
    
    if (props.firstBasket.isNotEmpty) categories.add('First_Basket');
    if (props.firstTeamBasketScorer.isNotEmpty) categories.add('First_team_basket_scorer');
    if (props.toScore10PlusPoints.isNotEmpty) categories.add('To_Score_10_Plus_Points');
    if (props.toScore25PlusPoints.isNotEmpty) categories.add('To_Score_25_Plus_Points');
    if (props.fivePlusMadeThrees.isNotEmpty) categories.add('Five_Plus_Made_Threes');
    if (props.toRecord10PlusRebounds.isNotEmpty) categories.add('To_record_10_Plus_Rebounds');
    if (props.toRecord10PlusAssist.isNotEmpty) categories.add('To_record_10_Plus_Assist');
    if (props.playerPoints.isNotEmpty) categories.add('Player_Points');
    if (props.playerMadeThrees.isNotEmpty) categories.add('Player_Made_Threes');
    if (props.playerRebounds.isNotEmpty) categories.add('Player_Rebounds');
    if (props.playerAssists.isNotEmpty) categories.add('Player_Assists');
    if (props.playerPtsPlusRebound.isNotEmpty) categories.add('Player_pts_plus_rebound');
    if (props.playerPtsPlusAst.isNotEmpty) categories.add('Player_pts_plus_ast');
    if (props.playerRebPlusAst.isNotEmpty) categories.add('Player_reb_plus_ast');
    if (props.toRecordATripleDouble.isNotEmpty) categories.add('To_record_a_triple_double');

    return categories;
  }

  /// Clear player props data
  void clearPlayerProps() {
    _playerProps.value = null;
  }

  /// Fetch AI predictions for Type 1 player props (single value)
  Future<Map<String, String>?> fetchAiForPlayerProps({
    required String category,
    required List<String> teamNames,
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

      // Skip if no valid players
      if (playerNames.isEmpty || playerValues.isEmpty) {
        print('No valid players with values for category: $category');
        return null;
      }

      // Get endpoint and title for this category
      final endpoint = PlayerPropsResponse.getEndpointForCategory(category);
      final title = PlayerPropsResponse.getTitleForCategory(category);

      // Build request body
      final requestBody = {
        'team_names': teamNames,
        'title': title,
        'player_list': playerNames,
        'player_values': playerValues,
      };

      final url = '${Urls.aiBaseUrl}$endpoint';

      print('=== Fetching AI for Player Props ===');
      print('Category: $category');
      print('Endpoint: $endpoint');
      print('URL: $url');
      print('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('AI Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiPrediction = data['AI_prediction'] as List<dynamic>?;

        if (aiPrediction != null && aiPrediction.length == playerNames.length) {
          // Map AI predictions to player names
          final aiValues = <String, String>{};
          for (int i = 0; i < playerNames.length; i++) {
            final aiValue = aiPrediction[i].toString();
            aiValues[playerNames[i]] = aiValue;
          }

          print('AI Predictions for $category: $aiValues');

          // Cache the predictions
          _aiPredictions[category] = aiValues.map((key, value) => 
            MapEntry(key, value)
          );
          _aiPredictions.refresh();
          
          // Mark this category as loaded
          markAiLoaded(category);

          return aiValues;
        } else {
          print('AI prediction length mismatch or null');
        }
      } else {
        print('AI API failed with status: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      print('Error fetching AI for player props: $e');
      return null;
    }
  }

  /// Fetch AI for all Type 1 categories
  Future<void> fetchAiForAllType1Categories({
    required List<String> teamNames,
  }) async {
    final type1Categories = [
      'First_Basket',
      'First_team_basket_scorer',
      'To_Score_10_Plus_Points',
      'To_Score_25_Plus_Points',
      'Five_Plus_Made_Threes',
      'To_record_10_Plus_Rebounds',
      'To_record_10_Plus_Assist',
      'To_record_a_triple_double',
    ];

    final futures = <Future>[];

    for (var category in type1Categories) {
      final propsData = _playerProps.value?.getPropsByCategory(category);
      if (propsData != null && propsData.isNotEmpty) {
        futures.add(fetchAiForPlayerProps(category: category, teamNames: teamNames));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
      print('All Type 1 AI predictions fetched!');
    }
  }

  /// Fetch AI predictions for Type 2 player props (Over/Under values)
  Future<Map<String, Map<String, String>>?> fetchAiForType2PlayerProps({
    required String category,
    required List<String> teamNames,
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
        return null;
      }

      // Get endpoint and title for this category
      final endpoint = PlayerPropsResponse.getEndpointForCategory(category);
      final title = PlayerPropsResponse.getTitleForCategory(category);

      // Build request body
      final requestBody = {
        'team_names': teamNames,
        'title': title,
        'player_list': playerNames,
        'over_values': overValues,
        'under_values': underValues,
      };

      final url = '${Urls.aiBaseUrl}$endpoint';

      print('=== Fetching AI for Type 2 Player Props ===');
      print('Category: $category');
      print('Endpoint: $endpoint');
      print('URL: $url');
      print('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

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
            aiValues[playerNames[i]] = {
              'over': aiPredictionOver[i].toString(),
              'under': aiPredictionUnder[i].toString(),
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
        }
      } else {
        print('AI API failed with status: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      print('Error fetching AI for Type 2 player props: $e');
      return null;
    }
  }

  /// Fetch AI for all Type 2 categories
  Future<void> fetchAiForAllType2Categories({
    required List<String> teamNames,
  }) async {
    final type2Categories = [
      'Player_Points',
      'Player_Made_Threes',
      'Player_Rebounds',
      'Player_Assists',
      'Player_pts_plus_rebound',
      'Player_pts_plus_ast',
      'Player_reb_plus_ast',
    ];

    final futures = <Future>[];

    for (var category in type2Categories) {
      final propsData = _playerProps.value?.getPropsByCategory(category);
      if (propsData != null && propsData.isNotEmpty) {
        futures.add(fetchAiForType2PlayerProps(category: category, teamNames: teamNames));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
      print('All Type 2 AI predictions fetched!');
    }
  }

  /// Fetch AI for all categories (Type 1 + Type 2) - Auto-detects type based on data structure
  Future<void> fetchAiForAllCategories({
    required List<String> teamNames,
  }) async {
    final allCategories = [
      'First_Basket',
      'First_team_basket_scorer',
      'To_Score_10_Plus_Points',
      'To_Score_25_Plus_Points',
      'Five_Plus_Made_Threes',
      'To_record_10_Plus_Rebounds',
      'To_record_10_Plus_Assist',
      'To_record_a_triple_double',
      'Player_Points',
      'Player_Made_Threes',
      'Player_Rebounds',
      'Player_Assists',
      'Player_pts_plus_rebound',
      'Player_pts_plus_ast',
      'Player_reb_plus_ast',
    ];

    final futures = <Future>[];

    for (var category in allCategories) {
      final propsData = _playerProps.value?.getPropsByCategory(category);
      if (propsData == null || propsData.isEmpty) continue;

      // Auto-detect type based on data structure
      final firstPlayerData = propsData.values.first;
      final isType2 = PlayerPropsResponse.hasOverUnder(firstPlayerData);

      if (isType2) {
        // Type 2: Has over/under values
        futures.add(fetchAiForType2PlayerProps(category: category, teamNames: teamNames));
      } else {
        // Type 1: Single value
        futures.add(fetchAiForPlayerProps(category: category, teamNames: teamNames));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
      print('All AI predictions fetched (auto-detected types)!');
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
