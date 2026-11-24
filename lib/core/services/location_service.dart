import 'package:geolocator/geolocator.dart';

/// Result of trying to read the device location.
class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? error;

  const LocationResult.success(this.latitude, this.longitude) : error = null;
  const LocationResult.failure(this.error) : latitude = null, longitude = null;

  bool get ok => latitude != null && longitude != null;
}

/// Asks for location permission and returns the device's current position.
/// The last good fix is cached so the dashboard and the weather tab don't
/// each trigger a new GPS lookup or permission prompt.
class LocationService {
  static LocationResult? _cached;
  static DateTime? _cachedAt;
  static const Duration _cacheFor = Duration(minutes: 10);

  static Future<LocationResult> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    final cached = _cached;
    final at = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        cached.ok &&
        at != null &&
        DateTime.now().difference(at) < _cacheFor) {
      return cached;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult.failure(
          'Location services are turned off. Turn them on to see weather for your current location.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(
          'Location permission was denied. Allow it to see weather for your current location.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(
          'Location permission is blocked. Enable it in your device or browser settings.',
        );
      }

      // Weather only needs city-level accuracy, which is faster and uses less battery.
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final result = LocationResult.success(pos.latitude, pos.longitude);
      _cached = result;
      _cachedAt = DateTime.now();
      return result;
    } catch (e) {
      return LocationResult.failure('Could not get your location: $e');
    }
  }

  /// Opens the OS settings page for this app (useful after "denied forever").
  static Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}
