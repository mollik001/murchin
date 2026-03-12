import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:murchin/const/service/endpoint.dart';
import 'package:murchin/features/sports/model/nba_finals_odds_model.dart';

class NbaFinalsOddsController extends GetxController {
  final isLoading = false.obs;
  final isRefreshing = false.obs;

  // Store odds by platform
  final Map<String, List<NbaFinalsOdd>> _platformOdds = {};
  final Map<String, String?> _nextPageUrls = {};

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
      print('Team: ${odd.teamName}, Price: ${odd.price}, Value: $value');
      if (value < lowestValue) {
        lowestValue = value;
        lowest = odd;
      }
    }

    print('Lowest team for $platform: ${lowest?.teamName} at $lowestValue');
    return lowest;
  }

  @override
  void onInit() {
    super.onInit();
    // Make this controller permanent to prevent disposal
    Get.config(enableLog: false);
    // Load all data for all platforms (fetch all pages)
    fetchAllPagesForPlatform('FanDuel');
    fetchAllPagesForPlatform('DraftKings');
    fetchAllPagesForPlatform('BetMGM');
  }

  /// Fetch all pages for a platform
  Future<void> fetchAllPagesForPlatform(String platform) async {
    String? nextPageUrl = Urls.nbaFinalsOddsUrl(platform);
    bool isFirstPage = true;
    
    while (nextPageUrl != null) {
      await fetchNbaFinalsOdds(platform, url: nextPageUrl, isLoadMore: !isFirstPage);
      isFirstPage = false;
      nextPageUrl = _nextPageUrls[platform];
    }
    
    print('=== All pages loaded for $platform ===');
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
        return const Color(0xFF607D3B);
      case 'draftkings':
        return const Color(0xFF6678F3);
      case 'betmgm':
        return const Color(0xFFE31837);
      default:
        return const Color(0xFFBDC4D2);
    }
  }

  @override
  void onClose() {
    // Don't dispose - keep controller persistent
    // This prevents data loss when navigating between screens
    super.onClose();
  }
}
