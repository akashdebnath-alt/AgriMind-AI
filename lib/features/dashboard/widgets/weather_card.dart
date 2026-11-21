import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';

class WeatherCard extends StatelessWidget {
  final String? temperature;
  final String? humidity;
  final String? wind;
  final String? condition;
  final String? location;
  final VoidCallback? onTap;

  const WeatherCard({
    super.key,
    this.temperature,
    this.humidity,
    this.wind,
    this.condition,
    this.location,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: Stack(
        children: [
          // Sky photo fills the whole card.
          Positioned.fill(
            child: Image.asset(
              'assets/images/card_weather.jpg',
              fit: BoxFit.cover,
              cacheWidth: 1400,
              filterQuality: FilterQuality.medium,
            ),
          ),
          // Dark-green tint so white text stays readable on the bright sky.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkGreen.withValues(alpha: 0.35),
                    AppColors.darkGreen.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.cloud_rounded,
                        color: AppColors.green,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location != null && location!.isNotEmpty
                                ? location!
                                : 'Farm Weather',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            condition ?? 'Weather updates available',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _WeatherValue(
                      icon: Icons.thermostat_rounded,
                      label: 'Temperature',
                      value: temperature ?? '-- °C',
                    ),
                    _WeatherValue(
                      icon: Icons.water_drop_rounded,
                      label: 'Humidity',
                      value: humidity ?? '-- %',
                    ),
                    _WeatherValue(
                      icon: Icons.air_rounded,
                      label: 'Wind',
                      value: wind ?? '--',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tap ripple on top of everything.
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}
class _WeatherValue extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 21),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
