import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:murchin/const/service/endpoint.dart';
import 'package:murchin/const/service/shared_preference_helper.dart';
import 'package:murchin/features/sports/home/model/sportsbook_model.dart';

class SportsHomeController extends GetxController {
  final selectedPlatform = 0.obs; // 0: All, 1: Fanduel, 2: Draftkings, 3: BetMGM

  final isLoading = false.obs;
  final isPageLoading = false.obs;
  final isRefreshing = false.obs;
  final isSearching = false.obs;
  final hasActiveSearch = false.obs;

  final RxList<SportsbookEvent> _sportsbookEvents = <SportsbookEvent>[].obs;
  final RxList<SportsbookEvent> _searchResults = <SportsbookEvent>[].obs;

  List<SportsbookEvent> get sportsbookEvents => _sportsbookEvents;
  List<SportsbookEvent> get searchResults => _searchResults;

  String? nextPageUrl;

  List<Map<String, dynamic>> get savedFanduelEvents => _savedFanduelEvents;
  List<Map<String, dynamic>> get savedDraftkingsEvents => _savedDraftkingsEvents;

  final Set<String> _savedFanduelEventIds = <String>{};
  final Set<String> _savedDraftkingsEventIds = <String>{};
  final Set<String> _savedBetMgmEventIds = <String>{};
  final RxList<Map<String, dynamic>> _savedFanduelEvents = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _savedDraftkingsEvents = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _savedBetMgmEvents = <Map<String, dynamic>>[].obs;

  final TextEditingController searchController = TextEditingController();

  // AI caching constants
  static const String _cacheKey = 'cached_sportsbook_ai_values';
  static const String _cacheTimestampKey = 'cached_sportsbook_ai_timestamp';
  static const Duration _cacheDuration = Duration(hours: 12);
  static const int _maxCachedEvents = 10;

  final Set<int> _cachedEventIndexes = <int>{};
  static const int _maxEventsPerSection = 10;

  @override
  void onInit() {
    super.onInit();
    fetchSavedEvents();
    
    // Load cached AI data first
    loadCachedAIData().then((hasValidCache) async {
      if (hasValidCache) {
        loadEventsWithCachedAI();
        await fetchSportsbookEvents(backgroundOnly: true);
      } else {
        await fetchSportsbookEvents();
      }
    });
  }

  /// Fetch sportsbook events from API
  Future<void> fetchSportsbookEvents({bool backgroundOnly = false}) async {
    if (!backgroundOnly) {
      isLoading.value = true;
    }

    try {
      print("=== Fetching Sportsbook Events ===");
      print("URL: ${Urls.sportsbookModelUrl}");

      final response = await http.get(Uri.parse(Urls.sportsbookModelUrl));

      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sportsbookResponse = SportsbookResponse.fromJson(data);

        print("Total events: ${sportsbookResponse.results.events.length}");
        print("Next page: ${sportsbookResponse.next}");

        // Limit to 10 events maximum
        List<SportsbookEvent> eventsList = sportsbookResponse.results.events;
        if (eventsList.length > _maxEventsPerSection) {
          eventsList = eventsList.take(_maxEventsPerSection).toList();
        }

        _sportsbookEvents.assignAll(eventsList);
        nextPageUrl = sportsbookResponse.next;

        print("Events loaded successfully! (Showing ${eventsList.length} events)");

        // Fetch AI predictions for each bookmark in all events
        int aiFetchCount = 0;
        for (int i = 0; i < eventsList.length; i++) {
          final event = eventsList[i];
          
          // Fetch AI for each bookmark in the event
          for (int j = 0; j < event.bookmark.length; j++) {
            final bookmark = event.bookmark[j];
            
            // Skip if AI data already exists for this bookmark
            if (bookmark.aiMoneylineAway != null) {
              continue;
            }
            
            fetchAIForBookmark(event, bookmark, i, j).then((aiData) async {
              // Skip if AI data is null
              if (aiData == null) {
                print("Sportsbook AI returned null for bookmark");
                return;
              }
              
              final idx = _sportsbookEvents.indexWhere(
                (ev) => ev.eventId == event.eventId,
              );
              
              if (idx != -1) {
                final currentEvent = _sportsbookEvents[idx];
                final currentBookmarks = List<Bookmark>.from(currentEvent.bookmark);
                
                // Update the specific bookmark with AI data
                currentBookmarks[j] = bookmark.copyWith(
                  aiSpreadAway: aiData['aiSpreadAway'],
                  aiSpreadHome: aiData['aiSpreadHome'],
                  aiMoneylineAway: aiData['aiMoneylineAway'],
                  aiMoneylineHome: aiData['aiMoneylineHome'],
                  aiTotalOver: aiData['aiTotalOver'],
                  aiTotalUnder: aiData['aiTotalUnder'],
                );
                
                final updatedEvent = currentEvent.copyWith(
                  bookmark: currentBookmarks,
                );
                
                _sportsbookEvents[idx] = updatedEvent;
                _sportsbookEvents.refresh();
                
                aiFetchCount++;
                
                if (aiFetchCount <= _maxCachedEvents * 3) { // Allow more caches for multiple bookmarks
                  await saveAIDataToCache();
                }
              }
            });
          }
        }
      } else {
        print("Failed to fetch events: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching sportsbook events: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more sportsbook events (pagination)
  Future<void> loadMoreSportsbookEvents() async {
    if (nextPageUrl == null || isRefreshing.value) return;

    try {
      isRefreshing.value = true;
      print("=== Loading More Sportsbook Events ===");
      print("URL: $nextPageUrl");

      final response = await http.get(Uri.parse(nextPageUrl!));

      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sportsbookResponse = SportsbookResponse.fromJson(data);

        print("Loaded ${sportsbookResponse.results.events.length} more events");
        print("Next page: ${sportsbookResponse.next}");

        _sportsbookEvents.addAll(sportsbookResponse.results.events);
        nextPageUrl = sportsbookResponse.next;

        print("More events loaded successfully!");
      } else {
        print("Failed to load more events: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading more sportsbook events: $e");
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Fetch AI prediction for a sportsbook event
  Future<Map<String, dynamic>> fetchAIForEvent(SportsbookEvent event, int index) async {
    try {
      // Get the first bookmark (FanDuel, DraftKings, etc.)
      if (event.bookmark.isEmpty) {
        return {'aiPercentage': null, 'aiExplanation': '', 'eventId': event.eventId};
      }

      final bookmark = event.bookmark.first;

      // Find h2h, spread, and totals markets
      Market? h2hMarket;
      Market? spreadMarket;
      Market? totalsMarket;

      for (var market in bookmark.market) {
        print("Market key: ${market.key}"); // Debug: log all market keys
        if (market.key == 'h2h') {
          h2hMarket = market;
        } else if (market.key == 'spread' || market.key == 'spreads') {
          spreadMarket = market;
        } else if (market.key == 'totals' || market.key == 'total') {
          totalsMarket = market;
        }
      }

      if (h2hMarket == null) {
        return {'aiPercentage': null, 'aiExplanation': '', 'eventId': event.eventId};
      }

      // Build team names list
      final teamNames = [event.awayTeam, event.homeTeam];

      // Build market values
      final marketValues = <String, List<dynamic>>{};

      // H2H (moneyline) values
      final h2hAway = h2hMarket.outcome.awayTeam?.american;
      final h2hHome = h2hMarket.outcome.homeTeam?.american;
      if (h2hAway != null && h2hHome != null) {
        marketValues['moneyline'] = [
          int.tryParse(h2hAway) ?? 0,
          int.tryParse(h2hHome) ?? 0,
        ];
      }

      // Spread values
      if (spreadMarket != null) {
        final spreadAway = spreadMarket.outcome.awayTeam?.american;
        final spreadHome = spreadMarket.outcome.homeTeam?.american;
        if (spreadAway != null && spreadHome != null) {
          marketValues['spread'] = [
            int.tryParse(spreadAway) ?? 0,
            int.tryParse(spreadHome) ?? 0,
          ];
        }
      }

      // Totals values
      if (totalsMarket != null) {
        final totalOver = totalsMarket.outcome.over?.american;
        final totalUnder = totalsMarket.outcome.under?.american;
        if (totalOver != null && totalUnder != null) {
          marketValues['totals'] = [
            int.tryParse(totalOver) ?? 0,
            int.tryParse(totalUnder) ?? 0,
          ];
        }
      }

      // Prepare request body
      final requestBody = {
        'team_names': teamNames,
        'market_values': marketValues,
      };

      print("=== Fetching AI Prediction ===");
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
          final aiMoneyline = aiPrediction['moneyline'] as List<dynamic>?;
          
          if (aiMoneyline != null && aiMoneyline.length == 2) {
            // Determine the favorite (more negative value)
            final awayValue = aiMoneyline[0] is int ? aiMoneyline[0] : (aiMoneyline[0] as num).toInt();
            final homeValue = aiMoneyline[1] is int ? aiMoneyline[1] : (aiMoneyline[1] as num).toInt();
            
            final favoriteTeam = awayValue < homeValue ? event.awayTeam : event.homeTeam;
            final favoriteOdds = awayValue < homeValue ? awayValue : homeValue;
            
            // Format odds - remove '+' for positive values
            String formattedOdds = favoriteOdds.toString();
            if (favoriteOdds > 0) {
              formattedOdds = '+$favoriteOdds';
            }

            print("AI Prediction: $formattedOdds for $favoriteTeam");

            // Calculate implied probabilities as doubles
            final awayProb = awayValue < 0 
                ? (100 / (1 + (100 / awayValue.abs()))) 
                : (awayValue / (awayValue + 100));
            final homeProb = homeValue < 0 
                ? (100 / (1 + (100 / homeValue.abs()))) 
                : (homeValue / (homeValue + 100));

            return {
              'aiPercentage': formattedOdds,
              'aiExplanation': 'AI predicts $favoriteTeam with odds $formattedOdds',
              'eventId': event.eventId,
              'optionTitles': teamNames,
              'marketProbs': [50.0, 50.0], // Placeholder probabilities
              'aiPercentages': [awayProb.toDouble(), homeProb.toDouble()],
            };
          }
        }
      }

      print("AI prediction failed or returned invalid data");
      return {'aiPercentage': null, 'aiExplanation': '', 'eventId': event.eventId};
    } catch (e) {
      print("Error fetching AI prediction: $e");
      return {'aiPercentage': null, 'aiExplanation': '', 'eventId': event.eventId};
    }
  }

  /// Fetch AI prediction for a specific bookmark
  Future<Map<String, dynamic>?> fetchAIForBookmark(
    SportsbookEvent event,
    Bookmark bookmark,
    int eventIndex,
    int bookmarkIndex,
  ) async {
    try {
      // Find h2h, spread, and totals markets
      Market? h2hMarket;
      Market? spreadMarket;
      Market? totalsMarket;

      for (var market in bookmark.market) {
        if (market.key == 'h2h') {
          h2hMarket = market;
        } else if (market.key == 'spread' || market.key == 'spreads') {
          spreadMarket = market;
        } else if (market.key == 'totals' || market.key == 'total') {
          totalsMarket = market;
        }
      }

      if (h2hMarket == null) {
        return null;
      }

      // Build team names list
      final teamNames = [event.awayTeam, event.homeTeam];

      // Build market values
      final marketValues = <String, List<dynamic>>{};

      // H2H (moneyline) values
      final h2hAway = h2hMarket.outcome.awayTeam?.american;
      final h2hHome = h2hMarket.outcome.homeTeam?.american;
      if (h2hAway != null && h2hHome != null) {
        marketValues['moneyline'] = [
          int.tryParse(h2hAway) ?? 0,
          int.tryParse(h2hHome) ?? 0,
        ];
      }

      // Spread values
      if (spreadMarket != null) {
        final spreadAway = spreadMarket.outcome.awayTeam?.american;
        final spreadHome = spreadMarket.outcome.homeTeam?.american;
        if (spreadAway != null && spreadHome != null) {
          marketValues['spread'] = [
            int.tryParse(spreadAway) ?? 0,
            int.tryParse(spreadHome) ?? 0,
          ];
        }
      }

      // Totals values
      if (totalsMarket != null) {
        final totalOver = totalsMarket.outcome.over?.american;
        final totalUnder = totalsMarket.outcome.under?.american;
        if (totalOver != null && totalUnder != null) {
          marketValues['totals'] = [
            int.tryParse(totalOver) ?? 0,
            int.tryParse(totalUnder) ?? 0,
          ];
        }
      }

      // Prepare request body
      final requestBody = {
        'team_names': teamNames,
        'market_values': marketValues,
      };

      print("=== Fetching AI for Bookmark ${bookmark.marketTitle} ===");
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
          String aiSpreadAway = 'N/A';
          String aiSpreadHome = 'N/A';
          if (aiSpread != null && aiSpread.length == 2) {
            aiSpreadAway = aiSpread[0].toString();
            aiSpreadHome = aiSpread[1].toString();
          }

          // Format moneyline values - no '+' sign for positive values
          String aiMoneylineAway = 'N/A';
          String aiMoneylineHome = 'N/A';
          if (aiMoneyline != null && aiMoneyline.length == 2) {
            final awayValue = aiMoneyline[0] is int ? aiMoneyline[0] : (aiMoneyline[0] as num).toInt();
            final homeValue = aiMoneyline[1] is int ? aiMoneyline[1] : (aiMoneyline[1] as num).toInt();
            aiMoneylineAway = awayValue.toString();
            aiMoneylineHome = homeValue.toString();
          }

          // Format totals values
          String aiTotalOver = 'N/A';
          String aiTotalUnder = 'N/A';
          if (aiTotals != null && aiTotals.length == 2) {
            aiTotalOver = aiTotals[0].toString();
            aiTotalUnder = aiTotals[1].toString();
          }

          print("AI Prediction for ${bookmark.marketTitle}: Spread[$aiSpreadAway, $aiSpreadHome] Money[$aiMoneylineAway, $aiMoneylineHome] Total[$aiTotalOver, $aiTotalUnder]");

          return {
            'aiSpreadAway': aiSpreadAway,
            'aiSpreadHome': aiSpreadHome,
            'aiMoneylineAway': aiMoneylineAway,
            'aiMoneylineHome': aiMoneylineHome,
            'aiTotalOver': aiTotalOver,
            'aiTotalUnder': aiTotalUnder,
          };
        }
      }

      print("AI prediction failed or returned invalid data for ${bookmark.marketTitle}");
      return null;
    } catch (e) {
      print("Error fetching AI prediction for bookmark: $e");
      return null;
    }
  }

  // ================= AI CACHING METHODS =================

  Future<bool> loadCachedAIData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cachedTimestamp == null) return false;
      
      final timestamp = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      final now = DateTime.now();
      
      if (now.difference(timestamp) > _cacheDuration) {
        print("Cache expired");
        return false;
      }
      
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData == null) return false;
      
      final List decoded = jsonDecode(cachedData);
      
      // Create a map of eventId -> AI data for quick lookup
      final aiDataMap = <String, Map<String, dynamic>>{};
      for (var item in decoded) {
        final eventId = item['eventId'] as String?;
        if (eventId != null) {
          aiDataMap[eventId] = Map<String, dynamic>.from(item);
        }
      }
      
      // Apply cached AI data to events
      for (int i = 0; i < _sportsbookEvents.length; i++) {
        final event = _sportsbookEvents[i];
        final aiData = aiDataMap[event.eventId];
        
        if (aiData != null && aiData['aiPercentage'] != null) {
          _sportsbookEvents[i] = event.copyWith(
            aiPercentage: aiData['aiPercentage'],
            aiExplanation: aiData['aiExplanation'],
            optionTitles: aiData['optionTitles'] as List<String>?,
            marketProbs: aiData['marketProbs'] as List<double>?,
            aiPercentages: aiData['aiPercentages'] as List<double>?,
          );
          _cachedEventIndexes.add(i);
        }
      }
      
      print("Loaded ${aiDataMap.length} cached AI predictions");
      return true;
    } catch (e) {
      print("Error loading cached AI data: $e");
      return false;
    }
  }

  void loadEventsWithCachedAI() {
    // Events already have AI data from loadCachedAIData
    print("Events loaded with cached AI data");
    update();
  }

  Future<void> saveAIDataToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final List<Map<String, dynamic>> dataToCache = [];
      
      for (int i = 0; i < _sportsbookEvents.length && i < _maxCachedEvents; i++) {
        final event = _sportsbookEvents[i];
        if (event.aiPercentage != null && event.aiPercentage.toString().isNotEmpty) {
          dataToCache.add({
            'eventId': event.eventId,
            'aiPercentage': event.aiPercentage,
            'aiExplanation': event.aiExplanation,
            'optionTitles': event.optionTitles,
            'marketProbs': event.marketProbs,
            'aiPercentages': event.aiPercentages,
          });
        }
      }
      
      await prefs.setString(_cacheKey, jsonEncode(dataToCache));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      print("Saved ${dataToCache.length} AI predictions to cache");
    } catch (e) {
      print("Error saving AI data to cache: $e");
    }
  }

  /// Search sportsbook events
  Future<void> searchSportsbookEvents(String query) async {
    if (query.trim().isEmpty) {
      isSearching.value = false;
      hasActiveSearch.value = false;
      _searchResults.clear();
      return;
    }

    try {
      isSearching.value = true;
      print("=== Searching Sportsbook Events ===");
      print("Query: $query");

      final url = '${Urls.sportsbookSearchUrl}?query=${Uri.encodeComponent(query)}';
      print("URL: $url");

      final response = await http.get(Uri.parse(url));

      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sportsbookResponse = SportsbookResponse.fromJson(data);

        print("Search results: ${sportsbookResponse.results.events.length}");

        _searchResults.assignAll(sportsbookResponse.results.events);
        hasActiveSearch.value = true;
      } else {
        print("Search failed: ${response.statusCode}");
        _searchResults.clear();
        hasActiveSearch.value = false;
      }
    } catch (e) {
      print("Error searching sportsbook events: $e");
      _searchResults.clear();
      hasActiveSearch.value = false;
    } finally {
      isSearching.value = false;
    }
  }

  /// Get moneyline (h2h) odds from bookmark
  /// Returns the more negative american value (the favorite)
  String? getMoneylineOdds(Bookmark bookmark) {
    // Find h2h market
    final h2hMarket = bookmark.market.firstWhere(
      (m) => m.key == 'h2h',
      orElse: () => Market(id: 0, key: '', outcome: MarketOutcome(), bookmark: 0),
    );

    if (h2hMarket.id == 0) return null;

    final awayOdds = h2hMarket.outcome.awayTeam?.american;
    final homeOdds = h2hMarket.outcome.homeTeam?.american;

    if (awayOdds == null && homeOdds == null) return null;
    if (awayOdds == null) return homeOdds;
    if (homeOdds == null) return awayOdds;

    // Parse and compare - return the more negative (lower) value
    final awayValue = int.tryParse(awayOdds) ?? 0;
    final homeValue = int.tryParse(homeOdds) ?? 0;

    // Return the lower value (more negative = the favorite)
    return (awayValue < homeValue ? awayOdds : homeOdds);
  }

  /// Format date for display
  String formatPrettyDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  void selectPlatform(int index) {
    selectedPlatform.value = index;
  }

  void onSearchQueryChanged(String query) {
    if (query.isEmpty) {
      isSearching.value = false;
      hasActiveSearch.value = false;
      _searchResults.clear();
    } else {
      // Call API to search
      searchSportsbookEvents(query);
    }
  }

  void clearSearch() {
    searchController.clear();
    isSearching.value = false;
    hasActiveSearch.value = false;
    _searchResults.clear();
  }

  bool isEventSaved(String eventId, String marketPlace) {
    switch (marketPlace) {
      case 'FanDuel':
        return _savedFanduelEventIds.contains(eventId);
      case 'DraftKings':
        return _savedDraftkingsEventIds.contains(eventId);
      case 'BetMGM':
        return _savedBetMgmEventIds.contains(eventId);
      default:
        return false;
    }
  }

  Future<void> fetchSavedEvents() async {
    try {
      final token = await SharedPreferencesHelper.getAccessToken();
      if (token == null) return;

      final url = Uri.parse('${Urls.baseUrl}/api/saved-accounts/');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final savedList = data['saved_accounts'] as List;

        _savedFanduelEventIds.clear();
        _savedDraftkingsEventIds.clear();
        _savedBetMgmEventIds.clear();

        for (var item in savedList) {
          final marketPlace = item['market_place'] as String?;
          final eventId = item['event_id']?.toString();

          if (eventId == null) continue;

          switch (marketPlace) {
            case 'FanDuel':
              _savedFanduelEventIds.add(eventId);
              break;
            case 'DraftKings':
              _savedDraftkingsEventIds.add(eventId);
              break;
            case 'BetMGM':
              _savedBetMgmEventIds.add(eventId);
              break;
          }
        }
      }
    } catch (e) {
      print("Error fetching saved events: $e");
    }
  }

  void saveEvent({required String eventId, required String marketPlace}) {
    switch (marketPlace) {
      case 'FanDuel':
        if (_savedFanduelEventIds.contains(eventId)) {
          _savedFanduelEventIds.remove(eventId);
        } else {
          _savedFanduelEventIds.add(eventId);
        }
        break;
      case 'DraftKings':
        if (_savedDraftkingsEventIds.contains(eventId)) {
          _savedDraftkingsEventIds.remove(eventId);
        } else {
          _savedDraftkingsEventIds.add(eventId);
        }
        break;
      case 'BetMGM':
        if (_savedBetMgmEventIds.contains(eventId)) {
          _savedBetMgmEventIds.remove(eventId);
        } else {
          _savedBetMgmEventIds.add(eventId);
        }
        break;
    }
  }

  void saveDraftkingsEvent({required String eventId, required String marketPlace}) {
    saveEvent(eventId: eventId, marketPlace: marketPlace);
  }
}
