import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:murchin/const/service/endpoint.dart';
import 'package:murchin/const/service/shared_preference_helper.dart';

class HomeController extends GetxController {
  final selectedPlatform = 0.obs; // 0: All, 1: Polymarket, 2: Kalshi

  final isLoading = false.obs;
  final isPageLoading = false.obs;
  final isSearching = false.obs;

  final RxList<Map<String, dynamic>> _events = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _searchResults =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _kalshiEvents =
      <Map<String, dynamic>>[].obs;

  List<Map<String, dynamic>> get events =>
      isSearching.value ? _searchResults : _events;

  List<Map<String, dynamic>> get allEvents => _events;

  List<Map<String, dynamic>> get kalshiEvents => _kalshiEvents;

  List<Map<String, dynamic>> get savedPolymarketEvents => _savedPolymarketEvents;

  List<Map<String, dynamic>> get savedKalshiEvents => _savedKalshiEvents;

  set events(List<Map<String, dynamic>> newEvents) {
    _events.assignAll(newEvents);
  }

  String? nextPageUrl;
  String? kalshiNextPageUrl;

  bool sendMarketPrediction = true;

  final String aiUrl = "https://ai.pickfair.ai/api/v1/prediction/predict";

  static const String _cacheKey = 'cached_ai_values';
  static const String _cacheTimestampKey = 'cached_ai_values_timestamp';
  static const Duration _cacheDuration = Duration(hours: 12);
  static const int _maxCachedEvents = 10;

  static const String _kalshiCacheKey = 'cached_kalshi_ai_values';
  static const String _kalshiCacheTimestampKey = 'cached_kalshi_ai_timestamp';
  static const String _kalshiEventsCacheKey = 'cached_kalshi_events';

  // Saved events caching - 12 hours cache (same as homepage)
  static const String _savedEventsCacheKey = 'cached_saved_market_events_v1';
  static const String _savedEventsCacheTimestampKey = 'cached_saved_market_timestamp_v1';
  static const Duration _savedCacheDuration = Duration(hours: 12);

  bool _isLoadingCache = false;

  final Set<int> _cachedEventIndexes = <int>{};

  static const int _maxEventsPerSection = 5; // Show only 5 events per platform
  static const int _eventsPerPage = 5;
  static const int _maxPagesToLoad = 10; // Load up to 10 pages to get 5 valid events
  static const int _maxAllTabEvents = 3; // Show 3 events from each platform in All tab

  int _polymarketPagesLoaded = 0;
  int _kalshiPagesLoaded = 0;

  Timer? _debounceTimer;
  final TextEditingController searchController = TextEditingController();

  // Singleton HTTP client for connection reuse (keep-alive)
  final http.Client _httpClient = http.Client();

  // Request deduplication for AI predictions - track pending requests
  final Map<String, Future<Map<String, dynamic>>> _pendingAiRequests = {};
  final Map<String, DateTime> _aiRequestTimestamps = {};

  @override
  void onInit() {
    super.onInit();

    // Fetch fresh data when controller initializes
    _fetchFreshDataInBackground();
  }

  /// Fetch fresh data in background (completely non-blocking, parallel loading)
  Future<void> _fetchFreshDataInBackground() async {
    // Fetch saved events from API every time
    await fetchSavedEvents();
    
    // Fetch Polymarket and Kalshi events SIMULTANEOUSLY (no delays, no awaits)
    // Both run in parallel for faster loading
    fetchPolymarketEvents(backgroundOnly: true);
    fetchKalshiEvents(backgroundOnly: true);
  }

  void selectPlatform(int index) {
    selectedPlatform.value = index;
  }

  // =========================================================
  // 🔥 NEW — DETAIL SCREEN FORCE AI FETCH
  // =========================================================

  Future<void> fetchAIForEventByTitle(String title) async {
    try {
      // Check if event is in saved Polymarket events first
      final savedIdx = _savedPolymarketEvents.indexWhere((e) => e['title'] == title);

      if (savedIdx != -1) {
        final e = _savedPolymarketEvents[savedIdx];

        // Skip if explanation already exists
        if (e['aiExplanation'] != null && e['aiExplanation'].toString().isNotEmpty) {
          return;
        }

        final filtered = _buildFilteredOptions(e);

        final aiData = await fetchAIValue(
          eventName: e['title'],
          options: filtered['options'],
          marketPredictions: filtered['marketProbs'],
          baseEvent: e,
          originalIndices: filtered['originalIndices'],
        );

        // Skip if AI data is null or empty (API failed)
        if (aiData['aiPercentage'] == null || aiData['aiPercentage'].toString().isEmpty) {
          return;
        }

        List<Map<String, dynamic>> newList = List.from(_savedPolymarketEvents);
        newList[savedIdx] = aiData;
        _savedPolymarketEvents.assignAll(newList);
        update();

        print("Detail AI fetched for $title (saved events)");
        return;
      }

      // Check if event is in search results
      bool isInSearch = isSearching.value && _searchResults.any((e) => e['title'] == title);

      if (isInSearch) {
        // Update search results
        final idx = _searchResults.indexWhere((e) => e['title'] == title);
        if (idx == -1) return;

        final e = _searchResults[idx];

        // Skip if explanation already exists
        if (e['aiExplanation'] != null && e['aiExplanation'].toString().isNotEmpty) {
          return;
        }

        final filtered = _buildFilteredOptions(e);

        final aiData = await fetchAIValue(
          eventName: e['title'],
          options: filtered['options'],
          marketPredictions: filtered['marketProbs'],
          baseEvent: e,
          originalIndices: filtered['originalIndices'],
        );

        // Skip if AI data is null or empty (API failed)
        if (aiData['aiPercentage'] == null || aiData['aiPercentage'].toString().isEmpty) {
          return;
        }

        List<Map<String, dynamic>> newResults = List.from(_searchResults);
        newResults[idx] = aiData;
        _searchResults.assignAll(newResults);
        update();

        print("Detail AI fetched for $title (search results)");
      } else {
        // Update main events list
        final idx = _events.indexWhere((e) => e['title'] == title);
        if (idx == -1) return;

        final e = _events[idx];

        // Skip if explanation already exists
        if (e['aiExplanation'] != null && e['aiExplanation'].toString().isNotEmpty) {
          return;
        }

        final filtered = _buildFilteredOptions(e);

        final aiData = await fetchAIValue(
          eventName: e['title'],
          options: filtered['options'],
          marketPredictions: filtered['marketProbs'],
          baseEvent: e,
          originalIndices: filtered['originalIndices'],
        );

        // Skip if AI data is null or empty (API failed)
        if (aiData['aiPercentage'] == null || aiData['aiPercentage'].toString().isEmpty) {
          return;
        }

        List<Map<String, dynamic>> newEvents = List.from(_events);
        newEvents[idx] = aiData;
        _events.assignAll(newEvents);
        update();

        print("Detail AI fetched for $title (main events)");
      }
    } catch (e) {
      print("Detail AI fetch error: $e");
    }
  }

  // =========================================================
  // 🔥 NEW — SHARED FILTER LOGIC
  // =========================================================

  Map<String, dynamic> _buildFilteredOptions(Map<String, dynamic> e) {
    List<String> filteredOptions = [];
    List<double> filteredMarketProbs = [];
    List<int> originalIndices = [];

    for (int j = 0; j < e['optionTitles'].length; j++) {
      final marketProb = e['marketProbs'][j] as double;
      if (marketProb <= 0) continue; // Skip 0% values
      filteredOptions.add(e['optionTitles'][j]);
      filteredMarketProbs.add(marketProb);
      originalIndices.add(j);
    }

    // Keep the market leader at index 0
    String highestMarketTeam = e['team'];
    int highestMarketIndex = filteredOptions.indexOf(highestMarketTeam);

    if (highestMarketIndex != -1 && highestMarketIndex != 0) {
      final topOption = filteredOptions.removeAt(highestMarketIndex);
      final topProb = filteredMarketProbs.removeAt(highestMarketIndex);
      final topIndex = originalIndices.removeAt(highestMarketIndex);

      filteredOptions.insert(0, topOption);
      filteredMarketProbs.insert(0, topProb);
      originalIndices.insert(0, topIndex);
    }

    return {
      "options": filteredOptions,
      "marketProbs": filteredMarketProbs,
      "originalIndices": originalIndices,
    };
  }

  // ================= EXISTING CODE BELOW =================

  Future<void> loadCachedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_events');

    if (cached != null) {
      final List decoded = jsonDecode(cached);

      final List<Map<String, dynamic>> eventsWithDefaults = decoded.map((e) {
        final event = Map<String, dynamic>.from(e);

        if (!event.containsKey('aiPercentages')) {
          event['aiPercentages'] = [];
        }
        return event;
      }).toList();

      _events.assignAll(eventsWithDefaults);
    }
  }

  Future<void> cacheEvents(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_events', jsonEncode(list));
  }

  // ================= FETCH EVENTS =================

  Future<void> fetchPolymarketEvents({
    String? url,
    bool backgroundOnly = false,
    bool isAutoLoad = false,
  }) async {
    final requestUrl =
        url ?? '${Urls.baseUrl}/api/trade/polymarket-event-list/';

    try {
      if (url == null && !backgroundOnly && !isAutoLoad) {
        isLoading.value = true;
        _polymarketPagesLoaded = 0; // Reset page counter
      } else if (!backgroundOnly && !isAutoLoad) {
        isPageLoading.value = true;
      }

      final response = await http.get(Uri.parse(requestUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final eventsList = data['results']?['events'];

        if (eventsList == null || eventsList.isEmpty) {
          if (url == null) {
            isLoading.value = false;
          } else {
            isPageLoading.value = false;
          }
          return;
        }

        List<Map<String, dynamic>> tempEvents = [];

        for (var event in eventsList) {
          final outcomes = event['question_outcome'] as List<dynamic>?;

          if (event['title'] == null || event['title'].toString().isEmpty)
            continue;
          if (outcomes == null || outcomes.isEmpty) continue;

          // Filter out outcomes that are invalid (empty title or missing probability)
          final validOutcomes = outcomes.where((o) {
            final title = o['group_item_title']?.toString() ?? '';
            final probStr = o['probability']?.toString() ?? '';
            final prob = double.tryParse(probStr) ?? -1;
            return title.isNotEmpty && prob >= 0;
          }).toList();

          if (validOutcomes.isEmpty) continue; // skip if no valid outcomes

          String highestTeam = '';
          double highestProb = -1;

          List<String> optionTitles = [];
          List<double> marketProbs = [];

          for (var outcome in validOutcomes) {
            final prob =
                double.tryParse(outcome['probability'].toString()) ?? 0;
            final title = outcome['group_item_title'] ?? '';

            // Skip 0% values here for the event itself
            if (prob <= 0) continue;

            optionTitles.add(title);
            marketProbs.add(prob);

            if (prob > highestProb) {
              highestProb = prob;
              highestTeam = title;
            }
          }

          // Skip event entirely if no options left
          if (optionTitles.isEmpty) continue;

          int roundedPercentage = highestProb.floor();
          if (highestProb - roundedPercentage >= 0.5) {
            roundedPercentage += 1;
          }

          final marketPercentage = '${roundedPercentage}%';

          tempEvents.add({
            'event_id': event['event_id'],
            'title': event['title'],
            'slug': event['slug'] ?? '',
            'imageUrl': event['image_url'] ?? '',
            'endDate': event['end_date'] ?? '',
            'team': highestTeam,
            'marketPercentage': marketPercentage,
            'aiPercentage': null,
            'aiExplanation': '',
            'optionTitles': optionTitles,
            'marketProbs': marketProbs,
            'aiPercentages': [],
          });
        }

        if (url != null) {
          _events.addAll(tempEvents);
        } else {
          _events.assignAll(tempEvents);
        }

        // Store next page URL but auto-load second page if needed
        if (url == null) {
          nextPageUrl = data['next'];
          _polymarketPagesLoaded = 1;
          cacheEvents(events);

          // Auto-load more pages if we have less than 10 events and next page exists
          if (_events.length < _maxEventsPerSection && nextPageUrl != null) {
            await fetchPolymarketEvents(url: nextPageUrl, isAutoLoad: true);
          } else {
            // Limit to 10 events after loading for initial display
            if (_events.length > _maxEventsPerSection) {
              _events.assignAll(_events.take(_maxEventsPerSection).toList());
            }
            // Keep nextPageUrl for "All" tab infinite scroll - don't set to null
            // nextPageUrl remains available for loadMoreForAllTab()
          }
        } else if (isAutoLoad) {
          // Auto-loading additional pages
          _polymarketPagesLoaded++;
          cacheEvents(events);

          // Continue loading if still need more events and have more pages
          if (_events.length < _maxEventsPerSection && data['next'] != null && _polymarketPagesLoaded < _maxPagesToLoad) {
            nextPageUrl = data['next'];
            await fetchPolymarketEvents(url: nextPageUrl, isAutoLoad: true);
          } else {
            // Reached 10 events or max pages
            if (_events.length > _maxEventsPerSection) {
              _events.assignAll(_events.take(_maxEventsPerSection).toList());
            }
            // Keep nextPageUrl for "All" tab infinite scroll
            if (data['next'] != null) {
              nextPageUrl = data['next'];
            }
          }
        }

        // Load cached AI values
        final hasValidCache = await loadCachedAIData();
        if (hasValidCache) {
          loadEventsWithCachedAI();
          print("✅ Homepage using cached AI data (cache valid)");
        } else {
          print("⚠️ Homepage cache expired - fetching fresh AI for visible events");
          // Cache expired - fetch fresh AI for first 5 events
          for (int i = 0; i < tempEvents.length && i < 5; i++) {
            final e = tempEvents[i];
            final filtered = _buildFilteredOptions(e);
            
            fetchAIValue(
              eventName: e['title'],
              options: filtered['options'],
              marketPredictions: filtered['marketProbs'],
              baseEvent: e,
              originalIndices: filtered['originalIndices'],
            ).then((aiData) async {
              if (aiData['aiPercentage'] == null || aiData['aiPercentage'].toString().isEmpty) {
                return;
              }
              
              final idx = _events.indexWhere((ev) => ev['title'] == aiData['title']);
              if (idx != -1) {
                List<Map<String, dynamic>> newEvents = List.from(_events);
                newEvents[idx] = aiData;
                _events.assignAll(newEvents);
                update();
                
                // Save to cache
                await saveAIDataToCache();
              }
            });
          }
        }
      }
    } catch (e) {
      print("Error in fetchPolymarketEvents: $e");
    } finally {
      if (!backgroundOnly && !isAutoLoad) {
        if (url == null) {
          isLoading.value = false;
        } else {
          isPageLoading.value = false;
        }
      }
    }
  }

  // ================= KALSHI EVENTS =================

  Future<void> fetchKalshiEvents({
    String? url,
    bool backgroundOnly = false,
    bool isAutoLoad = false,
  }) async {
    final requestUrl = url ?? Urls.kalshiEventListUrl;

    try {
      if (url == null && !backgroundOnly && !isAutoLoad) {
        isLoading.value = true;
        _kalshiPagesLoaded = 0; // Reset page counter
      } else if (!backgroundOnly && !isAutoLoad) {
        isPageLoading.value = true;
      }

      final response = await http.get(Uri.parse(requestUrl));

      print("Kalshi API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final eventsList = data['results']?['events'] as List<dynamic>?;

        if (eventsList == null || eventsList.isEmpty) {
          print("No Kalshi events found");
          if (url == null) {
            isLoading.value = false;
          } else {
            isPageLoading.value = false;
          }
          return;
        }

        List<Map<String, dynamic>> tempEvents = [];

        for (var event in eventsList) {
          final outcomes = event['outcomes'] as List<dynamic>?;

          if (event['title'] == null || event['title'].toString().isEmpty)
            continue;
          if (outcomes == null || outcomes.isEmpty) continue;

          // Process outcomes to find the highest probability_yes (excluding 0 and 100)
          String highestTeam = '';
          double highestProb = -1;

          List<String> optionTitles = [];
          List<double> marketProbs = [];

          // Check if we have multiple outcomes or just one
          if (outcomes.length == 1) {
            // Single outcome - use it directly
            final outcome = outcomes[0];
            final probYes = double.tryParse(outcome['probability_yes'].toString()) ?? -1;
            final titleYes = outcome['group_item_title_yes']?.toString() ?? '';

            if (probYes > 0 && probYes < 100 && titleYes.isNotEmpty) {
              highestTeam = titleYes;
              highestProb = probYes;
              optionTitles.add(titleYes);
              marketProbs.add(probYes);
            }
          } else {
            // Multiple outcomes - find the highest probability_yes (excluding 0 and 100)
            for (var outcome in outcomes) {
              final probYes = double.tryParse(outcome['probability_yes'].toString()) ?? -1;
              final titleYes = outcome['group_item_title_yes']?.toString() ?? '';

              // Skip 0 and 100 values as they are invalid
              if (probYes <= 0 || probYes >= 100) continue;
              if (titleYes.isEmpty) continue;

              optionTitles.add(titleYes);
              marketProbs.add(probYes);

              if (probYes > highestProb) {
                highestProb = probYes;
                highestTeam = titleYes;
              }
            }
          }

          // Skip event entirely if no valid options left
          if (optionTitles.isEmpty) {
            print("Skipping event '${event['title']}' - no valid options");
            continue;
          }

          int roundedPercentage = highestProb.floor();
          if (highestProb - roundedPercentage >= 0.5) {
            roundedPercentage += 1;
          }

          final marketPercentage = '${roundedPercentage}%';

          // For single outcome events, also store the NO probability
          double? probabilityNo;
          String? titleNo;
          if (outcomes.length == 1) {
            final outcome = outcomes[0];
            probabilityNo = double.tryParse(outcome['probability_no'].toString());
            titleNo = outcome['group_item_title_no']?.toString();
          }

          tempEvents.add({
            'event_id': event['event_ticker'],
            'series_ticker': event['series_ticker'] ?? '',
            'title': event['title'],
            'imageUrl': event['img_url'] ?? '',
            'endDate': event['end_date'] ?? '',
            'team': highestTeam,
            'marketPercentage': marketPercentage,
            'aiPercentage': null,
            'aiExplanation': '',
            'optionTitles': optionTitles,
            'marketProbs': marketProbs,
            'aiPercentages': [],
            'market_place': 'Kalshi',
            'probability_no': probabilityNo,
            'title_no': titleNo,
          });

          print("Kalshi event added: ${event['title']} | Market: $marketPercentage | Team: $highestTeam | Options: $optionTitles");
        }

        print("Processed ${tempEvents.length} Kalshi events");

        if (url != null) {
          _kalshiEvents.addAll(tempEvents);
        } else {
          _kalshiEvents.assignAll(tempEvents);
        }

        // Store next page URL but auto-load more pages if needed
        if (url == null) {
          kalshiNextPageUrl = data['next'];
          _kalshiPagesLoaded = 1;
          cacheKalshiEvents(_kalshiEvents);

          // Auto-load more pages if we have less than 10 events and next page exists
          if (_kalshiEvents.length < _maxEventsPerSection && kalshiNextPageUrl != null) {
            await fetchKalshiEvents(url: kalshiNextPageUrl, isAutoLoad: true);
          } else {
            // Limit to 10 events after loading for initial display
            if (_kalshiEvents.length > _maxEventsPerSection) {
              _kalshiEvents.assignAll(_kalshiEvents.take(_maxEventsPerSection).toList());
            }
            // Keep kalshiNextPageUrl for "All" tab infinite scroll - don't set to null
          }
        } else if (isAutoLoad) {
          // Auto-loading additional pages
          _kalshiPagesLoaded++;
          cacheKalshiEvents(_kalshiEvents);

          // Continue loading if still need more events and have more pages
          if (_kalshiEvents.length < _maxEventsPerSection && data['next'] != null && _kalshiPagesLoaded < _maxPagesToLoad) {
            kalshiNextPageUrl = data['next'];
            await fetchKalshiEvents(url: kalshiNextPageUrl, isAutoLoad: true);
          } else {
            // Reached 10 events or max pages
            if (_kalshiEvents.length > _maxEventsPerSection) {
              _kalshiEvents.assignAll(_kalshiEvents.take(_maxEventsPerSection).toList());
            }
            // Keep kalshiNextPageUrl for "All" tab infinite scroll
            if (data['next'] != null) {
              kalshiNextPageUrl = data['next'];
            }
          }
        }

        // Load cached AI values only if cache is valid (same as Polymarket)
        if (await loadCachedKalshiEventsData()) {
          await _loadKalshiCachedAIValues();
        }

        // Count how many events need AI fetch
        int needAiFetch = _kalshiEvents.where((e) => e['aiPercentage'] == null || e['aiPercentage'].toString().isEmpty).length;
        print("Kalshi events total: ${_kalshiEvents.length}, need AI fetch: $needAiFetch");

        // Fetch AI predictions for Kalshi events (only for events without AI data)
        int aiFetchCount = 0;
        for (int i = 0; i < _kalshiEvents.length && i < 5; i++) {
          final e = _kalshiEvents[i];

          // Skip if AI data already exists
          if (e['aiPercentage'] != null && e['aiPercentage'].toString().isNotEmpty) {
            continue;
          }

          final filtered = _buildFilteredOptions(e);

          print("Kalshi AI fetch: ${e['title']} with options: ${filtered['options']}");
          print("Kalshi market probs: ${filtered['marketProbs']}");

          fetchAIValue(
            eventName: e['title'],
            options: filtered['options'],
            marketPredictions: filtered['marketProbs'],
            baseEvent: e,
            originalIndices: filtered['originalIndices'],
          ).then((aiData) async {
            print("Kalshi AI received for: ${aiData['title']}");
            print("Kalshi AI percentage: ${aiData['aiPercentage']}");

            // Skip if AI data is null or empty (API failed or returned invalid data)
            if (aiData['aiPercentage'] == null || aiData['aiPercentage'].toString().isEmpty) {
              print("Kalshi AI returned null/empty, keeping cached value");
              return;
            }

            final idx = _kalshiEvents.indexWhere(
              (ev) => ev['event_id'] == aiData['event_id'],
            );

            if (idx != -1) {
              // Only update if we got valid AI data
              final currentEvent = _kalshiEvents[idx];

              // Skip if current event already has AI data (from cache)
              if (currentEvent['aiPercentage'] != null &&
                  currentEvent['aiPercentage'].toString().isNotEmpty) {
                print("Event already has AI data from cache, skipping update");
                return;
              }

              List<Map<String, dynamic>> newEvents = List.from(_kalshiEvents);
              newEvents[idx] = aiData;

              _kalshiEvents.assignAll(newEvents);
              update();

              print("Kalshi AI updated at index $idx");

              aiFetchCount++;

              // Save AI data to cache after fetching
              if (aiFetchCount <= _maxCachedEvents) {
                await saveKalshiAIDataToCache();
                await cacheKalshiEvents(_kalshiEvents);
              }
            } else {
              print("Kalshi AI update failed - event not found: ${aiData['event_id']}");
            }
          });
        }
      }
    } catch (e) {
      print("Error in fetchKalshiEvents: $e");
    } finally {
      if (!backgroundOnly && !isAutoLoad) {
        if (url == null) {
          isLoading.value = false;
        } else {
          isPageLoading.value = false;
        }
      }
    }
  }

  // ================= CACHE KALSHI EVENTS =================

  Future<void> cacheKalshiEvents(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    // Cache only first 100 events
    final eventsToCache = list.length > _maxCachedEvents ? list.take(_maxCachedEvents).toList() : list;
    await prefs.setString(_kalshiEventsCacheKey, jsonEncode(eventsToCache));
  }

  Future<bool> loadCachedKalshiEventsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_kalshiCacheTimestampKey);

      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final difference = DateTime.now().difference(timestamp);

      return difference <= _cacheDuration;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadCachedKalshiEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kalshiEventsCacheKey);

    if (cached != null) {
      final List decoded = jsonDecode(cached);

      final List<Map<String, dynamic>> eventsWithDefaults = decoded.map((e) {
        final event = Map<String, dynamic>.from(e);

        if (!event.containsKey('aiPercentages')) {
          event['aiPercentages'] = [];
        }
        return event;
      }).toList();

      _kalshiEvents.assignAll(eventsWithDefaults);
      print("Loaded ${_kalshiEvents.length} cached Kalshi events");
      
      // Debug: Check how many events have AI data
      int withAi = _kalshiEvents.where((e) => e['aiPercentage'] != null && e['aiPercentage'].toString().isNotEmpty).length;
      print("Cached Kalshi events with AI data: $withAi / ${_kalshiEvents.length}");
    } else {
      print("No cached Kalshi events found");
    }
  }

  Future<void> _loadKalshiCachedAIValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAIDataJson = prefs.getString(_kalshiCacheKey);

      if (cachedAIDataJson != null) {
        final cachedAIData = jsonDecode(cachedAIDataJson) as List<dynamic>;

        // Merge cached AI values into current events by index (same as Polymarket)
        int mergedCount = 0;
        for (int i = 0; i < _kalshiEvents.length && i < cachedAIData.length && i < _maxCachedEvents; i++) {
          final cachedEvent = cachedAIData[i] as Map<String, dynamic>;

          _kalshiEvents[i] = {
            ..._kalshiEvents[i],
            'aiPercentage': cachedEvent['aiPercentage'],
            'aiExplanation': '', // Don't load cached explanation
          };
          mergedCount++;
        }

        update();
        print("Loaded cached Kalshi AI values for $mergedCount events");
      }
    } catch (e) {
      print("Error loading Kalshi cached AI values: $e");
    }
  }

  Future<void> saveKalshiAIDataToCache() async {
    try {
      List<Map<String, dynamic>> aiDataToCache = [];

      for (int i = 0; i < _kalshiEvents.length && i < _maxCachedEvents; i++) {
        final event = _kalshiEvents[i];

        if (event['aiPercentage'] != null) {
          aiDataToCache.add({
            'aiPercentage': event['aiPercentage'],
            'aiExplanation': '', // Don't cache explanation
          });
        }
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_kalshiCacheKey, jsonEncode(aiDataToCache));
      await prefs.setString(
        _kalshiCacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print("Error saving Kalshi AI data to cache: $e");
    }
  }

  // ================= AI API - SIMPLIFIED =================

  /// Simple, direct AI API call with timing and deduplication
  Future<Map<String, dynamic>> fetchAIValue({
    required String eventName,
    required List<String> options,
    required List<double> marketPredictions,
    required Map<String, dynamic> baseEvent,
    List<int>? originalIndices,
  }) async {
    final cacheKey = 'ai_$eventName';
    final startTime = DateTime.now();

    // Check if request is already in progress - return the same future
    if (_pendingAiRequests.containsKey(cacheKey)) {
      print("⏳ AI request already in progress for: $eventName (reusing pending request)");
      return _pendingAiRequests[cacheKey]!;
    }

    // Check if we made a request very recently (within 2 seconds) - return cached result
    if (_aiRequestTimestamps.containsKey(cacheKey)) {
      final lastRequest = _aiRequestTimestamps[cacheKey]!;
      final timeDiff = startTime.difference(lastRequest);
      if (timeDiff.inSeconds < 2) {
        print("⚡ AI request too soon (${timeDiff.inMilliseconds}ms) for: $eventName - using existing data");
        return baseEvent;
      }
    }

    print("🕐 [${startTime.toString().substring(11, 19)}] 🤖 AI Request START: $eventName");
    print("   Options count: ${options.length}, Market probs: ${marketPredictions.length}");

    // Create the request future
    final requestFuture = _executeAiRequest(
      eventName: eventName,
      options: options,
      marketPredictions: marketPredictions,
      baseEvent: baseEvent,
      originalIndices: originalIndices,
    ).then((result) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print("🕐 [${endTime.toString().substring(11, 19)}] ✅ AI Request END: $eventName (${duration.inMilliseconds}ms)");
      
      // Clean up pending request
      _pendingAiRequests.remove(cacheKey);
      
      return result;
    }).catchError((error) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print("🕐 [${endTime.toString().substring(11, 19)}] ❌ AI Request FAILED: $eventName (${duration.inMilliseconds}ms) - $error");
      
      // Clean up pending request
      _pendingAiRequests.remove(cacheKey);
      
      return baseEvent;
    });

    // Store in pending requests
    _pendingAiRequests[cacheKey] = requestFuture;
    _aiRequestTimestamps[cacheKey] = startTime;

    return requestFuture;
  }

  /// Internal method to actually make the AI request
  Future<Map<String, dynamic>> _executeAiRequest({
    required String eventName,
    required List<String> options,
    required List<double> marketPredictions,
    required Map<String, dynamic> baseEvent,
    List<int>? originalIndices,
  }) async {
    final requestStartTime = DateTime.now();
    try {
      print("   📡 [${requestStartTime.toString().substring(11, 19)}] Preparing multipart request...");
      
      var request = http.MultipartRequest('POST', Uri.parse(aiUrl));

      request.fields['event_name'] = eventName;
      request.fields['options'] = options.join(',');

      if (sendMarketPrediction) {
        List<String> decimalPredictions = marketPredictions
            .map((prob) => (prob / 100).toString())
            .toList();

        request.fields['market_prediction'] = decimalPredictions.join(',');
      }

      final prepareTime = DateTime.now();
      final prepareDuration = prepareTime.difference(requestStartTime);
      print("   📡 [${prepareTime.toString().substring(11, 19)}] Request prepared (${prepareDuration.inMilliseconds}ms), sending...");

      final streamed = await _httpClient.send(request);
      
      final sendTime = DateTime.now();
      final sendDuration = sendTime.difference(requestStartTime);
      print("   📡 [${sendTime.toString().substring(11, 19)}] Request sent (${sendDuration.inMilliseconds}ms), waiting for response...");

      final response = await http.Response.fromStream(streamed);
      
      final responseTime = DateTime.now();
      final responseDuration = responseTime.difference(requestStartTime);
      print("   📡 [${responseTime.toString().substring(11, 19)}] Response received (${responseDuration.inMilliseconds}ms), status: ${response.statusCode}");

      return _processMarketAiResponse(response, baseEvent, options, originalIndices);
    } catch (e) {
      final errorTime = DateTime.now();
      final errorDuration = errorTime.difference(requestStartTime);
      print("   ❌ [${errorTime.toString().substring(11, 19)}] AI Error for $eventName after ${errorDuration.inMilliseconds}ms: $e");
      return baseEvent;
    }
  }

  /// Process market AI response
  Map<String, dynamic> _processMarketAiResponse(
    http.Response response,
    Map<String, dynamic> baseEvent,
    List<String> options,
    List<int>? originalIndices,
  ) {
    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body);

        List<dynamic> probs = json['probabilities'] ?? [];
        List explanations = json['explanations'] ?? [];

        if (probs.isEmpty) {
          print("⚠️ AI returned empty probabilities for ${baseEvent['title']}");
          return baseEvent;
        }

        List<double> aiPercentages = probs
            .map((e) => (double.tryParse(e.toString()) ?? 0) * 100)
            .toList();

        List<String> optionTitles = List<String>.from(
          baseEvent['optionTitles'],
        );

        List<double> finalAiPercentages = List<double>.filled(
          optionTitles.length,
          0.0,
        );

        if (originalIndices != null && originalIndices.isNotEmpty) {
          int safeLength = originalIndices.length < aiPercentages.length
              ? originalIndices.length
              : aiPercentages.length;

          for (int i = 0; i < safeLength; i++) {
            int originalIndex = originalIndices[i];

            if (originalIndex < finalAiPercentages.length) {
              finalAiPercentages[originalIndex] = aiPercentages[i];
            }
          }
        }

        String marketTeam = baseEvent['team'] ?? '';
        int marketIndex = optionTitles.indexOf(marketTeam);

        double aiValueForMarket = 0;

        if (marketIndex != -1 && marketIndex < finalAiPercentages.length) {
          aiValueForMarket = finalAiPercentages[marketIndex];
        }

        print("✅ AI Success: ${baseEvent['title']} = ${aiValueForMarket.round()}%");

        return {
          ...baseEvent,
          'aiPercentage': aiValueForMarket > 0 ? '${aiValueForMarket.round()}%' : null,
          'aiExplanation': explanations.isNotEmpty ? explanations.first : '',
          'aiPercentages': finalAiPercentages,
        };
      } catch (e) {
        print("❌ AI response parse error: $e");
        return baseEvent;
      }
    }

    print("❌ AI API error: status ${response.statusCode}");
    return baseEvent;
  }

  // ================= SEARCH =================

  Future<void> searchPolymarketEvents(String query) async {
    if (query.trim().isEmpty) {
      isSearching.value = false;
      _searchResults.clear();
      return;
    }

    try {
      isSearching.value = true;
      isPageLoading.value = true;

      final url =
          '${Urls.baseUrl}/api/trade/title-search/?query=${Uri.encodeComponent(query)}';
      print("Searching for: $query");
      print("API URL: $url");

      final response = await http.get(Uri.parse(url));

      print("Search response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final polymarketEvents = data['polymarket_events'] as List<dynamic>?;

        if (polymarketEvents == null || polymarketEvents.isEmpty) {
          print("No search results found for: $query");
          _searchResults.clear();
          isPageLoading.value = false;
          return;
        }

        List<Map<String, dynamic>> tempEvents = [];

        for (var event in polymarketEvents) {
          final outcomes = event['question_outcome'] as List<dynamic>?;

          if (event['title'] == null || event['title'].toString().isEmpty)
            continue;
          if (outcomes == null || outcomes.isEmpty) continue;

          final validOutcomes = outcomes.where((o) {
            final title = o['group_item_title']?.toString() ?? '';
            final probStr = o['probability']?.toString() ?? '';
            final prob = double.tryParse(probStr) ?? -1;
            return title.isNotEmpty && prob >= 0;
          }).toList();

          if (validOutcomes.isEmpty) continue;

          String highestTeam = '';
          double highestProb = -1;

          List<String> optionTitles = [];
          List<double> marketProbs = [];

          for (var outcome in validOutcomes) {
            final prob =
                double.tryParse(outcome['probability'].toString()) ?? 0;
            final title = outcome['group_item_title'] ?? '';

            if (prob <= 0) continue;

            optionTitles.add(title);
            marketProbs.add(prob);

            if (prob > highestProb) {
              highestProb = prob;
              highestTeam = title;
            }
          }

          if (optionTitles.isEmpty) continue;

          int roundedPercentage = highestProb.floor();
          if (highestProb - roundedPercentage >= 0.5) {
            roundedPercentage += 1;
          }

          final marketPercentage = '${roundedPercentage}%';

          tempEvents.add({
            'event_id': event['event_id'],
            'title': event['title'],
            'slug': event['slug'] ?? '',
            'imageUrl': event['image_url'] ?? '',
            'endDate': event['end_date'] ?? '',
            'team': highestTeam,
            'marketPercentage': marketPercentage,
            'aiPercentage': null,
            'aiExplanation': '',
            'optionTitles': optionTitles,
            'marketProbs': marketProbs,
            'aiPercentages': [],
          });
        }

        _searchResults.assignAll(tempEvents);
        print("Found ${tempEvents.length} search results for: $query");

        // Fetch AI predictions for search results (limited to first 5)
        int aiFetchCount = 0;
        for (int i = 0; i < tempEvents.length && i < 5; i++) {
          final e = tempEvents[i];
          final filtered = _buildFilteredOptions(e);

          fetchAIValue(
            eventName: e['title'],
            options: filtered['options'],
            marketPredictions: filtered['marketProbs'],
            baseEvent: e,
            originalIndices: filtered['originalIndices'],
          ).then((aiData) {
            // Skip if AI data is null or empty (API failed)
            if (aiData['aiPercentage'] == null || aiData['aiPercentage'].toString().isEmpty) {
              return;
            }

            final idx = _searchResults.indexWhere(
              (ev) => ev['title'] == aiData['title'],
            );

            if (idx != -1) {
              List<Map<String, dynamic>> newResults = List.from(_searchResults);
              newResults[idx] = aiData;
              _searchResults.assignAll(newResults);
              update();
            }
          });
        }
      } else {
        print("Search API error: ${response.statusCode}");
      }
    } catch (e) {
      print("Search error: $e");
    } finally {
      isPageLoading.value = false;
    }
  }

  void onSearchQueryChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      searchPolymarketEvents(query);
    });
  }

  void clearSearch() {
    searchController.clear();
    _debounceTimer?.cancel();
    isSearching.value = false;
    _searchResults.clear();
  }

  // ================= SAVE EVENT =================

  final RxSet<int> _savedEventIds = <int>{}.obs;
  final RxSet<String> _savedKalshiEventIds = <String>{}.obs;

  bool isEventSaved(int eventId) => _savedEventIds.contains(eventId);
  bool isKalshiEventSaved(String eventId) => _savedKalshiEventIds.contains(eventId);

  void addSavedEventId(int eventId) => _savedEventIds.add(eventId);
  void removeSavedEventId(int eventId) => _savedEventIds.remove(eventId);
  void addSavedKalshiEventId(String eventId) => _savedKalshiEventIds.add(eventId);
  void removeSavedKalshiEventId(String eventId) => _savedKalshiEventIds.remove(eventId);

  Future<bool> saveEvent({
    int? eventId,
    String? eventIdString,
    required String marketPlace,
    String? title,
    String? slug,
    String? seriesTicker,
    String? imageUrl,
    String? endDate,
    String? team,
    String? marketPercentage,
    String? aiPercentage,
    String? aiExplanation,
    List<String>? optionTitles,
    List<double>? marketProbs,
    List<double>? aiPercentages,
  }) async {
    try {
      final url = '${Urls.baseUrl}/api/trade/saved-event/';
      print("=== Save Event API ===");
      print("URL: $url");

      // Get token from SharedPreferencesHelper
      final token = await SharedPreferencesHelper.getAccessToken();
      print("Token: ${token?.substring(0, 20)}...");

      // Determine which ID to use based on market place
      final dynamic idToSend = eventId ?? (eventIdString as dynamic);

      print("Event ID: $idToSend (${eventId != null ? 'int' : 'String'})");
      print("Market Place: $marketPlace");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'event_id': idToSend,
          'market_place': marketPlace,
        }),
      );

      print("Request Body: {event_id: $idToSend, market_place: $marketPlace}");
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=====================");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Event saved successfully!");

        // Build event data to add to saved list with proper defaults
        final eventData = <String, dynamic>{
          'event_id': eventId ?? eventIdString,
          'title': title ?? '',
          'slug': slug ?? '',
          'series_ticker': seriesTicker ?? '',
          'imageUrl': imageUrl ?? '',
          'endDate': endDate ?? '',
          'team': team ?? '',
          'marketPercentage': marketPercentage ?? '0%',
          'aiPercentage': aiPercentage,
          'aiExplanation': aiExplanation ?? '',
          'optionTitles': optionTitles != null ? List<String>.from(optionTitles) : <String>[],
          'marketProbs': marketProbs != null ? List<double>.from(marketProbs) : <double>[],
          'aiPercentages': aiPercentages != null ? List<double>.from(aiPercentages) : <double>[],
          'market_place': marketPlace,
        };

        // Add to appropriate saved set and list
        if (eventId != null) {
          if (_savedEventIds.contains(eventId)) {
            _savedEventIds.remove(eventId);
            _savedPolymarketEvents.removeWhere((e) => e['event_id'] == eventId);
          } else {
            _savedEventIds.add(eventId);
            _savedPolymarketEvents.add(eventData);
          }
        } else if (eventIdString != null) {
          if (_savedKalshiEventIds.contains(eventIdString)) {
            _savedKalshiEventIds.remove(eventIdString);
            _savedKalshiEvents.removeWhere((e) => e['event_id'] == eventIdString);
          } else {
            _savedKalshiEventIds.add(eventIdString);
            _savedKalshiEvents.add(eventData);
          }
        }

        // Update cache
        cacheSavedEvents();

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

  // ================= FETCH SAVED EVENTS =================

  final RxList<Map<String, dynamic>> _savedPolymarketEvents =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _savedKalshiEvents =
      <Map<String, dynamic>>[].obs;
  final isLoadingSaved = false.obs;
  final hasLoadedSavedCache = false.obs; // Track if cache has been loaded

  Future<void> fetchSavedEvents() async {
    try {
      isLoadingSaved.value = true;
      final url = '${Urls.baseUrl}/api/trade/saved-event-list/';
      print("=== Fetch Saved Events ===");
      print("URL: $url");

      // Get token from SharedPreferencesHelper
      final token = await SharedPreferencesHelper.getAccessToken();
      print("Token: ${token?.substring(0, 20)}...");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Response Body: $data");

        final polymarketEvents = data['polymarket_events'] as List<dynamic>?;
        final kalshiEvents = data['kalshi_events'] as List<dynamic>?;

        // Clear and populate saved event IDs
        _savedEventIds.clear();

        // Process Polymarket events
        if (polymarketEvents != null && polymarketEvents.isNotEmpty) {
          _savedPolymarketEvents.assignAll(
            _processSavedEvents(polymarketEvents, 'Polymarket'),
          );
          // Add event IDs to saved set
          for (var event in polymarketEvents) {
            final eventId = event['event_id'] as int?;
            if (eventId != null) {
              _savedEventIds.add(eventId);
            }
          }
          print("Found ${_savedPolymarketEvents.length} saved Polymarket events");
          
          // Fetch fresh AI for first 5 saved events (for display in saved page list)
          for (int i = 0; i < _savedPolymarketEvents.length && i < 5; i++) {
            final e = _savedPolymarketEvents[i];
            final filtered = _buildFilteredOptions(e);
            
            fetchAIValue(
              eventName: e['title'],
              options: filtered['options'],
              marketPredictions: filtered['marketProbs'],
              baseEvent: e,
              originalIndices: filtered['originalIndices'],
            ).then((aiData) async {
              if (aiData['aiPercentage'] == null || aiData['aiPercentage'].toString().isEmpty) {
                return;
              }
              
              final idx = _savedPolymarketEvents.indexWhere((ev) => ev['title'] == aiData['title']);
              if (idx != -1) {
                List<Map<String, dynamic>> newList = List.from(_savedPolymarketEvents);
                newList[idx] = aiData;
                _savedPolymarketEvents.assignAll(newList);
                update();
              }
            });
          }
        } else {
          _savedPolymarketEvents.clear();
        }

        // Process Kalshi events
        if (kalshiEvents != null && kalshiEvents.isNotEmpty) {
          _savedKalshiEvents.assignAll(
            _processSavedEvents(kalshiEvents, 'Kalshi'),
          );
          print("Found ${_savedKalshiEvents.length} saved Kalshi events");
          
          // Fetch fresh AI for first 5 saved Kalshi events (for display in saved page list)
          for (int i = 0; i < _savedKalshiEvents.length && i < 5; i++) {
            final e = _savedKalshiEvents[i];
            final filtered = _buildFilteredOptions(e);
            
            fetchAIValue(
              eventName: e['title'],
              options: filtered['options'],
              marketPredictions: filtered['marketProbs'],
              baseEvent: e,
              originalIndices: filtered['originalIndices'],
            ).then((aiData) async {
              if (aiData['aiPercentage'] == null || aiData['aiPercentage'].toString().isEmpty) {
                return;
              }
              
              final idx = _savedKalshiEvents.indexWhere((ev) => ev['event_id'] == aiData['event_id']);
              if (idx != -1) {
                List<Map<String, dynamic>> newList = List.from(_savedKalshiEvents);
                newList[idx] = aiData;
                _savedKalshiEvents.assignAll(newList);
                update();
              }
            });
          }
        } else {
          _savedKalshiEvents.clear();
        }
        
        // Cache saved events
        cacheSavedEvents();
      } else {
        print("Failed to fetch saved events: ${response.statusCode}");
      }
    } catch (e) {
      print("Fetch saved events error: $e");
    } finally {
      isLoadingSaved.value = false;
    }
  }

  List<Map<String, dynamic>> _processSavedEvents(
    List<dynamic> events,
    String marketPlace,
  ) {
    List<Map<String, dynamic>> processedEvents = [];

    for (var event in events) {
      // Handle different structures for Polymarket vs Kalshi
      List<dynamic>? outcomes;
      dynamic eventId;
      
      if (marketPlace == 'Kalshi') {
        // Kalshi structure
        outcomes = event['outcomes'] as List<dynamic>?;
        eventId = event['event_ticker'] as String?;
      } else {
        // Polymarket structure
        outcomes = event['question_outcome'] as List<dynamic>?;
        eventId = event['event_id'];
      }

      if (event['title'] == null || event['title'].toString().isEmpty)
        continue;
      if (outcomes == null || outcomes.isEmpty) continue;

      String highestTeam = '';
      double highestProb = -1;

      List<String> optionTitles = [];
      List<double> marketProbs = [];

      if (marketPlace == 'Kalshi') {
        // Process Kalshi outcomes (probability_yes, group_item_title_yes)
        for (var outcome in outcomes) {
          final probYes = double.tryParse(outcome['probability_yes'].toString()) ?? -1;
          final titleYes = outcome['group_item_title_yes']?.toString() ?? '';
          
          // Skip 0 and 100 values
          if (probYes <= 0 || probYes >= 100) continue;
          if (titleYes.isEmpty) continue;

          optionTitles.add(titleYes);
          marketProbs.add(probYes);

          if (probYes > highestProb) {
            highestProb = probYes;
            highestTeam = titleYes;
          }
        }
      } else {
        // Process Polymarket outcomes (probability, group_item_title)
        final validOutcomes = outcomes.where((o) {
          final title = o['group_item_title']?.toString() ?? '';
          final probStr = o['probability']?.toString() ?? '';
          final prob = double.tryParse(probStr) ?? -1;
          return title.isNotEmpty && prob >= 0;
        }).toList();

        if (validOutcomes.isEmpty) continue;

        for (var outcome in validOutcomes) {
          final prob = double.tryParse(outcome['probability'].toString()) ?? 0;
          final title = outcome['group_item_title'] ?? '';

          if (prob <= 0) continue;

          optionTitles.add(title);
          marketProbs.add(prob);

          if (prob > highestProb) {
            highestProb = prob;
            highestTeam = title;
          }
        }
      }

      if (optionTitles.isEmpty) continue;

      int roundedPercentage = highestProb.floor();
      if (highestProb - roundedPercentage >= 0.5) {
        roundedPercentage += 1;
      }

      final marketPercentage = '${roundedPercentage}%';

      processedEvents.add({
        'event_id': eventId,
        'title': event['title'],
        'slug': event['slug'] ?? '',
        'series_ticker': event['series_ticker'] ?? '',
        'imageUrl': (marketPlace == 'Kalshi') 
            ? (event['img_url'] ?? '') 
            : (event['image_url'] ?? ''),
        'endDate': event['end_date'] ?? '',
        'team': highestTeam,
        'marketPercentage': marketPercentage,
        'aiPercentage': null,
        'aiExplanation': '',
        'optionTitles': optionTitles,
        'marketProbs': marketProbs,
        'aiPercentages': [],
        'market_place': marketPlace,
      });
    }

    return processedEvents;
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }

  // ================= CACHE =================

  Future<bool> loadCachedAIData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_cacheTimestampKey);

      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final difference = DateTime.now().difference(timestamp);

      return difference <= _cacheDuration;
    } catch (e) {
      return false;
    }
  }

  void loadEventsWithCachedAI() async {
    try {
      _isLoadingCache = true;

      final prefs = await SharedPreferences.getInstance();
      final cachedAIDataJson = prefs.getString(_cacheKey);

      if (cachedAIDataJson != null) {
        final cachedAIData = jsonDecode(cachedAIDataJson) as List<dynamic>;

        for (
          int i = 0;
          i < events.length && i < cachedAIData.length && i < _maxCachedEvents;
          i++
        ) {
          final cachedEvent = cachedAIData[i] as Map<String, dynamic>;

          events[i] = {
            ...events[i],
            'aiPercentage': cachedEvent['aiPercentage'],
            'aiExplanation': '', // Don't load cached explanation
          };

          _cachedEventIndexes.add(i);
        }
      }
    } finally {
      _isLoadingCache = false;
    }
  }

  Future<void> saveAIDataToCache() async {
    try {
      List<Map<String, dynamic>> aiDataToCache = [];

      for (int i = 0; i < events.length && i < _maxCachedEvents; i++) {
        final event = events[i];

        if (event['aiPercentage'] != null) {
          aiDataToCache.add({
            'aiPercentage': event['aiPercentage'],
            'aiExplanation': '', // Don't cache explanation
          });
        }
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_cacheKey, jsonEncode(aiDataToCache));
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print("Error saving AI data to cache: $e");
    }
  }

  // ================= SAVED EVENTS CACHE (30 MIN) =================

  /// Fetch saved events in background after 30 min cache expires
  Future<void> _fetchSavedEventsInBackground() async {
    try {
      print("=== Fetching Saved Market Events in Background ===");
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
        // Refresh data and fetch new AI predictions
        await fetchSavedEvents();
      }
    } catch (e) {
      print("Error fetching saved market events in background: $e");
    }
  }

  /// Load cached saved market events (30 min cache)
  Future<bool> loadCachedSavedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTimestampStr = prefs.getString(_savedEventsCacheTimestampKey);

      if (cachedTimestampStr == null) {
        print("No cached saved market events found");
        return false;
      }

      final timestamp = DateTime.parse(cachedTimestampStr);
      final now = DateTime.now();

      if (now.difference(timestamp) > _savedCacheDuration) {
        print("Saved market events cache expired (30 min) - will fetch fresh data");
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
            final eventId = eventData?['event_id'];

            if (marketPlace == null || eventData == null) continue;

            if (marketPlace == 'Polymarket') {
              _savedPolymarketEvents.add(eventData);
              if (eventId is int) {
                _savedEventIds.add(eventId);
              }
            } else if (marketPlace == 'Kalshi') {
              _savedKalshiEvents.add(eventData);
              if (eventId is String) {
                _savedKalshiEventIds.add(eventId);
              }
            }
          }
        }

        final totalCount = _savedPolymarketEvents.length + _savedKalshiEvents.length;

        if (totalCount > 0) {
          print("Loaded $totalCount cached saved market events");
          update();
          return true;
        }
      }

      return false;
    } catch (e) {
      print("Error loading cached saved market events: $e");
      return false;
    }
  }

  /// Cache saved market events to local storage (30 min)
  Future<void> cacheSavedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> dataToCache = [];

      // Cache Polymarket events
      for (var event in _savedPolymarketEvents) {
        dataToCache.add({
          'marketPlace': 'Polymarket',
          'data': event,
        });
      }

      // Cache Kalshi events
      for (var event in _savedKalshiEvents) {
        dataToCache.add({
          'marketPlace': 'Kalshi',
          'data': event,
        });
      }

      if (dataToCache.isEmpty) return;

      await prefs.setString(_savedEventsCacheKey, jsonEncode(dataToCache));
      await prefs.setString(
        _savedEventsCacheTimestampKey,
        DateTime.now().toIso8601String(),
      );

      print("Cached ${dataToCache.length} saved market events (30 min)");
    } catch (e) {
      print("Error caching saved market events: $e");
    }
  }
}

/// AI Request class for queue
class _AiRequest {
  final String eventName;
  final List<String> options;
  final List<double> marketPredictions;
  final Map<String, dynamic> baseEvent;
  final List<int>? originalIndices;
  final Completer<Map<String, dynamic>> completer;
  final String cacheKey;

  _AiRequest({
    required this.eventName,
    required this.options,
    required this.marketPredictions,
    required this.baseEvent,
    this.originalIndices,
    required this.completer,
    required this.cacheKey,
  });
}
