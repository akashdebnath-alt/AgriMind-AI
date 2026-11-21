
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'widgets/welcome_card.dart';
import 'widgets/farm_stats_card.dart';
import 'widgets/weather_card.dart';
import 'widgets/quick_actions.dart';

class DashboardScreen extends StatelessWidget {
  final int farmCount;
  final double totalArea;
  final VoidCallback onAddFarm;
  final VoidCallback onOpenFarms;
  final VoidCallback onOpenWater;
  final VoidCallback onOpenCrops;
  final VoidCallback onOpenAI;

  const DashboardScreen({
    super.key,
    required this.farmCount,
    required this.totalArea,
    required this.onAddFarm,
    required this.onOpenFarms,
    required this.onOpenWater,
    required this.onOpenCrops,
    required this.onOpenAI,
  });

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AgriMind AI',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Your smart farming companion',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: AppColors.green,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // WELCOME
                WelcomeCard(onAddFarm: onAddFarm),

                const SizedBox(height: 28),

                // FARM OVERVIEW
                const _SectionHeader(
                  title: 'Farm Overview',
                  subtitle: 'Your farming activity at a glance',
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FarmStatsCard(
                      icon: Icons.agriculture_rounded,
                      title: 'Total Farms',
                      value: farmCount.toString(),
                    ),
                    FarmStatsCard(
                      icon: Icons.landscape_rounded,
                      title: 'Total Land',
                      value: '${totalArea.toStringAsFixed(1)} acres',
                      iconBackground: const Color(0xFFEDF1DE),
                    ),
                    const FarmStatsCard(
                      icon: Icons.grass_rounded,
                      title: 'Crop Fields',
                      value: '0',
                      iconBackground: Color(0xFFF2EEDC),
                    ),
                    const FarmStatsCard(
                      icon: Icons.water_drop_rounded,
                      title: 'Irrigation',
                      value: 'Pending',
                      iconBackground: Color(0xFFE1F0F2),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // WEATHER
                const _SectionHeader(
                  title: 'Weather',
                  subtitle: 'Weather conditions for your farm',
                ),

                const SizedBox(height: 14),

                const WeatherCard(),

                const SizedBox(height: 28),

                // WATER MANAGEMENT
                const _SectionHeader(
                  title: 'Water Management',
                  subtitle: 'Plan your irrigation efficiently',
                ),

                const SizedBox(height: 14),

                InkWell(
                  onTap: onOpenWater,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFE4ECE4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.water_drop_rounded,
                          color: AppColors.green,
                          size: 34,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Irrigation Planner',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Manage your farm water requirements',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.green,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // QUICK ACTIONS
                const _SectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Your daily farming tools',
                ),

                const SizedBox(height: 14),

                QuickActions(
                  onAddFarm: onAddFarm,
                  onWater: onOpenWater,
                  onCrops: onOpenCrops,
                  onAI: onOpenAI,
                ),

                const SizedBox(height: 28),

                // MY FARMS
                _SectionHeader(
                  title: 'My Farms',
                  subtitle: 'Your registered agricultural lands',
                  actionText: 'View All',
                  onAction: onOpenFarms,
                ),

                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.agriculture_rounded,
                        size: 44,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        farmCount == 0
                            ? 'No farms registered yet'
                            : '$farmCount farm(s) registered',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        farmCount == 0
                            ? 'Add your farm to get started.'
                            : 'View and manage your registered farms.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: farmCount == 0 ? onAddFarm : onOpenFarms,
                        icon: Icon(
                          farmCount == 0
                              ? Icons.add
                              : Icons.agriculture_rounded,
                        ),
                        label: Text(
                          farmCount == 0 ? 'Register Farm' : 'View My Farms',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Center(
                  child: Text(
                    'AgriMind AI • Smart Agriculture',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// SECTION HEADER

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionText!),
          ),
      ],
    );
  }
}
