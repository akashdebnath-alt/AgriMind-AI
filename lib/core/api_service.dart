import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  // Saved after a successful login (kept in memory for now).
  static String? token;
  static Map<String, dynamic>? user;

  // Where the backend is running.
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000'; // Android emulator -> your computer
    }
    return 'http://127.0.0.1:8000';
  }

  static Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final data = await _post('/auth/register', {
      'full_name': fullName,
      'email': email,
      'password': password,
    });
    _saveSession(data);
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    _saveSession(data);
  }

  static void _saveSession(Map<String, dynamic> data) {
    token = data['access_token'] as String;
    user = data['user'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException(
        'Cannot reach the server. Check that the backend is running.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Unexpected reply from the server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded as Map<String, dynamic>;
    }
    throw ApiException(_errorMessage(decoded));
  }

  static String _errorMessage(dynamic decoded) {
    if (decoded is Map && decoded['detail'] is String) {
      return decoded['detail'] as String;
    }
    return 'Please check your details. Use a valid email and a password '
        'of at least 8 characters.';
  }
}