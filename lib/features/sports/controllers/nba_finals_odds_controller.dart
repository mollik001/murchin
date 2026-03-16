import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:murchin/const/service/endpoint.dart';
import 'package:murchin/const/service/shared_preference_helper.dart';
import 'package:murchin/features/sports/model/nba_finals_odds_model.dart';

class NbaFinalsOddsController extends GetxController {
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isAiLoading = false.obs;

  // Store odds by platform
  final Map<String, List<NbaFinalsOdd>> _platformOdds = {};
  final Map<String, String?> _nextPageUrls = {};

  // Store AI predictions by platform
  final Map<String, Map<String, String>> _aiPredictions = {}; // platform -> {teamName: aiValue}

  // Track saved NBA Finals events by platform
  final Set<String> _savedFanduelEventIds = <String>{};
  final Set<String> _savedDraftkingsEventIds = <String>{};
  final Set<String> _savedBetMgmEventIds = <String>{};

  List<NbaFinalsOdd> getOddsForPlatform(String platform) {
    // Try exact match first
    if (_platformOdds.containsKey(platform)) {
      return _platformOdds[platform] ?? [];
    }
    // Try case-insensitive match
    for (var key in _platformOdds.keys) {
      if (key.toLowerCase() == platform.toLowerCase()) {
        return _platformOdds[key] ?? [];
      }
    }
    return [];
  }

  /// Get the team with lowest odds (favorite) for a platform
  NbaFinalsOdd? getLowestOddsTeam(String platform) {
    final odds = getOddsForPlatform(platform);
    print('=== getLowestOddsTeam for $platform: ${odds.length} odds ===');
    if (odds.isEmpty) {
      print('No odds for $platform');
      return null;
    }

    NbaFinalsOdd? lowest;
    double lowestValue = double.infinity;

    for (var odd in odds) {
      final value = odd.priceValue;
      print('Team: ${odd.teamName}, Price: ${odd.price}, Value: $value, AI: ${odd.aiPrediction ?? "null"}');
      if (value < lowestValue) {
        lowestValue = value;
        lowest = odd;
      }
    }

    print('Lowest team for $platform: ${lowest?.teamName} at $lowestValue, AI: ${lowest?.aiPrediction ?? "null"}');
    return lowest;
  }

  /// Get AI prediction for a specific team and platform
  String? getAiPrediction(String platform, String teamName) {
    final platformPredictions = _aiPredictions[platform];
    if (platformPredictions == null) return null;
    
    // Case-insensitive search
    for (var entry in platformPredictions.entries) {
      if (entry.key.toLowerCase() == teamName.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

  /// Check if AI predictions are loaded for a platform
  bool hasAiPredictions(String platform) {
    return _aiPredictions.containsKey(platform) && _aiPredictions[platform]!.isNotEmpty;
  }

  /// Fetch AI predictions for NBA Finals
  Future<void> fetchAiPredictions(String platform) async {
    final odds = getOddsForPlatform(platform);
    if (odds.isEmpty) return;

    isAiLoading.value = true;
    update(); // Notify listeners that AI is loading

    try {
      print('=== Fetching AI Predictions for $platform ===');

      final teamNames = odds.map((odd) => odd.teamName).toList();
      final teamValues = odds.map((odd) {
        try {
          return (double.parse(odd.price)).toInt();
        } catch (e) {
          return 0;
        }
      }).toList();

      final response = await http.post(
        Uri.parse('${Urls.aiBaseUrl}/nba-finals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'team_names': teamNames,
          'team_values': teamValues,
        }),
      ).timeout(const Duration(seconds: 15));

      print('AI Prediction Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiPredictions = data['AI_prediction'] as List<dynamic>? ?? [];

        print('AI Predictions received: $aiPredictions (${aiPredictions.length} predictions for ${teamNames.length} teams)');

        // Store predictions as map of team name to AI value
        final predictionsMap = <String, String>{};
        for (int i = 0; i < teamNames.length && i < aiPredictions.length; i++) {
          predictionsMap[teamNames[i]] = aiPredictions[i].toString();
        }

        _aiPredictions[platform] = predictionsMap;
        print('AI predictions stored for $platform: $predictionsMap');

        // Update odds with AI predictions
        _updateOddsWithAiPredictions(platform);
      } else {
        print('Failed to fetch AI predictions for $platform: ${response.statusCode}');
        // Set AI loading to false even on failure to stop shimmer
        _setAiLoadingComplete(platform);
      }
    } catch (e) {
      print('Error fetching AI predictions for $platform: $e');
      // Set AI loading to false even on error to stop shimmer
      _setAiLoadingComplete(platform);
    }
  }

  /// Set AI loading complete for a platform (stops shimmer)
  void _setAiLoadingComplete(String platform) {
    isAiLoading.value = false;
    
    // Update odds to mark them as not loading
    final odds = _platformOdds[platform] ?? [];
    final updatedOdds = odds.map((odd) {
      return odd.copyWith(isLoadingAi: false);
    }).toList();
    _platformOdds[platform] = updatedOdds;
    
    update();
    refresh();
  }

  /// Update odds list with AI predictions
  void _updateOddsWithAiPredictions(String platform) {
    final odds = _platformOdds[platform] ?? [];
    final predictions = _aiPredictions[platform] ?? {};

    final updatedOdds = odds.map((odd) {
      final aiValue = predictions[odd.teamName];
      return odd.copyWith(
        aiPrediction: aiValue,
        isLoadingAi: false,
      );
    }).toList();

    _platformOdds[platform] = updatedOdds;
    print('Updated ${updatedOdds.length} odds with AI predictions for $platform');
    
    // Notify all listeners
    update();
    refresh();
  }

  @override
  void onInit() {
    super.onInit();
    // Make this controller permanent to prevent disposal
    Get.config(enableLog: false);
    // Load all odds data for all platforms in parallel, then fetch AI predictions
    fetchAllPagesForPlatform('FanDuel').then((_) => fetchAiPredictions('FanDuel'));
    fetchAllPagesForPlatform('DraftKings').then((_) => fetchAiPredictions('DraftKings'));
    fetchAllPagesForPlatform('BetMGM').then((_) => fetchAiPredictions('BetMGM'));
  }

  /// Fetch all pages for a platform
  Future<void> fetchAllPagesForPlatform(String platform) async {
    String? nextPageUrl = Urls.nbaFinalsOddsUrl(platform);
    bool isFirstPage = true;
    int pageCount = 0;
    final maxPages = 10; // Prevent infinite loop

    while (nextPageUrl != null && pageCount < maxPages) {
      await fetchNbaFinalsOdds(platform, url: nextPageUrl, isLoadMore: !isFirstPage);
      isFirstPage = false;
      nextPageUrl = _nextPageUrls[platform];
      pageCount++;

      // Break if next URL is the same as current (API bug)
      if (nextPageUrl != null && nextPageUrl.contains('page=$pageCount')) {
        // Check if we've seen this URL before
        final previousUrl = Urls.nbaFinalsOddsUrl(platform);
        if (nextPageUrl == previousUrl && pageCount > 1) {
          break;
        }
      }
    }

    print('=== All pages loaded for $platform ($pageCount pages) ===');
    
    // Re-apply AI predictions to the final odds list if they exist
    if (_aiPredictions.containsKey(platform) && _aiPredictions[platform]!.isNotEmpty) {
      _updateOddsWithAiPredictions(platform);
    }
  }

  /// Fetch NBA Finals odds from API for a specific platform
  Future<void> fetchNbaFinalsOdds(
    String platform, {
    String? url,
    bool isLoadMore = false,
  }) async {
    if (!isLoadMore) {
      isLoading.value = true;
    } else {
      isRefreshing.value = true;
    }

    try {
      print('=== Fetching NBA Finals Odds for $platform ===');
      final fetchUrl = url ?? Urls.nbaFinalsOddsUrl(platform);
      print('URL: $fetchUrl');

      final response = await http.get(Uri.parse(fetchUrl));

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nbaFinalsResponse = NbaFinalsOddsResponse.fromJson(data);

        print('Total odds: ${nbaFinalsResponse.results.odds.length}');
        print('Next page: ${nbaFinalsResponse.next}');

        if (isLoadMore) {
          final existing = _platformOdds[platform] ?? [];
          _platformOdds[platform] = [...existing, ...nbaFinalsResponse.results.odds];
          print('Stored ${_platformOdds[platform]?.length} odds for $platform (added more)');
        } else {
          _platformOdds[platform] = nbaFinalsResponse.results.odds;
          print('Stored ${_platformOdds[platform]?.length} odds for $platform (initial)');
        }

        _nextPageUrls[platform] = nbaFinalsResponse.next;

        print('Odds loaded successfully for $platform!');
        
        // Re-apply existing AI predictions to newly loaded odds
        if (_aiPredictions.containsKey(platform) && _aiPredictions[platform]!.isNotEmpty) {
          _updateOddsWithAiPredictions(platform);
        }
      } else {
        print('Failed to fetch NBA Finals odds for $platform: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching NBA Finals odds for $platform: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Load more odds (pagination)
  Future<void> loadMoreOdds(String platform) async {
    final nextPageUrl = _nextPageUrls[platform];
    if (nextPageUrl != null) {
      await fetchNbaFinalsOdds(platform, url: nextPageUrl, isLoadMore: true);
    }
  }

  /// Refresh odds for a platform
  Future<void> refreshOdds(String platform) async {
    await fetchNbaFinalsOdds(platform);
  }

  /// Format date for display
  String formatPrettyDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  /// Get background color by platform
  Color getPlatformBgColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'fanduel':
        return const Color(0xFF559CEE);
      case 'draftkings':
        return const Color(0xFF218B28);
      case 'betmgm':
        return const Color(0xFFA79D2C);
      default:
        return const Color(0xFF8D9AB1);
    }
  }

  /// Check if an NBA Finals event is saved
  bool isNbaFinalsEventSaved(String eventId, String platform) {
    switch (platform) {
      case 'FanDuel':
      case 'Fanduel':
      case 'fanduel':
        return _savedFanduelEventIds.contains(eventId);
      case 'DraftKings':
      case 'Draftkings':
      case 'draftkings':
        return _savedDraftkingsEventIds.contains(eventId);
      case 'BetMGM':
      case 'Betmgm':
      case 'betmgm':
        return _savedBetMgmEventIds.contains(eventId);
      default:
        return false;
    }
  }

  /// Save/Unsave NBA Finals event
  Future<bool> saveNbaFinalsEvent({
    required String eventId,
    required String platform,
  }) async {
    try {
      final url = '${Urls.baseUrl}/api/trade/saved-event/';
      print('=== Save NBA Finals Event API ===');
      print('URL: $url');

      // Get token from SharedPreferencesHelper
      final token = await SharedPreferencesHelper.getAccessToken();
      print('Token: ${token?.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'event_id': eventId,
          'market_place': 'NBA Finals',
        }),
      );

      print('Request Body: {event_id: $eventId, market_place: NBA Finals}');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=====================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('NBA Finals event saved successfully!');
        // Toggle local state
        switch (platform) {
          case 'FanDuel':
          case 'Fanduel':
          case 'fanduel':
            if (_savedFanduelEventIds.contains(eventId)) {
              _savedFanduelEventIds.remove(eventId);
            } else {
              _savedFanduelEventIds.add(eventId);
            }
            break;
          case 'DraftKings':
          case 'Draftkings':
          case 'draftkings':
            if (_savedDraftkingsEventIds.contains(eventId)) {
              _savedDraftkingsEventIds.remove(eventId);
            } else {
              _savedDraftkingsEventIds.add(eventId);
            }
            break;
          case 'BetMGM':
          case 'Betmgm':
          case 'betmgm':
            if (_savedBetMgmEventIds.contains(eventId)) {
              _savedBetMgmEventIds.remove(eventId);
            } else {
              _savedBetMgmEventIds.add(eventId);
            }
            break;
        }
        update();
        return true;
      } else {
        print('Failed to save NBA Finals event: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Save NBA Finals event error: $e');
      return false;
    }
  }

  @override
  void onClose() {
    // Don't dispose - keep controller persistent
    // This prevents data loss when navigating between screens
    super.onClose();
  }
}
