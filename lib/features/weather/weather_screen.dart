import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/location_service.dart';
import '../farms/farm_model.dart';

class WeatherScreen extends StatefulWidget {
  final List<Farm>? farms;
  final VoidCallback? onAddFarm;

  const WeatherScreen({super.key, this.farms, this.onAddFarm});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _weatherData;
  List<Farm> _farms = [];
  int? _selectedFarmId;
  bool _useCurrentLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Load farms if not supplied
      if (widget.farms != null && widget.farms!.isNotEmpty) {
        _farms = widget.farms!;
      } else {
        try {
          _farms = await ApiService().getFarms();
        } catch (_) {}
      }

      if (_farms.isNotEmpty && _selectedFarmId == null) {
        _selectedFarmId = _farms.first.id;
      }

      Map<String, dynamic>? data;
      String? locationError;
      if (_useCurrentLocation) {
        final loc = await LocationService.getCurrentLocation(
          forceRefresh: forceRefresh,
        );
        if (loc.ok) {
          data = await ApiService().getWeather(
            lat: loc.latitude,
            lon: loc.longitude,
          );
        } else {
          locationError = loc.error;
        }
      }
      // Fall back to the selected farm if location is off, denied or failed.
      data ??= await ApiService().getWeather(farmId: _selectedFarmId);
      if (mounted) {
        setState(() {
          _weatherData = data;
          _locationError = locationError;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _conditionEmoji(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('thunder')) return '⛈️';
    if (c.contains('rain') || c.contains('shower')) return '🌧️';
    if (c.contains('drizzle')) return '🌦️';
    if (c.contains('snow')) return '🌨️';
    if (c.contains('fog')) return '🌫️';
    if (c.contains('partly')) return '⛅';
    if (c.contains('overcast') || c.contains('cloud')) return '☁️';
    if (c.contains('clear') || c.contains('sun')) return '☀️';
    return '🌤️';
  }

  String _formatForecastDay(dynamic dateStr, int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    if (dateStr is String) {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return '${days[parsed.weekday - 1]} (${parsed.day}/${parsed.month})';
      }
    }
    return 'Day ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadWeather(forceRefresh: true),
          color: AppColors.green,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weather',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Weather conditions for your farming area',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.green,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Current-location toggle (shows a hint if permission is missing)
                _locationBar(),
                const SizedBox(height: 16),

                // Farm selector dropdown if multiple farms exist
                if (_farms.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedFarmId,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.green,
                        ),
                        items: _farms.map((f) {
                          return DropdownMenuItem<int>(
                            value: f.id,
                            child: Text(
                              '📍 ${f.name} (${f.location})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && val != _selectedFarmId) {
                            setState(() {
                              _selectedFarmId = val;
                              _useCurrentLocation = false;
                            });
                            _loadWeather();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_farms.isEmpty && _weatherData == null && !_isLoading) ...[
                  _noFarmsCard(),
                ] else ...[
                  // Current weather card
                  _currentWeatherCard(),

                  const SizedBox(height: 24),

                  // Weather details
                  const Text(
                    'Weather Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _weatherDetailsGrid(),

                  const SizedBox(height: 26),

                  // Forecast
                  const Text(
                    '5-Day Forecast',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _forecastCard(),

                  const SizedBox(height: 24),

                  // Farming note
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.agriculture, color: AppColors.darkGreen),
                            SizedBox(width: 8),
                            Text(
                              'Weather for Farming',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _weatherData != null
                              ? 'Live forecast powered by Open-Meteo for ${_weatherData!['farm_name'] ?? 'your current location'}. '
                                    'Rainfall and reference evapotranspiration (ET0) are directly integrated into irrigation planning.'
                              : 'Weather information helps plan field activities, monitor rainfall, and calculate smart irrigation needs.',
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      _weatherData != null
                          ? 'Source: Open-Meteo • Live data for ${_weatherData!['location'] ?? ''}'
                          : 'Sample weather data • Connect backend for live weather',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationBar() {
    final hasError = _useCurrentLocation && _locationError != null;
    final accent = hasError ? Colors.orange.shade800 : AppColors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: hasError ? Colors.orange.shade50 : AppColors.lightGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasError
                    ? Icons.location_off_rounded
                    : Icons.my_location_rounded,
                color: accent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  !_useCurrentLocation
                      ? 'Showing weather for your farm'
                      : hasError
                      ? 'Current location unavailable'
                      : 'Using your current location',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
              Switch(
                value: _useCurrentLocation,
                onChanged: (val) {
                  setState(() => _useCurrentLocation = val);
                  _loadWeather(forceRefresh: val);
                },
              ),
            ],
          ),
          if (hasError) ...[
            Text(
              _locationError!,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: LocationService.openSettings,
                  child: const Text('Open settings'),
                ),
                TextButton(
                  onPressed: () => _loadWeather(forceRefresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _noFarmsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_queue_rounded,
            size: 64,
            color: AppColors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Farm Registered Yet',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Register a farm with your location to get accurate live weather and rainfall forecasts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          if (widget.onAddFarm != null)
            ElevatedButton.icon(
              onPressed: widget.onAddFarm,
              icon: const Icon(Icons.add),
              label: const Text('Add Your Farm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _currentWeatherCard() {
    final cur = _weatherData?['current'] as Map<String, dynamic>?;
    final today = _weatherData?['today'] as Map<String, dynamic>?;

    final location =
        _weatherData?['location'] ??
        (_farms.isNotEmpty ? _farms.first.location : 'Your Farm Location');
    final isCurrentLocation = _weatherData?['is_current_location'] == true;
    final farmName = isCurrentLocation
        ? null
        : (_weatherData?['farm_name'] ??
              (_farms.isNotEmpty ? _farms.first.name : null));

    final temp = cur != null ? '${cur['temperature_c']?.round()}°C' : '28°C';
    final condition = cur != null
        ? (cur['condition'] ?? 'Partly Cloudy')
        : 'Partly Cloudy';
    final feelsLike = cur != null
        ? '${cur['feels_like_c']?.round()}°C'
        : '30°C';
    final high = today != null ? '${today['high_c']?.round()}°C' : '32°C';
    final low = today != null ? '${today['low_c']?.round()}°C' : '24°C';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkGreen, AppColors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  farmName != null ? '$farmName • $location' : location,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temp,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    condition,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              Text(
                _conditionEmoji(condition),
                style: const TextStyle(fontSize: 68),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Divider(color: Colors.white30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeatherMiniInfo(
                icon: Icons.thermostat,
                label: 'Feels Like',
                value: feelsLike,
              ),
              _WeatherMiniInfo(
                icon: Icons.arrow_upward,
                label: 'High',
                value: high,
              ),
              _WeatherMiniInfo(
                icon: Icons.arrow_downward,
                label: 'Low',
                value: low,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherDetailsGrid() {
    final cur = _weatherData?['current'] as Map<String, dynamic>?;

    final humidity = cur != null ? '${cur['humidity_pct']}%' : '72%';
    final wind = cur != null ? '${cur['wind_kmh']} km/h' : '8 km/h';
    final clouds = cur != null ? '${cur['cloud_cover_pct']}%' : '35%';
    final rain = cur != null ? '${cur['rainfall_mm']} mm' : '2 mm';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _WeatherInfoCard(
          icon: Icons.water_drop_outlined,
          title: 'Humidity',
          value: humidity,
        ),
        _WeatherInfoCard(icon: Icons.air, title: 'Wind Speed', value: wind),
        _WeatherInfoCard(
          icon: Icons.cloud_outlined,
          title: 'Cloud Cover',
          value: clouds,
        ),
        _WeatherInfoCard(icon: Icons.water, title: 'Rainfall', value: rain),
      ],
    );
  }

  Widget _forecastCard() {
    final rawForecast = _weatherData?['forecast'] as List?;
    final List<List<String>> forecastList = [];

    if (rawForecast != null && rawForecast.isNotEmpty) {
      for (int i = 0; i < rawForecast.length; i++) {
        final item = rawForecast[i] as Map<String, dynamic>;
        final day = _formatForecastDay(item['date'], i);
        final cond = item['condition']?.toString() ?? 'Clear';
        final emoji = _conditionEmoji(cond);
        final high = '${item['t_max']?.round()}°';
        final low = '${item['t_min']?.round()}°';
        forecastList.add([day, emoji, high, low]);
      }
    } else {
      forecastList.addAll([
        ['Today', '☀️', '32°', '24°'],
        ['Tomorrow', '🌦️', '30°', '23°'],
        ['Day 3', '☁️', '29°', '22°'],
        ['Day 4', '🌧️', '27°', '23°'],
        ['Day 5', '☀️', '31°', '24°'],
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: forecastList.map((day) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    day[0],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(day[1], style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 24),
                Text(
                  day[2],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Text(day[3], style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WeatherInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _WeatherInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.green, size: 26),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherMiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherMiniInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
