import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../core/services/api_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;

  // Overview
  String _totalFarms = '--';
  String _cultivatedArea = '--';
  String _activeCrops = '--';
  String _waterUsed = '--';

  // Water usage
  String _waterUsageTitle = '--';
  double? _usedRatio;
  String _usedPctLabel = '--';
  double? _remainingRatio;
  String _remainingPctLabel = '--';

  // Crop distribution
  List<Map<String, dynamic>> _cropDistribution = [];

  // Last 7 days activity
  List<Map<String, dynamic>> _weeklyDays = [];

  // Recommendations
  List<Map<String, dynamic>> _recommendations = [
    {
      'icon': Icons.water_drop_outlined,
      'title': 'Monitor soil moisture',
      'description': 'Check soil moisture before your next irrigation session.',
    },
    {
      'icon': Icons.cloud_outlined,
      'title': 'Check weather conditions',
      'description': 'Review rainfall forecasts before planning irrigation.',
    },
    {
      'icon': Icons.eco_outlined,
      'title': 'Track crop growth',
      'description': 'Keep crop planting dates and growth stages updated.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _totalFarms = '--';
      _cultivatedArea = '--';
      _activeCrops = '--';
      _waterUsed = '--';
      _waterUsageTitle = '--';
      _usedRatio = null;
      _usedPctLabel = '--';
      _remainingRatio = null;
      _remainingPctLabel = '--';
    });

    try {
      final data = await ApiService().getInsights();
      if (data.isNotEmpty && mounted) {
        setState(() {
          // Overview
          final ov = data['overview'] as Map<String, dynamic>?;
          if (ov != null) {
            _totalFarms = '${ov['total_farms'] ?? 0}';
            _cultivatedArea = '${ov['cultivated_area_acres'] ?? 0.0} ac';
            _activeCrops = '${ov['active_crops'] ?? 0}';
            final usedL = ov['water_used_liters'] ?? 0;
            _waterUsed = '$usedL L';
          }

          // Water usage
          final wu = data['water_usage'] as Map<String, dynamic>?;
          if (wu != null) {
            final usedLiters = wu['used_liters'] ?? 0;
            _waterUsageTitle = '$usedLiters L';
            if (wu['used_ratio'] != null) {
              _usedRatio = (wu['used_ratio'] as num).toDouble().clamp(0.0, 1.0);
              _usedPctLabel = '${((_usedRatio ?? 0.0) * 100).round()}%';
            } else {
              _usedRatio = null;
              _usedPctLabel = '--';
            }
            if (wu['remaining_ratio'] != null) {
              _remainingRatio = (wu['remaining_ratio'] as num).toDouble().clamp(
                0.0,
                1.0,
              );
              _remainingPctLabel = '${((_remainingRatio ?? 0.0) * 100).round()}%';
            } else {
              _remainingRatio = null;
              _remainingPctLabel = '--';
            }
          }

          // Crop distribution
          if (data['crop_distribution'] is List &&
              (data['crop_distribution'] as List).isNotEmpty) {
            _cropDistribution = (data['crop_distribution'] as List).map((c) {
              final m = c as Map<String, dynamic>;
              final share = (m['share'] as num?)?.toDouble() ?? 0.5;
              return {
                'name': m['name'] ?? 'Crop',
                'area': '${m['area_acres'] ?? 0} acres',
                'progress': share.clamp(0.05, 1.0),
              };
            }).toList();
          }

          // Last 7 days activity
          if (data['weekly_activity'] is List &&
              (data['weekly_activity'] as List).isNotEmpty) {
            _weeklyDays = (data['weekly_activity'] as List).map((d) {
              final m = d as Map<String, dynamic>;
              final val = (m['value'] as num?)?.toDouble() ?? 0.0;
              return {'day': m['day'] ?? 'Day', 'value': val.clamp(0.0, 1.0)};
            }).toList();
          }

          // Recommendations
          if (data['recommendations'] is List &&
              (data['recommendations'] as List).isNotEmpty) {
            _recommendations = (data['recommendations'] as List).map((r) {
              final m = r as Map<String, dynamic>;
              IconData icon = Icons.info_outline;
              final iconStr = m['icon']?.toString() ?? '';
              if (iconStr == 'water') icon = Icons.water_drop_outlined;
              if (iconStr == 'weather') icon = Icons.cloud_outlined;
              if (iconStr == 'crop') icon = Icons.eco_outlined;
              if (iconStr == 'farm') icon = Icons.landscape_outlined;

              return {
                'icon': icon,
                'title': m['title'] ?? 'Recommendation',
                'description': m['description'] ?? '',
              };
            }).toList();
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _totalFarms = '--';
          _cultivatedArea = '--';
          _activeCrops = '--';
          _waterUsed = '--';
          _waterUsageTitle = '--';
          _usedRatio = null;
          _usedPctLabel = '--';
          _remainingRatio = null;
          _remainingPctLabel = '--';
          _cropDistribution = [];
          _weeklyDays = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInsights,
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
                            'Insights & Analytics',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Understand your farm performance.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.green,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Overview cards
                _buildOverview(),

                const SizedBox(height: 24),

                // Water usage
                _buildWaterUsage(),

                const SizedBox(height: 24),

                // Crop distribution
                _buildCropDistribution(),

                const SizedBox(height: 24),

                // Last 7 days activity
                _buildWeeklyActivity(),

                const SizedBox(height: 24),

                // Recommendations
                _buildRecommendations(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // FARM OVERVIEW
  // --------------------------------------------------

  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Farm Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGreen,
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Total Farms',
                value: _totalFarms,
                icon: Icons.landscape,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                title: 'Cultivated Area',
                value: _cultivatedArea,
                icon: Icons.grass,
                color: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Active Crops',
                value: _activeCrops,
                icon: Icons.eco,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                title: 'Water Used',
                value: _waterUsed,
                icon: Icons.water_drop,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // WATER USAGE
  // --------------------------------------------------

  Widget _buildWaterUsage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: AppColors.green),
              SizedBox(width: 10),
              Text(
                'Water Usage',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Water used in the last 7 days',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 20),

          Text(
            _waterUsageTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Completed logs in the last 7 days vs. weekly irrigation requirement',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 20),

          _progressRow('Water used in the last 7 days', _usedRatio, _usedPctLabel),
          const SizedBox(height: 15),
          _progressRow('Water remaining', _remainingRatio, _remainingPctLabel),
        ],
      ),
    );
  }

  Widget _progressRow(String title, double? value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (value == null)
          const Text(
            '--',
            style: TextStyle(color: Colors.grey),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 9,
              backgroundColor: AppColors.lightGreen,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------
  // CROP DISTRIBUTION
  // --------------------------------------------------

  Widget _buildCropDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crop Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Cultivated area by crop',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 20),

          if (_cropDistribution.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No crops registered yet.',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ..._cropDistribution.map((crop) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          crop['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        Text(
                          crop['area'] as String,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: (crop['progress'] as num).toDouble(),
                        minHeight: 8,
                        backgroundColor: AppColors.lightGreen,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // WEEKLY IRRIGATION ACTIVITY
  // --------------------------------------------------

  Widget _buildWeeklyActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 7 days irrigation activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Irrigation activity from completed logs in the last 7 days',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weeklyDays.map((item) {
                final value = (item['value'] as num).toDouble();

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 24,
                      height: 110 * value,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['day'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // FARMING RECOMMENDATIONS
  // --------------------------------------------------

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Farm Recommendations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGreen,
          ),
        ),

        const SizedBox(height: 14),

        ..._recommendations.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: AppColors.green,
                  size: 24,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        item['description'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade200),
    );
  }
}
