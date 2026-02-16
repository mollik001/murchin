import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:murchin/const/service/endpoint.dart';

class HomeController extends GetxController {
  final selectedPlatform = 0.obs;

  final isLoading = false.obs;
  final isPageLoading = false.obs;

  final RxList<Map<String, dynamic>> _events = <Map<String, dynamic>>[].obs;

  List<Map<String, dynamic>> get events => _events;

  set events(List<Map<String, dynamic>> newEvents) {
    _events.assignAll(newEvents);
  }

  String? nextPageUrl;

  bool sendMarketPrediction = true;

  final String aiUrl = "https://abc.dsrt321.online/predict";

  static const String _cacheKey = 'cached_ai_values';
  static const String _cacheTimestampKey = 'cached_ai_values_timestamp';
  static const Duration _cacheDuration = Duration(hours: 12);
  static const int _maxCachedEvents = 100;

  bool _isLoadingCache = false;

  final Set<int> _cachedEventIndexes = <int>{};

  static const String _pageCachePrefix = 'cached_page_';

  @override
  void onInit() {
    super.onInit();

    loadCachedEvents();

    Future.delayed(Duration.zero, () {
      loadCachedAIData().then((hasValidCache) async {
        if (hasValidCache) {
          loadEventsWithCachedAI();
          await fetchPolymarketEvents(backgroundOnly: true);
        } else {
          await fetchPolymarketEvents();
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
      final idx = events.indexWhere((e) => e['title'] == title);
      if (idx == -1) return;

      final e = events[idx];

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

      print("Detail AI refreshed for $title");
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

      final List<Map<String, dynamic>> eventsWithDefaults =
          decoded.map((e) {
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

  if (event['title'] == null || event['title'].toString().isEmpty) continue;
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
  final prob = double.tryParse(outcome['probability'].toString()) ?? 0;
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
            final idx =
                events.indexWhere((ev) => ev['title'] == aiData['title']);

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

  // ================= AI API =================

  Future<Map<String, dynamic>> fetchAIValue({
    required String eventName,
    required List<String> options,
    required List<double> marketPredictions,
    required Map<String, dynamic> baseEvent,
    List<int>? originalIndices,
  }) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse(aiUrl));

      request.fields['event_name'] = eventName;
      request.fields['options'] = options.join(',');

      if (sendMarketPrediction) {
        List<String> decimalPredictions = marketPredictions
            .map((prob) => (prob / 100).toString())
            .toList();

        request.fields['market_prediction'] =
            decimalPredictions.join(',');
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        List<dynamic> probs = json['probabilities'] ?? [];
        List explanations = json['explanations'] ?? [];

        if (probs.isEmpty) return baseEvent;

        List<double> aiPercentages =
            probs.map((e) => (double.tryParse(e.toString()) ?? 0) * 100).toList();

        List<String> optionTitles =
            List<String>.from(baseEvent['optionTitles']);

        List<double> finalAiPercentages =
            List<double>.filled(optionTitles.length, 0.0);

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

        if (marketIndex != -1 &&
            marketIndex < finalAiPercentages.length) {
          aiValueForMarket = finalAiPercentages[marketIndex];
        }

        return {
          ...baseEvent,
          'aiPercentage': '${aiValueForMarket.round()}%',
          'aiExplanation':
              explanations.isNotEmpty ? explanations.first : '',
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
        final cachedAIData =
            jsonDecode(cachedAIDataJson) as List<dynamic>;

        for (int i = 0;
            i < events.length &&
                i < cachedAIData.length &&
                i < _maxCachedEvents;
            i++) {
          final cachedEvent =
              cachedAIData[i] as Map<String, dynamic>;

          events[i] = {
            ...events[i],
            'aiPercentage': cachedEvent['aiPercentage'],
            'aiExplanation': cachedEvent['aiExplanation'],
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

      for (int i = 0;
          i < events.length && i < _maxCachedEvents;
          i++) {
        final event = events[i];

        if (event['aiPercentage'] != null &&
            event['aiExplanation'] != null) {
          aiDataToCache.add({
            'aiPercentage': event['aiPercentage'],
            'aiExplanation': event['aiExplanation'],
          });
        }
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_cacheKey, jsonEncode(aiDataToCache));
      await prefs.setString(
          _cacheTimestampKey,
          DateTime.now().toIso8601String());
    } catch (e) {
      print("Error saving AI data to cache: $e");
    }
  }
}
