import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _accessTokenKey = 'token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userPhotoKey = 'user_photo';
  static const String _sportsbookModeKey = 'sportsbook_mode';
  static const String _lastVisitedSectionKey = 'last_visited_section';

  /// ⭐ NEW → Events Cache Key
  static const String _cachedEventsKey = 'cached_events_ai_v1';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// ===============================
  /// AUTH STORAGE
  /// ===============================

  static Future<bool> saveAccessToken(String token) async {
    final prefs = await _instance;
    return await prefs.setString(_accessTokenKey, token);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await _instance;
    return prefs.getString(_accessTokenKey);
  }

  static Future<bool> saveRefreshToken(String token) async {
    final prefs = await _instance;
    return await prefs.setString(_refreshTokenKey, token);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await _instance;
    return prefs.getString(_refreshTokenKey);
  }

  static Future<bool> saveUserId(String id) async {
    final prefs = await _instance;
    return await prefs.setString(_userIdKey, id);
  }

  static Future<String?> getUserId() async {
    final prefs = await _instance;
    return prefs.getString(_userIdKey);
  }

  static Future<bool> saveUserEmail(String email) async {
    final prefs = await _instance;
    return await prefs.setString(_userEmailKey, email);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await _instance;
    return prefs.getString(_userEmailKey);
  }

  static Future<bool> saveUserName(String name) async {
    final prefs = await _instance;
    return await prefs.setString(_userNameKey, name);
  }

  static Future<String?> getUserName() async {
    final prefs = await _instance;
    return prefs.getString(_userNameKey);
  }

  static Future<bool> saveUserPhoto(String photoUrl) async {
    final prefs = await _instance;
    return await prefs.setString(_userPhotoKey, photoUrl);
  }

  static Future<String?> getUserPhoto() async {
    final prefs = await _instance;
    return prefs.getString(_userPhotoKey);
  }

  static Future<bool> saveSportsbookMode(bool isSportsbook) async {
    final prefs = await _instance;
    return await prefs.setBool(_sportsbookModeKey, isSportsbook);
  }

  static Future<bool?> getSportsbookMode() async {
    final prefs = await _instance;
    return prefs.getBool(_sportsbookModeKey);
  }

  /// ===============================
  /// LAST VISITED SECTION STORAGE
  /// ===============================

  /// Save last visited section ('sports' or 'market')
  static Future<bool> saveLastVisitedSection(String section) async {
    final prefs = await _instance;
    return await prefs.setString(_lastVisitedSectionKey, section);
  }

  /// Get last visited section
  static Future<String?> getLastVisitedSection() async {
    final prefs = await _instance;
    return prefs.getString(_lastVisitedSectionKey);
  }

  /// Clear last visited section
  static Future<bool> clearLastVisitedSection() async {
    final prefs = await _instance;
    return await prefs.remove(_lastVisitedSectionKey);
  }

  /// ===============================
  /// ⭐ EVENTS CACHE STORAGE
  /// ===============================

  /// Save Events List (With Limit)
  static Future<bool> saveCachedEvents(
    List<Map<String, dynamic>> events, {
    int limit = 100,
  }) async {
    try {
      final prefs = await _instance;

      final limitedList =
          events.take(limit).map((e) => Map<String, dynamic>.from(e)).toList();

      final jsonString = jsonEncode(limitedList);

      return await prefs.setString(_cachedEventsKey, jsonString);
    } catch (e) {
      print("Save cache error: $e");
      return false;
    }
  }

  /// Get Cached Events
  static Future<List<Map<String, dynamic>>> getCachedEvents() async {
    try {
      final prefs = await _instance;

      final jsonString = prefs.getString(_cachedEventsKey);

      if (jsonString == null) return [];

      final List decoded = jsonDecode(jsonString);

      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print("Get cache error: $e");
      return [];
    }
  }

  /// Clear Only Events Cache
  static Future<bool> clearEventsCache() async {
    final prefs = await _instance;
    return await prefs.remove(_cachedEventsKey);
  }

  /// ===============================
  /// CLEAR ALL
  /// ===============================
  static Future<bool> clearAllData() async {
    final prefs = await _instance;
    await prefs.clear();
    return true;
  }
}
