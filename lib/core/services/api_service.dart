import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../../features/farms/farm_model.dart';
import '../../features/crops/crop_model.dart';
import 'auth_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const Duration _timeout = Duration(seconds: 12);

  String get baseUrl =>
      AuthStorage.getBaseUrl().trim().replaceAll(RegExp(r'/+$'), '');

  Map<String, String> _buildHeaders({bool requiresAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    String errorMessage = 'An error occurred (${response.statusCode})';
    dynamic errorDetails;
    try {
      final body = jsonDecode(response.body);
      errorDetails = body;
      if (body is Map<String, dynamic>) {
        if (body.containsKey('detail')) {
          final detail = body['detail'];
          if (detail is String) {
            errorMessage = detail;
          } else if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            if (first is Map && first.containsKey('msg')) {
              errorMessage = first['msg'].toString();
            } else {
              errorMessage = detail.toString();
            }
          }
        } else if (body.containsKey('message')) {
          errorMessage = body['message'].toString();
        }
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        errorMessage = response.body;
      }
    }

    if (response.statusCode == 401) {
      AuthStorage.clearAuth();
      throw ApiException(
        errorMessage.isNotEmpty
            ? errorMessage
            : 'Session expired. Please sign in again.',
        statusCode: 401,
        details: errorDetails,
      );
    }

    throw ApiException(
      errorMessage,
      statusCode: response.statusCode,
      details: errorDetails,
    );
  }

  Future<dynamic> _safeCall(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        'Cannot connect to backend server at $baseUrl. Please verify the backend is running.',
        details: e.message,
      );
    } on TimeoutException {
      throw ApiException(
        'Request timed out. The server might be busy or unreachable.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Network error: ${e.message}. Check your connection.',
        details: e.uri?.toString(),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // HEALTH & CONNECTION CHECK
  // ---------------------------------------------------------------------------
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('${baseUrl.replaceAll('/api/v1', '')}/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.authLogin}');
    final res = await _safeCall(
      () => http.post(
        uri,
        headers: _buildHeaders(requiresAuth: false),
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ),
    );

    if (res is Map<String, dynamic>) {
      final token = res['access_token'] as String?;
      if (token != null) {
        await AuthStorage.saveToken(token);
      }
      if (res['user'] != null && res['user'] is Map<String, dynamic>) {
        final user = UserModel.fromJson(res['user']);
        await AuthStorage.saveUser(user);
      }
      return res;
    }
    throw ApiException('Invalid response received from login server');
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password, {
    String? fullName,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.authRegister}');
    final res = await _safeCall(
      () => http.post(
        uri,
        headers: _buildHeaders(requiresAuth: false),
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
          if (fullName != null && fullName.trim().isNotEmpty)
            'full_name': fullName.trim(),
        }),
      ),
    );

    if (res is Map<String, dynamic>) {
      final token = res['access_token'] as String?;
      if (token != null) {
        await AuthStorage.saveToken(token);
      }
      if (res['user'] != null && res['user'] is Map<String, dynamic>) {
        final user = UserModel.fromJson(res['user']);
        await AuthStorage.saveUser(user);
      }
      return res;
    }
    throw ApiException('Invalid response received from registration server');
  }

  Future<UserModel> getMe() async {
    final uri = Uri.parse('$baseUrl${ApiConstants.authMe}');
    final res = await _safeCall(() => http.get(uri, headers: _buildHeaders()));
    final user = UserModel.fromJson(res as Map<String, dynamic>);
    await AuthStorage.saveUser(user);
    return user;
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.authChangePassword}');
    await _safeCall(
      () => http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ),
    );
  }

  Future<String> forgotPassword(String email) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.authForgotPassword}');
    final res = await _safeCall(
      () => http.post(
        uri,
        headers: _buildHeaders(requiresAuth: false),
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      ),
    );
    if (res is Map && res.containsKey('message')) {
      return res['message'].toString();
    }
    return 'If an account exists, reset instructions have been sent.';
  }

  // ---------------------------------------------------------------------------
  // PROFILE
  // ---------------------------------------------------------------------------
  Future<UserModel> getProfile() async {
    final uri = Uri.parse('$baseUrl${ApiConstants.profile}');
    final res = await _safeCall(() => http.get(uri, headers: _buildHeaders()));
    final user = UserModel.fromJson(res as Map<String, dynamic>);
    await AuthStorage.saveUser(user);
    return user;
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? language,
    bool? notificationsEnabled,
    bool? weatherAlertsEnabled,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.profile}');
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (language != null) body['language'] = language;
    if (notificationsEnabled != null) {
      body['notifications_enabled'] = notificationsEnabled;
    }
    if (weatherAlertsEnabled != null) {
      body['weather_alerts_enabled'] = weatherAlertsEnabled;
    }

    final res = await _safeCall(
      () => http.patch(uri, headers: _buildHeaders(), body: jsonEncode(body)),
    );
    final user = UserModel.fromJson(res as Map<String, dynamic>);
    await AuthStorage.saveUser(user);
    return user;
  }

  // ---------------------------------------------------------------------------
  // FARMS
  // ---------------------------------------------------------------------------
  Future<List<Farm>> getFarms() async {
    final uri = Uri.parse('$baseUrl${ApiConstants.farms}');
    final res = await _safeCall(() => http.get(uri, headers: _buildHeaders()));
    if (res is List) {
      return res.map((item) {
        if (item is! Map<String, dynamic>) {
          throw ApiException('Invalid farm received from backend');
        }
        return Farm.fromJson(item);
      }).toList();
    }
    throw ApiException('Invalid response received from farms server');
  }

  Future<Farm> getFarm(int farmId) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.farms}/$farmId');
    final res = await _safeCall(() => http.get(uri, headers: _buildHeaders()));
    return Farm.fromJson(res as Map<String, dynamic>);
  }

  Future<Farm> createFarm(Farm farm) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.farms}');
    final res = await _safeCall(
      () => http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode(farm.toJson()),
      ),
    );
    return Farm.fromJson(res as Map<String, dynamic>);
  }

  Future<Farm> updateFarm(Farm farm) async {
    if (farm.id == null) {
      throw ApiException('Farm ID is required for update');
    }
    final uri = Uri.parse('$baseUrl${ApiConstants.farms}/${farm.id}');
    final res = await _safeCall(
      () => http.put(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode(farm.toJson()),
      ),
    );
    return Farm.fromJson(res as Map<String, dynamic>);
  }

  Future<void> deleteFarm(int farmId) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.farms}/$farmId');
    await _safeCall(() => http.delete(uri, headers: _buildHeaders()));
  }

  // ---------------------------------------------------------------------------
  // CROPS
  // ---------------------------------------------------------------------------
  Future<List<Crop>> getCrops({int? farmId}) async {
    var url = '$baseUrl${ApiConstants.crops}';
    if (farmId != null) {
      url += '?farm_id=$farmId';
    }
    final uri = Uri.parse(url);
    final res = await _safeCall(() => http.get(uri, headers: _buildHeaders()));
    if (res is List) {
      return res.map((item) {
        if (item is! Map<String, dynamic>) {
          throw ApiException('Invalid crop received from backend');
        }
        return Crop.fromJson(item);
      }).toList();
    }
    throw ApiException('Invalid response received from crops server');
  }

  Future<Crop> getCrop(int cropId) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.crops}/$cropId');
    final res = await _safeCall(() => http.get(uri, headers: _buildHeaders()));
    return Crop.fromJson(res as Map<String, dynamic>);
  }

  Future<Crop> createCrop(Crop crop) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.crops}');
    final res = await _safeCall(
      () => http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode(crop.toJson()),
      ),
    );
    return Crop.fromJson(res as Map<String, dynamic>);
  }

  Future<Crop> updateCrop(Crop crop) async {
    if (crop.id == null) {
      throw ApiException('Crop ID is required for update');
    }
    final uri = Uri.parse('$baseUrl${ApiConstants.crops}/${crop.id}');
    final res = await _safeCall(
      () => http.put(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode(crop.toJson()),
      ),
    );
    return Crop.fromJson(res as Map<String, dynamic>);
  }

  Future<void> deleteCrop(int cropId) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.crops}/$cropId');
    await _safeCall(() => http.delete(uri, headers: _buildHeaders()));
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> getDashboard() async {
    final uri = Uri.parse('$baseUrl${ApiConstants.dashboard}');
    final res = await _safeCall(() => http.get(uri, headers: _buildHeaders()));
    return res is Map<String, dynamic> ? res : {};
  }

  // ---------------------------------------------------------------------------
  // WEATHER
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>?> getWeather({int? farmId}) async {
    var url = '$baseUrl${ApiConstants.weather}';
    if (farmId != null) {
      url += '?farm_id=$farmId';
    }
    final uri = Uri.parse(url);
    try {
      final res = await _safeCall(
        () => http.get(uri, headers: _buildHeaders()),
      );
      return res is Map<String, dynamic> ? res : null;
    } on ApiException catch (e) {
      // 404 means no farms yet or farm not found; return null so UI displays friendly prompt
      if (e.statusCode == 404 || e.statusCode == 503) {
        return null;
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // IRRIGATION
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> getIrrigationOverview({int? farmId}) async {
    var url = '$baseUrl${ApiConstants.irrigationOverview}';
    if (farmId != null) {
      url += '?farm_id=$farmId';
    }
    final uri = Uri.parse(url);
    final res = await _safeCall(() => http.get(uri, headers: _buildHeaders()));
    return res is Map<String, dynamic> ? res : {};
  }

  Future<Map<String, dynamic>> logIrrigation({
    required int farmId,
    double? amountLiters,
    String method = 'Drip irrigation',
  }) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.irrigationLogs}');
    final res = await _safeCall(
      () => http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode({
          'farm_id': farmId,
          'amount_liters': ?amountLiters,
          'method': method,
        }),
      ),
    );
    return res is Map<String, dynamic> ? res : {};
  }

  Future<Map<String, dynamic>> scheduleIrrigation({
    required int farmId,
    required DateTime scheduledFor,
    double? amountLiters,
    String method = 'Drip irrigation',
  }) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.irrigationSchedule}');
    final res = await _safeCall(
      () => http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode({
          'farm_id': farmId,
          'scheduled_for': scheduledFor.toIso8601String(),
          'amount_liters': ?amountLiters,
          'method': method,
        }),
      ),
    );
    return res is Map<String, dynamic> ? res : {};
  }

  Future<List<Map<String, dynamic>>> getIrrigationLogs({int? farmId}) async {
    var url = '$baseUrl${ApiConstants.irrigationLogs}';
    if (farmId != null) {
      url += '?farm_id=$farmId';
    }
    final uri = Uri.parse(url);
    final res = await _safeCall(() => http.get(uri, headers: _buildHeaders()));
    if (res is List) {
      return res.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  Future<void> deleteIrrigationLog(int logId) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.irrigationLogs}/$logId');
    await _safeCall(() => http.delete(uri, headers: _buildHeaders()));
  }

  Future<Map<String, dynamic>> getIrrigationRecommendations({
    required int farmId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl${ApiConstants.irrigationRecommendations}?farm_id=$farmId',
    );
    final res = await _safeCall(() => http.get(uri, headers: _buildHeaders()));
    return res is Map<String, dynamic> ? res : {};
  }

  Future<Map<String, dynamic>> createIrrigationRecommendation({
    required int farmId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.irrigationRecommendations}');
    final res = await _safeCall(
      () => http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode({'farm_id': farmId}),
      ),
    );
    return res is Map<String, dynamic> ? res : {};
  }

  // ---------------------------------------------------------------------------
  // INSIGHTS
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> getInsights() async {
    final uri = Uri.parse('$baseUrl${ApiConstants.insights}');
    final res = await _safeCall(() => http.get(uri, headers: _buildHeaders()));
    return res is Map<String, dynamic> ? res : {};
  }

  // ---------------------------------------------------------------------------
  // AI ADVISER
  // ---------------------------------------------------------------------------
  Future<List<String>> getAdviserSuggestions() async {
    final uri = Uri.parse('$baseUrl${ApiConstants.adviserSuggestions}');
    try {
      final res = await _safeCall(
        () => http.get(uri, headers: _buildHeaders()),
      );
      if (res is Map &&
          res.containsKey('suggestions') &&
          res['suggestions'] is List) {
        return (res['suggestions'] as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [
      'Why are my leaves turning yellow?',
      'How often should I irrigate my crops?',
      'How can I protect crops from pests?',
      'What should I do during heavy rainfall?',
    ];
  }

  Future<Map<String, dynamic>> sendAdviserChat(
    String message, {
    int? farmId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.adviserChat}');
    final body = <String, dynamic>{'message': message, 'farm_id': ?farmId};
    final res = await _safeCall(
      () => http.post(uri, headers: _buildHeaders(), body: jsonEncode(body)),
    );
    return res is Map<String, dynamic> ? res : {};
  }
}
