import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Default base URL based on platform.
  /// Android emulator maps 10.0.2.2 to host machine's localhost:8000.
  /// Web, Windows, macOS, and Linux connect directly to 127.0.0.1:8000.
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://127.0.0.1:8000/api/v1';
    }
  }

  // Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  static const String authChangePassword = '/auth/change-password';
  static const String authForgotPassword = '/auth/forgot-password';

  static const String profile = '/profile';
  static const String farms = '/farms';
  static const String crops = '/crops';
  static const String dashboard = '/dashboard';
  static const String weather = '/weather';

  static const String irrigationOverview = '/irrigation/overview';
  static const String irrigationLogs = '/irrigation/logs';
  static const String irrigationSchedule = '/irrigation/schedule';
  static const String irrigationRecommendations = '/irrigation/recommendations';

  static const String insights = '/insights';
  static const String adviserSuggestions = '/adviser/suggestions';
  static const String adviserChat = '/adviser/chat';
  static const String health = '/health';
}
