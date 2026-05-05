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
  final hasError = false.obs;

  final RxList<SportsbookEvent> _sportsbookEvents = <SportsbookEvent>[].obs;
  final RxList<SportsbookEvent> _mlbEvents = <SportsbookEvent>[].obs;
  final RxList<SportsbookEvent> _searchResults = <SportsbookEvent>[].obs;

  List<SportsbookEvent> get sportsbookEvents => _sportsbookEvents;
  List<SportsbookEvent> get mlbEvents => _mlbEvents;
  List<SportsbookEvent> get searchResults => _searchResults;

  // Track if initial cache load is complete
  bool _isInitialCacheLoaded = false;
  bool get isInitialCacheLoaded => _isInitialCacheLoaded;

  String? nextPageUrl;
  String? mlbNextPageUrl;

  List<Map<String, dynamic>> get savedFanduelEvents => _savedFanduelEvents;
  List<Map<String, dynamic>> get savedDraftkingsEvents => _savedDraftkingsEvents;
  List<Map<String, dynamic>> get savedBetMgmEvents => _savedBetMgmEvents;

  final Set<String> _savedFanduelEventIds = <String>{};
  final Set<String> _savedDraftkingsEventIds = <String>{};
  final Set<String> _savedBetMgmEventIds = <String>{};
  final RxList<Map<String, dynamic>> _savedFanduelEvents = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _savedDraftkingsEvents = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _savedBetMgmEvents = <Map<String, dynamic>>[].obs;

  final TextEditingController searchController = TextEditingController();

  // Sportsbook events caching - cache entire events data
  static const String _sportsbookCacheKey = 'cached_sportsbook_events_v3';
  static const String _sportsbookCacheTimestampKey = 'cached_sportsbook_timestamp_v3';
  
  // MLB events caching
  static const String _mlbCacheKey = 'cached_mlb_events_v1';
  static const String _mlbCacheTimestampKey = 'cached_mlb_timestamp_v1';
  
  static const Duration _cacheDuration = Duration(hours: 12);
  static const int _maxCachedEvents = 50; // Increased to cache more events

  // Saved events caching - 30 minutes cache
  static const String _savedEventsCacheKey = 'cached_saved_sports_events_v1';
  static const String _savedEventsCacheTimestampKey = 'cached_saved_sports_timestamp_v1';
  static const Duration _savedCacheDuration = Duration(minutes: 30);

  final Set<int> _cachedEventIndexes = <int>{};
  // No limit on events - show all current/upcoming events

  @override
  void onInit() {
    super.onInit();
    // Load cached saved events first
    loadCachedSavedEvents().then((hasValidCache) async {
      if (hasValidCache) {
        // Fetch fresh data in background
        _fetchSavedEventsInBackground();
      } else {
        await fetchSavedEvents();
      }
    });

    // Load cached sportsbook events first
    loadCachedSportsbookEvents().then((hasValidCache) async {
      if (hasValidCache) {
        // Fetch fresh data in background without replacing cached data immediately
        _fetchSportsbookEventsInBackground();
      } else {
        await fetchSportsbookEvents();
      }
    });

    // Load cached MLB events
    loadCachedMlbEvents().then((hasValidCache) async {
      if (hasValidCache) {
        _fetchMlbEventsInBackground();
      } else {
        await fetchMlbEvents();
      }
    });
  }

  /// Fetch sportsbook events in background (doesn't replace existing data until AI is loaded)
  Future<void> _fetchSportsbookEventsInBackground() async {
    try {
      print("=== Fetching Sportsbook Events in Background ===");
      print("URL: ${Urls.sportsbookModelUrl}");

      final response = await http.get(Uri.parse(Urls.sportsbookModelUrl));
      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sportsbookResponse = SportsbookResponse.fromJson(data);

        // Filter by date: only include current or upcoming events
        List<SportsbookEvent> eventsList = sportsbookResponse.events
            .where((event) => _isCurrentOrUpcomingDate(event.date))
            .toList();

        print("Background events after date filter: ${eventsList.length}");

        // Only update if we have events, otherwise keep cached data
        if (eventsList.isNotEmpty) {
          // No limit - show all current/upcoming events

          // Preserve AI moneyline data from cached events for ALL bookmarks
          for (int i = 0; i < eventsList.length; i++) {
            final freshEvent = eventsList[i];
            final cachedEventIndex = _sportsbookEvents.indexWhere(
              (e) => e.eventId == freshEvent.eventId,
            );

            if (cachedEventIndex != -1) {
              final cachedEvent = _sportsbookEvents[cachedEventIndex];

              // Merge AI data from cached event into fresh event for ALL bookmarks
              List<Bookmark> mergedBookmarks = [];
              for (int j = 0; j < freshEvent.bookmark.length; j++) {
                final freshBookmark = freshEvent.bookmark[j];
                final cachedBookmark = cachedEvent.bookmark.length > j ? cachedEvent.bookmark[j] : null;

                if (cachedBookmark != null) {
                  // Merge all AI data from cached bookmark
                  mergedBookmarks.add(freshBookmark.copyWith(
                    aiSpreadAway: cachedBookmark.aiSpreadAway ?? freshBookmark.aiSpreadAway,
                    aiSpreadHome: cachedBookmark.aiSpreadHome ?? freshBookmark.aiSpreadHome,
                    aiMoneylineAway: cachedBookmark.aiMoneylineAway ?? freshBookmark.aiMoneylineAway,
                    aiMoneylineHome: cachedBookmark.aiMoneylineHome ?? freshBookmark.aiMoneylineHome,
                    aiTotalOver: cachedBookmark.aiTotalOver ?? freshBookmark.aiTotalOver,
                    aiTotalUnder: cachedBookmark.aiTotalUnder ?? freshBookmark.aiTotalUnder,
                  ));
                } else {
                  mergedBookmarks.add(freshBookmark);
                }
              }

              // Merge AI data from cached event into fresh event
              eventsList[i] = freshEvent.copyWith(
                bookmark: mergedBookmarks,
                aiPercentage: cachedEvent.aiPercentage,
                aiExplanation: cachedEvent.aiExplanation,
                optionTitles: cachedEvent.optionTitles,
                marketProbs: cachedEvent.marketProbs,
                aiPercentages: cachedEvent.aiPercentages,
              );
            }
          }

          // Update events with merged data
          _sportsbookEvents.assignAll(eventsList);
          _sportsbookEvents.refresh();
          nextPageUrl = sportsbookResponse.next;

          print("Background events loaded with cached AI data!");
          update(); // Notify UI to rebuild

          // Fetch fresh AI data and update cache
          _fetchAllAiPredictionsAsync(eventsList, isMlb: false);
        } else {
          print("⚠️ No current/upcoming events from API (background) - keeping cached data");
        }
      } else {
        print("Background fetch failed with status: ${response.statusCode}. Keeping cached data.");
      }
    } catch (e) {
      print("Error fetching sportsbook events in background: $e");
      // Keep cached data - don't clear events on error
    }
  }

  /// Fetch MLB events in background
  Future<void> _fetchMlbEventsInBackground() async {
    try {
      print("=== Fetching MLB Events in Background ===");
      print("URL: ${Urls.mlbSportsbookModelUrl}");

      final response = await http.get(Uri.parse(Urls.mlbSportsbookModelUrl));
      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sportsbookResponse = SportsbookResponse.fromJson(data);

        List<SportsbookEvent> eventsList = sportsbookResponse.events
            .where((event) => _isCurrentOrUpcomingDate(event.date))
            .toList();

        if (eventsList.isNotEmpty) {
          // Preserve AI data from cached MLB events
          for (int i = 0; i < eventsList.length; i++) {
            final freshEvent = eventsList[i];
            final cachedEventIndex = _mlbEvents.indexWhere(
              (e) => e.eventId == freshEvent.eventId,
            );

            if (cachedEventIndex != -1) {
              final cachedEvent = _mlbEvents[cachedEventIndex];
              List<Bookmark> mergedBookmarks = [];
              for (int j = 0; j < freshEvent.bookmark.length; j++) {
                final freshBookmark = freshEvent.bookmark[j];
                final cachedBookmark = cachedEvent.bookmark.length > j ? cachedEvent.bookmark[j] : null;

                if (cachedBookmark != null) {
                  mergedBookmarks.add(freshBookmark.copyWith(
                    aiSpreadAway: cachedBookmark.aiSpreadAway ?? freshBookmark.aiSpreadAway,
                    aiSpreadHome: cachedBookmark.aiSpreadHome ?? freshBookmark.aiSpreadHome,
                    aiMoneylineAway: cachedBookmark.aiMoneylineAway ?? freshBookmark.aiMoneylineAway,
                    aiMoneylineHome: cachedBookmark.aiMoneylineHome ?? freshBookmark.aiMoneylineHome,
                    aiTotalOver: cachedBookmark.aiTotalOver ?? freshBookmark.aiTotalOver,
                    aiTotalUnder: cachedBookmark.aiTotalUnder ?? freshBookmark.aiTotalUnder,
                  ));
                } else {
                  mergedBookmarks.add(freshBookmark);
                }
              }

              eventsList[i] = freshEvent.copyWith(
                bookmark: mergedBookmarks,
              );
            }
          }

          _mlbEvents.assignAll(eventsList);
          _mlbEvents.refresh();
          mlbNextPageUrl = sportsbookResponse.next;

          print("Background MLB events loaded!");
          update();

          _fetchAllAiPredictionsAsync(eventsList, isMlb: true);
        }
      }
    } catch (e) {
      print("Error fetching MLB events in background: $e");
    }
  }

  /// Fetch sportsbook events from API
  /// Helper method to check if a date string is now or in the future
  /// Returns true if the event time is >= current time OR within live grace period
  /// Uses UTC time to match website behavior (no timezone conversion)
  bool _isCurrentOrUpcomingDate(String dateStr) {
    try {
      // Parse the date string as UTC (same as API response)
      final eventDate = DateTime.parse(dateStr); // Keep as UTC
      final now = DateTime.now().toUtc(); // Convert current time to UTC

      // Compare exact datetime in UTC (includes time, not just date)
      final isFuture = eventDate.isAfter(now);
      final isNow = eventDate.isAtSameMomentAs(now);
      
      // Add grace period for LIVE games (3 hours = covers most NBA/MLB games)
      final liveGracePeriod = const Duration(hours: 3);
      final isLiveGame = eventDate.isAfter(now.subtract(liveGracePeriod)) && eventDate.isBefore(now);

      final isCurrentOrUpcoming = isFuture || isNow || isLiveGame;

      return isCurrentOrUpcoming;
    } catch (e) {
      print("Error parsing date '$dateStr': $e");
      return true; // Include on parse error
    }
  }

  Future<void> fetchSportsbookEvents({bool backgroundOnly = false}) async {
    if (!backgroundOnly) {
      isLoading.value = true;
      hasError.value = false;
    }

    try {
      print("=== Fetching Sportsbook Events ===");
      print("URL: ${Urls.sportsbookModelUrl}");

      final response = await http.get(Uri.parse(Urls.sportsbookModelUrl));

      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sportsbookResponse = SportsbookResponse.fromJson(data);

        print("Total events: ${sportsbookResponse.events.length}");
        print("Next page: ${sportsbookResponse.next}");

        // Filter by date: only include current or upcoming events
        List<SportsbookEvent> eventsList = sportsbookResponse.events
            .where((event) => _isCurrentOrUpcomingDate(event.date))
            .toList();

        print("Events after date filter: ${eventsList.length}");

        // No limit - show all current/upcoming events

        // Only update if we have events, otherwise keep cached data
        if (eventsList.isNotEmpty) {
          _sportsbookEvents.assignAll(eventsList);
          nextPageUrl = sportsbookResponse.next;
          print("Events loaded successfully! (Showing ${eventsList.length} events)");
          
          // Fetch AI predictions first, then cache everything together
          await _fetchAllAiPredictionsSync(eventsList, isMlb: false);
          
          // Cache the events with AI data
          cacheSportsbookEvents();
        } else {
          print("⚠️ No current/upcoming events from API - keeping cached data");
        }

        // Notify UI immediately after loading events (before AI fetch)
        update();
      } else {
        print("Failed to fetch events: ${response.statusCode}");
        if (!backgroundOnly) {
          hasError.value = true;
        }
      }
    } catch (e) {
      print("Error fetching sportsbook events: $e");
      if (!backgroundOnly) {
        hasError.value = true;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch MLB events
  Future<void> fetchMlbEvents({bool backgroundOnly = false}) async {
    if (!backgroundOnly) {
      isLoading.value = true;
      hasError.value = false;
    }

    try {
      print("=== Fetching MLB Events ===");
      print("URL: ${Urls.mlbSportsbookModelUrl}");

      final response = await http.get(Uri.parse(Urls.mlbSportsbookModelUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sportsbookResponse = SportsbookResponse.fromJson(data);

        List<SportsbookEvent> eventsList = sportsbookResponse.events
            .where((event) => _isCurrentOrUpcomingDate(event.date))
            .toList();

        if (eventsList.isNotEmpty) {
          _mlbEvents.assignAll(eventsList);
          mlbNextPageUrl = sportsbookResponse.next;
          
          await _fetchAllAiPredictionsSync(eventsList, isMlb: true);
          cacheMlbEvents();
        }
        update();
      } else {
        if (!backgroundOnly) hasError.value = true;
      }
    } catch (e) {
      print("Error fetching MLB events: $e");
      if (!backgroundOnly) hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch AI predictions synchronously (waits for completion)
  Future<void> _fetchAllAiPredictionsSync(List<SportsbookEvent> eventsList, {required bool isMlb}) async {
    List<Future<void>> aiFetchFutures = [];

    for (int i = 0; i < eventsList.length; i++) {
      final event = eventsList[i];

      // Fetch AI for ALL bookmarks (not just first one)
      for (int j = 0; j < event.bookmark.length; j++) {
        final bookmark = event.bookmark[j];

        // Skip if AI moneyline already exists for this bookmark
        if (bookmark.aiMoneylineAway != null && bookmark.aiMoneylineHome != null) {
          continue;
        }

        aiFetchFutures.add(
          fetchAIForBookmark(event, bookmark, i, j).then((aiData) async {
            // Skip if AI data is null
            if (aiData == null) {
              print("Sportsbook AI returned null for bookmark");
              return;
            }

            final targetList = isMlb ? _mlbEvents : _sportsbookEvents;
            final idx = targetList.indexWhere(
              (ev) => ev.eventId == event.eventId,
            );

            if (idx != -1) {
              final currentEvent = targetList[idx];
              final currentBookmarks = List<Bookmark>.from(currentEvent.bookmark);

              // Ensure we have a bookmark at index j
              if (j >= currentBookmarks.length) {
                return;
              }

              // Save moneyline values for this bookmark
              currentBookmarks[j] = currentBookmarks[j].copyWith(
                aiMoneylineAway: aiData['aiMoneylineAway'],
                aiMoneylineHome: aiData['aiMoneylineHome'],
                aiSpreadAway: aiData['aiSpreadAway'],
                aiSpreadHome: aiData['aiSpreadHome'],
                aiTotalOver: aiData['aiTotalOver'],
                aiTotalUnder: aiData['aiTotalUnder'],
              );

              final updatedEvent = currentEvent.copyWith(
                bookmark: currentBookmarks,
              );

              targetList[idx] = updatedEvent;
              targetList.refresh();
            }
          }),
        );
      }
    }

    // Wait for all AI fetches to complete
    if (aiFetchFutures.isNotEmpty) {
      await Future.wait(aiFetchFutures);
      print("All AI predictions fetched for ${isMlb ? 'MLB' : 'NBA'}!");
    }
  }

  /// Fetch AI predictions asynchronously (doesn't block)
  void _fetchAllAiPredictionsAsync(List<SportsbookEvent> eventsList, {required bool isMlb, bool shouldCache = true}) {
    int completedCount = 0;
    int totalCount = 0;

    // Count total AI fetches needed
    for (int i = 0; i < eventsList.length; i++) {
      final event = eventsList[i];
      for (int j = 0; j < event.bookmark.length; j++) {
        final bookmark = event.bookmark[j];
        if (bookmark.aiMoneylineAway == null || bookmark.aiMoneylineHome == null) {
          totalCount++;
        }
      }
    }

    // No AI fetches needed, return
    if (totalCount == 0) {
      if (shouldCache) isMlb ? cacheMlbEvents() : cacheSportsbookEvents();
      return;
    }

    for (int i = 0; i < eventsList.length; i++) {
      final event = eventsList[i];

      // Fetch AI for ALL bookmarks (not just first one)
      for (int j = 0; j < event.bookmark.length; j++) {
        final bookmark = event.bookmark[j];

        // Skip if AI moneyline already exists for this bookmark
        if (bookmark.aiMoneylineAway != null && bookmark.aiMoneylineHome != null) {
          continue;
        }

        fetchAIForBookmark(event, bookmark, i, j).then((aiData) async {
          completedCount++;

          // Skip if AI data is null
          if (aiData == null) {
            print("Sportsbook AI returned null for bookmark");
            // Cache even if some AI failed
            if (shouldCache && completedCount >= totalCount) {
              isMlb ? cacheMlbEvents() : cacheSportsbookEvents();
            }
            return;
          }

          final targetList = isMlb ? _mlbEvents : _sportsbookEvents;
          final idx = targetList.indexWhere(
            (ev) => ev.eventId == event.eventId,
          );

          if (idx != -1) {
            final currentEvent = targetList[idx];
            final currentBookmarks = List<Bookmark>.from(currentEvent.bookmark);

            // Ensure we have a bookmark at index j
            if (j >= currentBookmarks.length) {
              return;
            }

            // Save moneyline values for this bookmark
            currentBookmarks[j] = currentBookmarks[j].copyWith(
              aiMoneylineAway: aiData['aiMoneylineAway'],
              aiMoneylineHome: aiData['aiMoneylineHome'],
              aiSpreadAway: aiData['aiSpreadAway'],
              aiSpreadHome: aiData['aiSpreadHome'],
              aiTotalOver: aiData['aiTotalOver'],
              aiTotalUnder: aiData['aiTotalUnder'],
            );

            final updatedEvent = currentEvent.copyWith(
              bookmark: currentBookmarks,
            );

            targetList[idx] = updatedEvent;
            targetList.refresh();

            // Cache after all AI fetches complete
            if (shouldCache && completedCount >= totalCount) {
              isMlb ? cacheMlbEvents() : cacheSportsbookEvents();
            }
          }
        });
      }
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

        print("Loaded ${sportsbookResponse.events.length} more events");
        print("Next page: ${sportsbookResponse.next}");

        _sportsbookEvents.addAll(sportsbookResponse.events);
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

  /// Load more MLB events
  Future<void> loadMoreMlbEvents() async {
    if (mlbNextPageUrl == null || isRefreshing.value) return;

    try {
      isRefreshing.value = true;
      final response = await http.get(Uri.parse(mlbNextPageUrl!));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sportsbookResponse = SportsbookResponse.fromJson(data);

        _mlbEvents.addAll(sportsbookResponse.events);
        mlbNextPageUrl = sportsbookResponse.next;
      }
    } catch (e) {
      print("Error loading more MLB events: $e");
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
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30), // Increased from 10s to 30s
        onTimeout: () {
          print("⚠️ AI API request timed out for ${bookmark.marketTitle}");
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      print("AI Response Status: ${response.statusCode}");
      print("AI Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
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
        } catch (e) {
          print("Error decoding AI response: $e");
          print("Response body: ${response.body}");
        }
      }

      print("AI prediction failed or returned invalid data for ${bookmark.marketTitle}");
      return null;
    } catch (e) {
      print("Error fetching AI prediction for bookmark: $e");
      return null;
    }
  }

  // ================= SPORTSBOOK EVENTS CACHING METHODS =================

  /// Load cached sportsbook events
  Future<bool> loadCachedSportsbookEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTimestampStr = prefs.getString(_sportsbookCacheTimestampKey);

      if (cachedTimestampStr == null) {
        print("No cached sportsbook events found");
        return false;
      }

      final timestamp = DateTime.parse(cachedTimestampStr);
      final now = DateTime.now();

      if (now.difference(timestamp) > _cacheDuration) {
        print("Sportsbook cache expired - will fetch fresh data");
        return false;
      }

      final cachedData = prefs.getString(_sportsbookCacheKey);
      if (cachedData == null) return false;

      final List decoded = jsonDecode(cachedData);
      final eventsList = decoded.map((e) => SportsbookEvent.fromJson(Map<String, dynamic>.from(e))).toList();

      if (eventsList.isNotEmpty) {
        _sportsbookEvents.assignAll(eventsList);
        _isInitialCacheLoaded = true;
        print("Loaded ${eventsList.length} cached sportsbook events");
        // Trigger UI update
        update();
        return true;
      }

      // Mark as loaded even if no cache (first time user)
      _isInitialCacheLoaded = true;
      update();
      return false;
    } catch (e) {
      print("Error loading cached sportsbook events: $e");
      // Mark as loaded even on error to prevent infinite loading
      _isInitialCacheLoaded = true;
      update();
      return false;
    }
  }

  /// Cache sportsbook events to local storage
  Future<void> cacheSportsbookEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert events to JSON-serializable format
      final List<Map<String, dynamic>> dataToCache = [];
      for (int i = 0; i < _sportsbookEvents.length && i < _maxCachedEvents; i++) {
        final event = _sportsbookEvents[i];
        dataToCache.add(event.toJson());
      }

      if (dataToCache.isEmpty) return;

      await prefs.setString(_sportsbookCacheKey, jsonEncode(dataToCache));
      await prefs.setString(
        _sportsbookCacheTimestampKey,
        DateTime.now().toIso8601String(),
      );

      print("Cached ${dataToCache.length} sportsbook events");
    } catch (e) {
      print("Error caching sportsbook events: $e");
    }
  }

  /// Load cached MLB events
  Future<bool> loadCachedMlbEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTimestampStr = prefs.getString(_mlbCacheTimestampKey);

      if (cachedTimestampStr == null) return false;

      final timestamp = DateTime.parse(cachedTimestampStr);
      final now = DateTime.now();

      if (now.difference(timestamp) > _cacheDuration) return false;

      final cachedData = prefs.getString(_mlbCacheKey);
      if (cachedData == null) return false;

      final List decoded = jsonDecode(cachedData);
      final eventsList = decoded.map((e) => SportsbookEvent.fromJson(Map<String, dynamic>.from(e))).toList();

      if (eventsList.isNotEmpty) {
        _mlbEvents.assignAll(eventsList);
        update();
        return true;
      }
      return false;
    } catch (e) {
      print("Error loading cached MLB events: $e");
      return false;
    }
  }

  /// Cache MLB events to local storage
  Future<void> cacheMlbEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> dataToCache = [];
      for (int i = 0; i < _mlbEvents.length && i < _maxCachedEvents; i++) {
        dataToCache.add(_mlbEvents[i].toJson());
      }

      if (dataToCache.isEmpty) return;

      await prefs.setString(_mlbCacheKey, jsonEncode(dataToCache));
      await prefs.setString(_mlbCacheTimestampKey, DateTime.now().toIso8601String());
      print("Cached ${dataToCache.length} MLB events");
    } catch (e) {
      print("Error caching MLB events: $e");
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

        print("Search results: ${sportsbookResponse.events.length}");

        _searchResults.assignAll(sportsbookResponse.events);
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
    final platform = marketPlace.toLowerCase();
    switch (platform) {
      case 'fanduel':
        return _savedFanduelEventIds.contains(eventId);
      case 'draftkings':
        return _savedDraftkingsEventIds.contains(eventId);
      case 'betmgm':
        return _savedBetMgmEventIds.contains(eventId);
      default:
        return false;
    }
  }

  Future<void> fetchSavedEvents() async {
    try {
      final token = await SharedPreferencesHelper.getAccessToken();
      if (token == null) {
        print("No token found for saved events");
        return;
      }

      final url = Uri.parse('${Urls.baseUrl}/api/trade/saved-event-list/');
      print("=== Fetch Saved Sports Events ===");
      print("URL: $url");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Response Body: $data");

        // Get only sportsbook_events from the response
        final sportsbookEvents = data['sportsbook_events'] as List<dynamic>?;

        // Save current ID sets before clearing (to know which platforms user actually saved)
        final savedFanduelIds = Set<String>.from(_savedFanduelEventIds);
        final savedDraftkingsIds = Set<String>.from(_savedDraftkingsEventIds);
        final savedBetMgmIds = Set<String>.from(_savedBetMgmEventIds);

        // Clear existing saved events
        _savedFanduelEventIds.clear();
        _savedDraftkingsEventIds.clear();
        _savedBetMgmEventIds.clear();
        _savedFanduelEvents.clear();
        _savedDraftkingsEvents.clear();
        _savedBetMgmEvents.clear();

        // Process sportsbook events
        if (sportsbookEvents != null && sportsbookEvents.isNotEmpty) {
          print("Found ${sportsbookEvents.length} saved sportsbook events");

          for (var event in sportsbookEvents) {
            final eventId = event['event_id']?.toString();
            if (eventId == null) continue;

            // Process each bookmark (FanDuel, DraftKings, BetMGM)
            final bookmarks = event['bookmark'] as List<dynamic>?;
            if (bookmarks == null) continue;

            for (var bookmark in bookmarks) {
              final marketPlace = bookmark['market_title'] as String?;
              if (marketPlace == null) continue;

              // Check if user actually saved this platform (using saved ID sets)
              bool wasActuallySaved = false;
              switch (marketPlace) {
                case 'FanDuel':
                  wasActuallySaved = savedFanduelIds.contains(eventId);
                  break;
                case 'DraftKings':
                  wasActuallySaved = savedDraftkingsIds.contains(eventId);
                  break;
                case 'BetMGM':
                  wasActuallySaved = savedBetMgmIds.contains(eventId);
                  break;
              }

              // Only add to saved list if user actually saved this platform
              if (!wasActuallySaved) continue;

              // Add to appropriate saved set and event list
              print('💾 Adding saved event: eventId=$eventId, marketPlace=$marketPlace, title=${event['title']}');
              switch (marketPlace) {
                case 'FanDuel':
                  _savedFanduelEventIds.add(eventId);
                  _savedFanduelEvents.add({
                    'event_id': eventId,
                    'title': event['title'] ?? '',
                    'subtitle': '${event['away_team'] ?? ''} vs ${event['home_team'] ?? ''}',
                    'endDate': event['date'] ?? '',
                    'marketPercentage': _getBestMoneyline(bookmark),
                    'aiPercentage': bookmark['ai_moneyline_away'] ?? bookmark['ai_moneyline_home'],
                    'team': event['home_team'] ?? '',
                    'marketPlace': marketPlace,
                    'bookmark': bookmark,
                  });
                  print('💾 FD event added, event_id=${_savedFanduelEvents.last['event_id']}');
                  break;
                case 'DraftKings':
                  _savedDraftkingsEventIds.add(eventId);
                  _savedDraftkingsEvents.add({
                    'event_id': eventId,
                    'title': event['title'] ?? '',
                    'subtitle': '${event['away_team'] ?? ''} vs ${event['home_team'] ?? ''}',
                    'endDate': event['date'] ?? '',
                    'marketPercentage': _getBestMoneyline(bookmark),
                    'aiPercentage': bookmark['ai_moneyline_away'] ?? bookmark['ai_moneyline_home'],
                    'team': event['home_team'] ?? '',
                    'marketPlace': marketPlace,
                    'bookmark': bookmark,
                  });
                  print('💾 DK event added, event_id=${_savedDraftkingsEvents.last['event_id']}');
                  break;
                case 'BetMGM':
                  _savedBetMgmEventIds.add(eventId);
                  _savedBetMgmEvents.add({
                    'event_id': eventId,
                    'title': event['title'] ?? '',
                    'subtitle': '${event['away_team'] ?? ''} vs ${event['home_team'] ?? ''}',
                    'endDate': event['date'] ?? '',
                    'marketPercentage': _getBestMoneyline(bookmark),
                    'aiPercentage': bookmark['ai_moneyline_away'] ?? bookmark['ai_moneyline_home'],
                    'team': event['home_team'] ?? '',
                    'marketPlace': marketPlace,
                    'bookmark': bookmark,
                  });
                  print('💾 MGM event added, event_id=${_savedBetMgmEvents.last['event_id']}');
                  break;
              }
            }
          }

          print("Saved events processed: FD=${_savedFanduelEvents.length}, DK=${_savedDraftkingsEvents.length}, MGM=${_savedBetMgmEvents.length}");

          // Fetch AI predictions for saved events (async, doesn't block UI)
          _fetchAiForSavedEvents();
        } else {
          print("No saved sportsbook events found");
        }
      } else {
        print("Failed to fetch saved events: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching saved events: $e");
    }
  }

  /// Fetch AI predictions for saved events - Process in parallel for faster loading
  Future<void> _fetchAiForSavedEvents() async {
    final allSavedEvents = [
      ..._savedFanduelEvents,
      ..._savedDraftkingsEvents,
      ..._savedBetMgmEvents,
    ];

    // Filter events that need AI predictions
    final eventsNeedingAi = allSavedEvents.where((event) {
      final bookmark = event['bookmark'] as Map<String, dynamic>?;
      if (bookmark == null) return false;
      final existingAiAway = bookmark['ai_moneyline_away'] as String?;
      final existingAiHome = bookmark['ai_moneyline_home'] as String?;
      return existingAiAway == null && existingAiHome == null;
    }).toList();

    // If no events need AI, just cache and return
    if (eventsNeedingAi.isEmpty) {
      cacheSavedEvents();
      return;
    }

    print("Fetching AI for ${eventsNeedingAi.length} saved events in parallel...");

    // Create futures for all AI requests
    final aiFutures = eventsNeedingAi.map((event) async {
      try {
        final bookmark = event['bookmark'] as Map<String, dynamic>;
        final eventId = event['event_id'] as String;
        final marketPlace = event['marketPlace'] as String;

        // Build team names from subtitle
        final subtitle = event['subtitle'] as String? ?? '';
        final teams = subtitle.split(' vs ');
        if (teams.length != 2) return;

        final awayTeam = teams[0].trim();
        final homeTeam = teams[1].trim();

        // Fetch AI for this bookmark
        final aiData = await fetchAIForBookmark(
          SportsbookEvent(
            eventId: eventId,
            bookmark: [Bookmark.fromJson(bookmark)],
            date: event['endDate'] as String? ?? '',
            homeTeam: homeTeam,
            awayTeam: awayTeam,
          ),
          Bookmark.fromJson(bookmark),
          0,
          0,
        );

        if (aiData != null) {
          final aiMoneylineAway = aiData['aiMoneylineAway'] as String?;
          final aiMoneylineHome = aiData['aiMoneylineHome'] as String?;

          // Determine which team is the favorite (more negative moneyline)
          String? favoriteAiValue;
          final markets = bookmark['market'] as List<dynamic>?;
          if (markets != null) {
            for (var market in markets) {
              final key = market['key'] as String?;
              if (key == 'h2h') {
                final outcome = market['outcome'] as Map<String, dynamic>?;
                if (outcome != null) {
                  final away = outcome['away_team'] as Map<String, dynamic>?;
                  final home = outcome['home_team'] as Map<String, dynamic>?;
                  final awayAmerican = away?['american'] as String?;
                  final homeAmerican = home?['american'] as String?;

                  if (awayAmerican != null && homeAmerican != null) {
                    final awayValue = int.tryParse(awayAmerican) ?? 0;
                    final homeValue = int.tryParse(homeAmerican) ?? 0;
                    // Favorite is the more negative value
                    favoriteAiValue = (awayValue < homeValue) ? aiMoneylineAway : aiMoneylineHome;
                  }
                }
                break;
              }
            }
          }

          // Update the saved event with AI data
          final idx = _getSavedEventIndex(eventId, marketPlace);
          if (idx != -1) {
            final updatedBookmark = bookmark..addAll({
              'ai_moneyline_away': aiMoneylineAway,
              'ai_moneyline_home': aiMoneylineHome,
            });

            switch (marketPlace) {
              case 'FanDuel':
                if (idx < _savedFanduelEvents.length) {
                  _savedFanduelEvents[idx]['bookmark'] = updatedBookmark;
                  _savedFanduelEvents[idx]['aiPercentage'] = favoriteAiValue ?? aiMoneylineAway ?? aiMoneylineHome;
                }
                break;
              case 'DraftKings':
                if (idx < _savedDraftkingsEvents.length) {
                  _savedDraftkingsEvents[idx]['bookmark'] = updatedBookmark;
                  _savedDraftkingsEvents[idx]['aiPercentage'] = favoriteAiValue ?? aiMoneylineAway ?? aiMoneylineHome;
                }
                break;
              case 'BetMGM':
                if (idx < _savedBetMgmEvents.length) {
                  _savedBetMgmEvents[idx]['bookmark'] = updatedBookmark;
                  _savedBetMgmEvents[idx]['aiPercentage'] = favoriteAiValue ?? aiMoneylineAway ?? aiMoneylineHome;
                }
                break;
            }
            // Refresh the specific list to trigger UI rebuild
            _savedFanduelEvents.refresh();
            _savedDraftkingsEvents.refresh();
            _savedBetMgmEvents.refresh();
          }
        }
      } catch (e) {
        print("Error processing AI for saved event: $e");
      }
    }).toList();

    // Wait for all AI requests to complete in parallel
    await Future.wait(aiFutures);

    print("Completed processing all ${eventsNeedingAi.length} saved events AI requests");
    // Cache saved events after AI predictions are fetched
    cacheSavedEvents();
  }

  /// Get index of saved event by event ID and market place
  int _getSavedEventIndex(String eventId, String marketPlace) {
    switch (marketPlace) {
      case 'FanDuel':
        return _savedFanduelEvents.indexWhere((e) => e['event_id'] == eventId);
      case 'DraftKings':
        return _savedDraftkingsEvents.indexWhere((e) => e['event_id'] == eventId);
      case 'BetMGM':
        return _savedBetMgmEvents.indexWhere((e) => e['event_id'] == eventId);
      default:
        return -1;
    }
  }

  /// Get best moneyline (lowest american value) from bookmark
  String _getBestMoneyline(dynamic bookmark) {
    try {
      final markets = bookmark['market'] as List<dynamic>?;
      if (markets == null) return '-';

      // Find h2h market
      final h2hMarket = markets.firstWhere(
        (m) => m['key'] == 'h2h',
        orElse: () => null,
      );

      if (h2hMarket == null) return '-';

      final outcome = h2hMarket['outcome'] as Map<String, dynamic>?;
      if (outcome == null) return '-';

      final awayTeam = outcome['away_team'] as Map<String, dynamic>?;
      final homeTeam = outcome['home_team'] as Map<String, dynamic>?;

      final awayAmerican = awayTeam?['american'] as String?;
      final homeAmerican = homeTeam?['american'] as String?;

      if (awayAmerican == null && homeAmerican == null) return '-';
      if (awayAmerican == null) return homeAmerican!.replaceAll('+', '');
      if (homeAmerican == null) return awayAmerican.replaceAll('+', '');

      // Return the lower (more negative) value
      final awayValue = int.tryParse(awayAmerican) ?? 0;
      final homeValue = int.tryParse(homeAmerican) ?? 0;

      return (awayValue < homeValue ? awayAmerican : homeAmerican).replaceAll('+', '');
    } catch (e) {
      return '-';
    }
  }

  /// Fetch saved events in background (after 30 min cache)
  Future<void> _fetchSavedEventsInBackground() async {
    try {
      print("=== Fetching Saved Events in Background ===");
      final token = await SharedPreferencesHelper.getAccessToken();
      if (token == null) return;

      final url = Uri.parse('${Urls.baseUrl}/api/trade/saved-event-list/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sportsbookEvents = data['sportsbook_events'] as List<dynamic>?;

        if (sportsbookEvents != null && sportsbookEvents.isNotEmpty) {
          // Process events and merge with cached AI data
          for (var event in sportsbookEvents) {
            final eventId = event['event_id']?.toString();
            if (eventId == null) continue;

            final bookmarks = event['bookmark'] as List<dynamic>?;
            if (bookmarks == null) continue;

            for (var bookmark in bookmarks) {
              final marketPlace = bookmark['market_title'] as String?;
              if (marketPlace == null) continue;

              // Find existing cached event and preserve AI data
              List<Map<String, dynamic>>? targetList;
              switch (marketPlace) {
                case 'FanDuel':
                  targetList = _savedFanduelEvents;
                  break;
                case 'DraftKings':
                  targetList = _savedDraftkingsEvents;
                  break;
                case 'BetMGM':
                  targetList = _savedBetMgmEvents;
                  break;
              }

              if (targetList != null) {
                final idx = targetList.indexWhere((e) => e['event_id'] == eventId);
                if (idx != -1) {
                  // Preserve existing AI data
                  final cachedAiAway = targetList[idx]['bookmark']?['ai_moneyline_away'] as String?;
                  final cachedAiHome = targetList[idx]['bookmark']?['ai_moneyline_home'] as String?;
                  
                  if (cachedAiAway != null || cachedAiHome != null) {
                    bookmark['ai_moneyline_away'] = cachedAiAway;
                    bookmark['ai_moneyline_home'] = cachedAiHome;
                  }
                }
              }
            }
          }
        }

        // Refresh data and fetch new AI predictions
        await fetchSavedEvents();
      }
    } catch (e) {
      print("Error fetching saved events in background: $e");
    }
  }

  /// Load cached saved events
  Future<bool> loadCachedSavedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTimestampStr = prefs.getString(_savedEventsCacheTimestampKey);

      if (cachedTimestampStr == null) {
        print("No cached saved events found");
        return false;
      }

      final timestamp = DateTime.parse(cachedTimestampStr);
      final now = DateTime.now();

      if (now.difference(timestamp) > _savedCacheDuration) {
        print("Saved events cache expired (30 min) - will fetch fresh data");
        return false;
      }

      final cachedData = prefs.getString(_savedEventsCacheKey);
      if (cachedData == null) return false;

      final List decoded = jsonDecode(cachedData);
      
      // Restore saved events from cache
      if (decoded is List && decoded.isNotEmpty) {
        for (var item in decoded) {
          if (item is Map<String, dynamic>) {
            final marketPlace = item['marketPlace'] as String?;
            final eventData = item['data'] as Map<String, dynamic>?;
            final eventId = eventData?['event_id'] as String?;

            if (marketPlace == null || eventId == null || eventData == null) continue;

            switch (marketPlace) {
              case 'FanDuel':
                if (!_savedFanduelEventIds.contains(eventId)) {
                  _savedFanduelEventIds.add(eventId);
                  _savedFanduelEvents.add(eventData);
                }
                break;
              case 'DraftKings':
                if (!_savedDraftkingsEventIds.contains(eventId)) {
                  _savedDraftkingsEventIds.add(eventId);
                  _savedDraftkingsEvents.add(eventData);
                }
                break;
              case 'BetMGM':
                if (!_savedBetMgmEventIds.contains(eventId)) {
                  _savedBetMgmEventIds.add(eventId);
                  _savedBetMgmEvents.add(eventData);
                }
                break;
            }
          }
        }

        final totalCount = _savedFanduelEvents.length + 
                          _savedDraftkingsEvents.length + 
                          _savedBetMgmEvents.length;
        
        if (totalCount > 0) {
          print("Loaded $totalCount cached saved events");
          update();
          return true;
        }
      }

      return false;
    } catch (e) {
      print("Error loading cached saved events: $e");
      return false;
    }
  }

  /// Cache saved events to local storage
  Future<void> cacheSavedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> dataToCache = [];

      // Cache FanDuel events
      for (var event in _savedFanduelEvents) {
        dataToCache.add({
          'marketPlace': 'FanDuel',
          'data': event,
        });
      }

      // Cache DraftKings events
      for (var event in _savedDraftkingsEvents) {
        dataToCache.add({
          'marketPlace': 'DraftKings',
          'data': event,
        });
      }

      // Cache BetMGM events
      for (var event in _savedBetMgmEvents) {
        dataToCache.add({
          'marketPlace': 'BetMGM',
          'data': event,
        });
      }

      if (dataToCache.isEmpty) return;

      await prefs.setString(_savedEventsCacheKey, jsonEncode(dataToCache));
      await prefs.setString(
        _savedEventsCacheTimestampKey,
        DateTime.now().toIso8601String(),
      );

      print("Cached ${dataToCache.length} saved events (30 min)");
    } catch (e) {
      print("Error caching saved events: $e");
    }
  }

  Future<bool> saveEvent({
    required String eventId,
    required String marketPlace,
    String? title,
    String? subtitle,
    String? endDate,
    String? marketPercentage,
    String? aiPercentage,
    String? team,
    Map<String, dynamic>? bookmark,
  }) async {
    print('💾 saveEvent called - eventId: $eventId, marketPlace: $marketPlace');
    print('💾 Current saved IDs - FanDuel: $_savedFanduelEventIds, DraftKings: $_savedDraftkingsEventIds, BetMGM: $_savedBetMgmEventIds');
    
    try {
      final url = '${Urls.baseUrl}/api/trade/saved-event/';
      print("=== Save Sports Event API ===");
      print("URL: $url");

      // Get token from SharedPreferencesHelper
      final token = await SharedPreferencesHelper.getAccessToken();
      print("Token: ${token?.substring(0, 20)}...");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'event_id': eventId,
          'market_place': 'SportsBook',
        }),
      );

      print("Request Body: {event_id: $eventId, market_place: SportsBook}");
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=====================");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Event saved successfully!");

        // Build event data to add to saved list
        final eventData = <String, dynamic>{
          'event_id': eventId,
          'title': title ?? 'NBA Championship Odds 2026',
          'subtitle': subtitle ?? '',
          'endDate': endDate ?? '',
          'marketPercentage': marketPercentage ?? '',
          'aiPercentage': aiPercentage, // null if not available - shows shimmer
          'team': team ?? '',
          'marketPlace': marketPlace,
          'bookmark': bookmark ?? {},
        };

        // Update local state and notify listeners
        switch (marketPlace) {
          case 'FanDuel':
            print('💾 Adding to FanDuel saved: $eventId');
            if (!_savedFanduelEventIds.contains(eventId)) {
              _savedFanduelEventIds.add(eventId);
              // Add to saved events list immediately
              _savedFanduelEvents.add(eventData);
              print('💾 FanDuel IDs now: $_savedFanduelEventIds');
            }
            break;
          case 'DraftKings':
            print('💾 Adding to DraftKings saved: $eventId');
            if (!_savedDraftkingsEventIds.contains(eventId)) {
              _savedDraftkingsEventIds.add(eventId);
              // Add to saved events list immediately
              _savedDraftkingsEvents.add(eventData);
              print('💾 DraftKings IDs now: $_savedDraftkingsEventIds');
            }
            break;
          case 'BetMGM':
            print('💾 Adding to BetMGM saved: $eventId');
            if (!_savedBetMgmEventIds.contains(eventId)) {
              _savedBetMgmEventIds.add(eventId);
              // Add to saved events list immediately
              _savedBetMgmEvents.add(eventData);
              print('💾 BetMGM IDs now: $_savedBetMgmEventIds');
            }
            break;
        }

        // Update cache
        cacheSavedEvents();

        // Notify GetX listeners to rebuild UI
        print('💾 Calling update() for saved_events');
        update(['saved_events']);

        return true;
      } else {
        print("Failed to save event: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Save event error: $e");
      return false;
    }
  }
  void saveDraftkingsEvent({required String eventId, required String marketPlace}) {
    saveEvent(eventId: eventId, marketPlace: marketPlace);
  }
}
