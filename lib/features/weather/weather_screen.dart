
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Weather',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Weather conditions for your farming area',
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

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

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: const [
                  _WeatherInfoCard(
                    icon: Icons.water_drop_outlined,
                    title: 'Humidity',
                    value: '72%',
                  ),
                  _WeatherInfoCard(
                    icon: Icons.air,
                    title: 'Wind Speed',
                    value: '8 km/h',
                  ),
                  _WeatherInfoCard(
                    icon: Icons.cloud_outlined,
                    title: 'Cloud Cover',
                    value: '35%',
                  ),
                  _WeatherInfoCard(
                    icon: Icons.water,
                    title: 'Rainfall',
                    value: '2 mm',
                  ),
                ],
              ),

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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.agriculture,
                          color: AppColors.darkGreen,
                        ),
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
                    SizedBox(height: 10),
                    Text(
                      'Weather information can help you plan field activities, '
                      'monitor rainfall, and make better irrigation decisions. '
                      'Live weather-based recommendations will be available '
                      'after API integration.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Placeholder notice
              Center(
                child: Text(
                  'Sample weather data • Live updates coming later',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currentWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.darkGreen,
            AppColors.green,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Your Farm Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '28°C',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Partly Cloudy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.cloud,
                size: 85,
                color: Colors.white,
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Divider(color: Colors.white30),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeatherMiniInfo(
                icon: Icons.thermostat,
                label: 'Feels Like',
                value: '30°C',
              ),
              _WeatherMiniInfo(
                icon: Icons.arrow_upward,
                label: 'High',
                value: '32°C',
              ),
              _WeatherMiniInfo(
                icon: Icons.arrow_downward,
                label: 'Low',
                value: '24°C',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _forecastCard() {
    final forecast = [
      ['Today', '☀️', '32°', '24°'],
      ['Tomorrow', '🌦️', '30°', '23°'],
      ['Day 3', '☁️', '29°', '22°'],
      ['Day 4', '🌧️', '27°', '23°'],
      ['Day 5', '☀️', '31°', '24°'],
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: forecast.map((day) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    day[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(day[1], style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 24),
                Text(
                  day[2],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Text(
                  day[3],
                  style: TextStyle(color: Colors.grey.shade600),
                ),
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
