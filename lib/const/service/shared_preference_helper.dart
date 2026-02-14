import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _accessTokenKey = 'token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userPhotoKey = 'user_photo';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

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

  static Future<bool> clearAllData() async {
    final prefs = await _instance;
    await prefs.clear();
    return true;
  }
}
