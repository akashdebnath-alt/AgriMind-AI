import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';

class AuthStorage {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyBaseUrl = 'api_base_url';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String? getToken() {
    return _prefs?.getString(_keyToken);
  }

  static Future<void> saveToken(String token) async {
    await init();
    await _prefs?.setString(_keyToken, token);
  }

  static UserModel? getUser() {
    final raw = _prefs?.getString(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUser(UserModel user) async {
    await init();
    await _prefs?.setString(_keyUser, jsonEncode(user.toJson()));
  }

  static String getBaseUrl() {
    final custom = _prefs?.getString(_keyBaseUrl);
    if (custom != null && custom.trim().isNotEmpty) {
      return normalizeBaseUrl(custom);
    }
    return ApiConstants.defaultBaseUrl;
  }

  static Future<void> saveBaseUrl(String url) async {
    await init();
    await _prefs?.setString(_keyBaseUrl, normalizeBaseUrl(url));
  }

  static String normalizeBaseUrl(String url) {
    var normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized.isEmpty) return ApiConstants.defaultBaseUrl;
    if (!normalized.endsWith('/api/v1')) {
      normalized = '$normalized/api/v1';
    }
    return normalized;
  }

  static Future<void> clearAuth() async {
    await init();
    await _prefs?.remove(_keyToken);
    await _prefs?.remove(_keyUser);
  }

  static bool get isAuthenticated {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }
}
