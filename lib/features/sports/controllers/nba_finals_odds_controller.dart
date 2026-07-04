import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:murcin/const/service/endpoint.dart';
import 'package:murcin/const/service/shared_preference_helper.dart';
import 'package:murcin/features/sports/model/nba_finals_odds_model.dart';

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

  // NBA Finals odds caching - 30 minutes cache for event page
  static const String _nbaFinalsCacheKey = 'cached_nba_finals_odds_v1';
  static const String _nbaFinalsCacheTimestampKey = 'cached_nba_finals_timestamp_v1';
  static const Duration _nbaFinalsCacheDuration = Duration(minutes: 30);

  // Singleton HTTP client for connection reuse (keep-alive)
  final http.Client httpClient = http.Client();

  // Request deduplication for AI predictions
  final Map<String, DateTime> _lastAiRequestTime = {};
  final Map<String, Future<http.Response>> _pendingAiRequests = {};

  // Public getters for details page access
  Map<String, Future<http.Response>> get pendingAiRequests => _pendingAiRequests;
  Map<String, Map<String, String>> get aiPredictions => _aiPredictions;

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

  /// Check if there are more pages to load for a platform
  bool hasMorePages(String platform) {
    return _nextPageUrls[platform] != null;
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

    // Create cache key for deduplication
    final cacheKey = 'nba_finals_$platform';

    // Check if request is already in progress
    if (_pendingAiRequests.containsKey(cacheKey)) {
      print("⏳ Waiting for pending NBA Finals AI request: $cacheKey");
      try {
        final response = await _pendingAiRequests[cacheKey]!.timeout(
          const Duration(seconds: 30),
        );
        await _processNbaAiResponse(response, platform, odds);
      } on TimeoutException {
        print("⚠️ NBA Finals AI API timeout after 30s for $cacheKey");
        _setAiLoadingComplete(platform);
      }
      return;
    }

    // Check if we made a recent request (within 3 seconds)
    final now = DateTime.now();
    if (_lastAiRequestTime.containsKey(cacheKey)) {
      final timeDiff = now.difference(_lastAiRequestTime[cacheKey]!);
      if (timeDiff.inSeconds < 3) {
        print("⚡ Skipping duplicate NBA Finals AI request (too soon): $cacheKey");
        _setAiLoadingComplete(platform);
        return;
      }
    }

    isAiLoading.value = true;
    update(); // Notify listeners that AI is loading

    try {
      print('=== Fetching AI Predictions for $platform ===');

      // AI API can only handle 10 teams at a time, so fetch for first 10 teams (favorites)
      final teamsToFetch = odds.length > 10 ? odds.take(10).toList() : odds;
      
      final teamNames = teamsToFetch.map((odd) => odd.teamName).toList();
      final teamValues = teamsToFetch.map((odd) {
        try {
          return (double.parse(odd.price)).toInt();
        } catch (e) {
          return 0;
        }
      }).toList();

      print('Fetching AI for ${teamNames.length} teams: $teamNames');

      // Mark request as pending
      final future = httpClient.post(
        Uri.parse('${Urls.aiBaseUrl}/nba-finals'),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
        },
        body: jsonEncode({
          'team_names': teamNames,
          'team_values': teamValues,
        }),
      );

      _pendingAiRequests[cacheKey] = future;
      _lastAiRequestTime[cacheKey] = now;

      http.Response response;
      try {
        response = await future.timeout(const Duration(seconds: 30)); // Increased from 15s to 30s
      } on TimeoutException {
        print("⚠️ NBA Finals AI API timeout after 30s for $platform");
        response = http.Response('{"error": "timeout"}', 408);
      }

      await _processNbaAiResponse(response, platform, odds);
    } catch (e) {
      print('Error fetching AI predictions for $platform: $e');
      // Set AI loading to false even on error to stop shimmer
      _setAiLoadingComplete(platform);
    } finally {
      _pendingAiRequests.remove(cacheKey);
    }
  }

  /// Process NBA Finals AI response
  Future<void> _processNbaAiResponse(http.Response response, String platform, List<NbaFinalsOdd> odds) async {
    print('AI Prediction Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final aiPredictions = data['AI_prediction'] as List<dynamic>? ?? [];

        print('AI Predictions received: $aiPredictions (${aiPredictions.length} predictions for ${odds.length} teams)');

        // Store predictions as map of team name to AI value
        final predictionsMap = <String, String>{};
        final teamNames = odds.map((odd) => odd.teamName).toList();

        for (int i = 0; i < teamNames.length && i < aiPredictions.length; i++) {
          predictionsMap[teamNames[i]] = aiPredictions[i].toString();
        }

        _aiPredictions[platform] = predictionsMap;
        print('AI predictions stored for $platform: $predictionsMap');

        // Update odds with AI predictions
        _updateOddsWithAiPredictions(platform);
      } catch (e) {
        print('Error decoding NBA Finals AI response: $e');
        _setAiLoadingComplete(platform);
      }
    } else {
      print('Failed to fetch AI predictions for $platform: ${response.statusCode}');
      // Set AI loading to false even on failure to stop shimmer
      _setAiLoadingComplete(platform);
    }
  }

  /// Set AI loading complete for a platform (stops shimmer)
  void _setAiLoadingComplete(String platform) {
    isAiLoading.value = false;

    // Update odds to mark them as not loading
    // IMPORTANT: Don't overwrite existing aiPrediction values
    final odds = _platformOdds[platform] ?? [];
    final updatedOdds = odds.map((odd) {
      return odd.copyWith(
        isLoadingAi: false,
        // Preserve existing aiPrediction if it exists
        aiPrediction: odd.aiPrediction,
      );
    }).toList();
    _platformOdds[platform] = updatedOdds;

    update();
    refresh();
  }

  /// Expose setAiLoadingComplete for details page
  void setAiLoadingComplete(String platform) => _setAiLoadingComplete(platform);

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

  /// Expose updateOddsWithAiPredictions for details page
  void updateOddsWithAiPredictions(String platform) => _updateOddsWithAiPredictions(platform);

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

      final response = await httpClient.get(Uri.parse(fetchUrl));

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

        // Notify UI to rebuild after loading odds
        update();

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

  // ================= NBA FINALS ODDS CACHING (30 MIN) =================

  /// Load cached NBA Finals odds
  Future<bool> loadCachedNbaFinalsOdds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTimestampStr = prefs.getString(_nbaFinalsCacheTimestampKey);

      if (cachedTimestampStr == null) {
        print('No cached NBA Finals odds found');
        return false;
      }

      final timestamp = DateTime.parse(cachedTimestampStr);
      final now = DateTime.now();

      if (now.difference(timestamp) > _nbaFinalsCacheDuration) {
        print('NBA Finals odds cache expired (30 min) - will fetch fresh data');
        return false;
      }

      final cachedData = prefs.getString(_nbaFinalsCacheKey);
      if (cachedData == null) return false;

      final List decoded = jsonDecode(cachedData);

      // Restore odds from cache
      if (decoded is List && decoded.isNotEmpty) {
        for (var item in decoded) {
          if (item is Map<String, dynamic>) {
            final platform = item['platform'] as String?;
            final oddsData = item['odds'] as List<dynamic>?;

            if (platform == null || oddsData == null) continue;

            final oddsList = oddsData
                .map((o) => NbaFinalsOdd.fromJson(o as Map<String, dynamic>))
                .toList();

            if (oddsList.isNotEmpty) {
              _platformOdds[platform] = oddsList;
              print('Loaded ${oddsList.length} cached NBA Finals odds for $platform');
            }
          }
        }

        if (_platformOdds.isNotEmpty) {
          update();
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error loading cached NBA Finals odds: $e');
      return false;
    }
  }

  /// Cache NBA Finals odds to local storage (30 min)
  Future<void> cacheNbaFinalsOdds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> dataToCache = [];

      // Cache odds for each platform
      for (var entry in _platformOdds.entries) {
        final platform = entry.key;
        final odds = entry.value;

        dataToCache.add({
          'platform': platform,
          'odds': odds.map((odd) => odd.toJson()).toList(),
        });
      }

      if (dataToCache.isEmpty) return;

      await prefs.setString(_nbaFinalsCacheKey, jsonEncode(dataToCache));
      await prefs.setString(
        _nbaFinalsCacheTimestampKey,
        DateTime.now().toIso8601String(),
      );

      print('Cached NBA Finals odds for ${_platformOdds.length} platforms (30 min)');
    } catch (e) {
      print('Error caching NBA Finals odds: $e');
    }
  }

  /// Fetch NBA Finals odds with caching
  Future<void> fetchNbaFinalsOddsWithCache() async {
    // Try to load cached data first
    final hasValidCache = await loadCachedNbaFinalsOdds();

    if (hasValidCache) {
      print('NBA Finals: Loaded from cache, fetching fresh data in background');
      // Fetch fresh data in background
      _fetchNbaFinalsOddsInBackground();
    } else {
      print('NBA Finals: No valid cache, fetching fresh data');
      // No valid cache, fetch fresh data
      await _fetchNbaFinalsOddsInBackground();
    }
  }

  /// Fetch fresh NBA Finals odds in background
  Future<void> _fetchNbaFinalsOddsInBackground() async {
    try {
      print('=== Fetching NBA Finals Odds in Background ===');

      // Only fetch FIRST page for each platform (not all pages)
      // User can scroll to load more pages via infinite scroll
      await Future.wait([
        fetchNbaFinalsOdds('FanDuel'),
        fetchNbaFinalsOdds('DraftKings'),
        fetchNbaFinalsOdds('BetMGM'),
      ]);

      // Cache the fresh data
      cacheNbaFinalsOdds();
    } catch (e) {
      print('Error fetching NBA Finals odds in background: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Make this controller permanent to prevent disposal
    Get.config(enableLog: false);
    // Load cached NBA Finals odds first, then fetch fresh data in background
    fetchNbaFinalsOddsWithCache();
  }

  @override
  void onClose() {
    httpClient.close();
    // Don't dispose - keep controller persistent
    // This prevents data loss when navigating between screens
    super.onClose();
  }
}
