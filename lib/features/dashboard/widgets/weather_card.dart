
import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF4EC), Colors.white],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFDCE9DE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.cloud_rounded,
                  color: AppColors.green,
                  size: 34,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm Weather',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Weather updates coming soon',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFD9E5D9)),
          const SizedBox(height: 15),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherValue(
                icon: Icons.thermostat_rounded,
                label: 'Temperature',
                value: '-- °C',
              ),
              _WeatherValue(
                icon: Icons.water_drop_rounded,
                label: 'Humidity',
                value: '-- %',
              ),
              _WeatherValue(
                icon: Icons.air_rounded,
                label: 'Wind',
                value: '--',
              ),
            ],
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
        Icon(icon, color: AppColors.green, size: 21),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGreen,
          ),
        ),
      ],
    );
  }
}
