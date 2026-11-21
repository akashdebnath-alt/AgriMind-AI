class UserModel {
  final int id;
  final String email;
  final String? fullName;
  final String language;
  final bool notificationsEnabled;
  final bool weatherAlertsEnabled;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.language = 'English',
    this.notificationsEnabled = true,
    this.weatherAlertsEnabled = true,
  });

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : email.split('@').first;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'],
      language: json['language'] ?? 'English',
      notificationsEnabled: json['notifications_enabled'] ?? true,
      weatherAlertsEnabled: json['weather_alerts_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'language': language,
      'notifications_enabled': notificationsEnabled,
      'weather_alerts_enabled': weatherAlertsEnabled,
    };
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? fullName,
    String? language,
    bool? notificationsEnabled,
    bool? weatherAlertsEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      weatherAlertsEnabled: weatherAlertsEnabled ?? this.weatherAlertsEnabled,
    );
  }
}
