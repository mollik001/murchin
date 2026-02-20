import 'dart:convert';
import 'dart:async';
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

  final String aiUrl = "https://abc.dsrt321.online/predict";

  static const String _cacheKey = 'cached_ai_values';
  static const String _cacheTimestampKey = 'cached_ai_values_timestamp';
  static const Duration _cacheDuration = Duration(hours: 12);
  static const int _maxCachedEvents = 100;

  static const String _kalshiCacheKey = 'cached_kalshi_ai_values';
  static const String _kalshiCacheTimestampKey = 'cached_kalshi_ai_timestamp';
  static const String _kalshiEventsCacheKey = 'cached_kalshi_events';

  bool _isLoadingCache = false;

  final Set<int> _cachedEventIndexes = <int>{};

  static const String _pageCachePrefix = 'cached_page_';

  Timer? _debounceTimer;
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    loadCachedEvents();
    
    // Load cached Kalshi events immediately
    loadCachedKalshiEvents();

    // Fetch saved events to populate saved event IDs
    fetchSavedEvents();

    Future.delayed(Duration.zero, () {
      // Load Polymarket with AI cache check
      loadCachedAIData().then((hasValidCache) async {
        if (hasValidCache) {
          loadEventsWithCachedAI();
          await fetchPolymarketEvents(backgroundOnly: true);
        } else {
          await fetchPolymarketEvents();
        }
      });
      
      // Load Kalshi with AI cache check
      loadCachedKalshiEventsData().then((hasValidCache) async {
        if (hasValidCache) {
          // Has valid AI cache, just fetch fresh events in background
          await fetchKalshiEvents(backgroundOnly: true);
        } else {
          // No valid cache, fetch fresh events
          await fetchKalshiEvents();
        }
      });
    });
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
  }) async {
    final requestUrl =
        url ?? '${Urls.baseUrl}/api/trade/polymarket-event-list/';

    try {
      if (url == null && !backgroundOnly) {
        isLoading.value = true;
      } else if (!backgroundOnly) {
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

        nextPageUrl = data['next'];

        if (url == null) {
          cacheEvents(events);
        }

        if (await loadCachedAIData()) {
          loadEventsWithCachedAI();
        }

        int aiFetchCount = 0;

        for (int i = 0; i < tempEvents.length; i++) {
          final e = tempEvents[i];

          final filtered = _buildFilteredOptions(e);

          fetchAIValue(
            eventName: e['title'],
            options: filtered['options'],
            marketPredictions: filtered['marketProbs'],
            baseEvent: e,
            originalIndices: filtered['originalIndices'],
          ).then((aiData) async {
            final idx = events.indexWhere(
              (ev) => ev['title'] == aiData['title'],
            );

            if (idx != -1 && !_cachedEventIndexes.contains(idx)) {
              List<Map<String, dynamic>> newEvents = List.from(_events);
              newEvents[idx] = aiData;

              _events.assignAll(newEvents);

              cacheEvents(_events);
              update();

              aiFetchCount++;

              if (aiFetchCount <= _maxCachedEvents) {
                await saveAIDataToCache();
              }
            }
          });
        }
      }
    } catch (e) {
      print("Error in fetchPolymarketEvents: $e");
    } finally {
      if (!backgroundOnly) {
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
  }) async {
    final requestUrl = url ?? Urls.kalshiEventListUrl;

    try {
      if (url == null && !backgroundOnly) {
        isLoading.value = true;
      } else if (!backgroundOnly) {
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

        kalshiNextPageUrl = data['next'];

        if (url == null) {
          cacheKalshiEvents(_kalshiEvents);
        }

        // Load cached AI values and merge them with fresh events
        await _loadKalshiCachedAIValues();

        // Fetch AI predictions for Kalshi events
        for (int i = 0; i < tempEvents.length; i++) {
          final e = tempEvents[i];

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
            
            final idx = _kalshiEvents.indexWhere(
              (ev) => ev['event_id'] == aiData['event_id'],
            );

            if (idx != -1) {
              // Check if AI data is different from current
              final currentEvent = _kalshiEvents[idx];
              if (currentEvent['aiPercentage'] == aiData['aiPercentage']) {
                return; // Already has this AI data
              }

              List<Map<String, dynamic>> newEvents = List.from(_kalshiEvents);
              newEvents[idx] = aiData;

              _kalshiEvents.assignAll(newEvents);
              update();

              print("Kalshi AI updated at index $idx");
              
              // Save AI data to cache
              await saveKalshiAIDataToCache();
            } else {
              print("Kalshi AI update failed - event not found: ${aiData['event_id']}");
            }
          });
        }
      }
    } catch (e) {
      print("Error in fetchKalshiEvents: $e");
    } finally {
      if (!backgroundOnly) {
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
    }
  }

  Future<void> _loadKalshiCachedAIValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAIDataJson = prefs.getString(_kalshiCacheKey);

      if (cachedAIDataJson != null) {
        final cachedAIData = jsonDecode(cachedAIDataJson) as List<dynamic>;

        // Merge cached AI values into current events list
        for (int i = 0; i < _kalshiEvents.length && i < cachedAIData.length && i < _maxCachedEvents; i++) {
          final cachedEvent = cachedAIData[i] as Map<String, dynamic>;

          _kalshiEvents[i] = {
            ..._kalshiEvents[i],
            'aiPercentage': cachedEvent['aiPercentage'],
            'aiExplanation': '', // Don't load cached explanation
          };
        }
        
        update();
        print("Loaded cached Kalshi AI values for ${cachedAIData.length} events");
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

  // ================= KALSHI PAGINATION =================

  Future<void> loadKalshiNextPage() async {
    if (kalshiNextPageUrl != null && !isPageLoading.value) {
      await fetchKalshiEvents(url: kalshiNextPageUrl);
    }
  }

  // ================= AI API =================

  Future<Map<String, dynamic>> fetchAIValue({
    required String eventName,
    required List<String> options,
    required List<double> marketPredictions,
    required Map<String, dynamic> baseEvent,
    List<int>? originalIndices,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(aiUrl));

      request.fields['event_name'] = eventName;
      request.fields['options'] = options.join(',');

      if (sendMarketPrediction) {
        List<String> decimalPredictions = marketPredictions
            .map((prob) => (prob / 100).toString())
            .toList();

        request.fields['market_prediction'] = decimalPredictions.join(',');
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        List<dynamic> probs = json['probabilities'] ?? [];
        List explanations = json['explanations'] ?? [];

        if (probs.isEmpty) return baseEvent;

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

        return {
          ...baseEvent,
          'aiPercentage': '${aiValueForMarket.round()}%',
          'aiExplanation': explanations.isNotEmpty ? explanations.first : '',
          'aiPercentages': finalAiPercentages,
        };
      }

      return baseEvent;
    } catch (e) {
      print("AI Error: $e");
      return baseEvent;
    }
  }

  // ================= PAGINATION =================

  Future<void> loadNextPage() async {
    if (nextPageUrl != null && !isPageLoading.value) {
      await fetchPolymarketEvents(url: nextPageUrl);
    }
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

  bool isEventSaved(int eventId) => _savedEventIds.contains(eventId);

  void addSavedEventId(int eventId) => _savedEventIds.add(eventId);

  void removeSavedEventId(int eventId) => _savedEventIds.remove(eventId);

  Future<bool> saveEvent({
    required int eventId,
    required String marketPlace,
  }) async {
    try {
      final url = '${Urls.baseUrl}/api/trade/saved-event/';
      print("=== Save Event API ===");
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
          'market_place': marketPlace,
        }),
      );

      print("Request Body: {event_id: $eventId, market_place: $marketPlace}");
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=====================");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Event saved successfully!");
        addSavedEventId(eventId);
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

          // Fetch AI predictions for saved events (limited to first 5)
          for (int i = 0; i < _savedPolymarketEvents.length && i < 5; i++) {
            final e = _savedPolymarketEvents[i];
            final filtered = _buildFilteredOptions(e);

            fetchAIValue(
              eventName: e['title'],
              options: filtered['options'],
              marketPredictions: filtered['marketProbs'],
              baseEvent: e,
              originalIndices: filtered['originalIndices'],
            ).then((aiData) {
              final idx = _savedPolymarketEvents.indexWhere(
                (ev) => ev['title'] == aiData['title'],
              );

              if (idx != -1) {
                List<Map<String, dynamic>> newList = List.from(_savedPolymarketEvents);
                newList[idx] = aiData;
                _savedPolymarketEvents.assignAll(newList);
                update(); // Force UI refresh
                print("AI data updated for saved event: ${aiData['title']}");
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
        } else {
          _savedKalshiEvents.clear();
        }
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

      if (optionTitles.isEmpty) continue;

      int roundedPercentage = highestProb.floor();
      if (highestProb - roundedPercentage >= 0.5) {
        roundedPercentage += 1;
      }

      final marketPercentage = '${roundedPercentage}%';

      processedEvents.add({
        'event_id': event['event_id'],
        'title': event['title'],
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
}
