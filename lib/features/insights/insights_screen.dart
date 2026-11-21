
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

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
                'Insights & Analytics',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Understand your farm performance.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
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

              // Weekly activity
              _buildWeeklyActivity(),

              const SizedBox(height: 24),

              // Recommendations
              _buildRecommendations(),

              const SizedBox(height: 20),
            ],
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
                value: '2',
                icon: Icons.landscape,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                title: 'Cultivated Area',
                value: '5.5 ac',
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
                value: '4',
                icon: Icons.eco,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                title: 'Water Used',
                value: '4,500 L',
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
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
            'Weekly irrigation water consumption',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            '4,500 L',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Illustrative weekly usage',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 20),

          _progressRow('Water used', 0.65, '65%'),
          const SizedBox(height: 15),
          _progressRow('Water remaining', 0.35, '35%'),
        ],
      ),
    );
  }

  Widget _progressRow(String title, double value, String label) {
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
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 9,
            backgroundColor: AppColors.lightGreen,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.green,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // CROP DISTRIBUTION
  // --------------------------------------------------

  Widget _buildCropDistribution() {
    final crops = [
      {'name': 'Rice', 'area': '2.5 acres', 'progress': 0.80},
      {'name': 'Tomato', 'area': '1.5 acres', 'progress': 0.55},
      {'name': 'Mustard', 'area': '1.0 acres', 'progress': 0.35},
      {'name': 'Potato', 'area': '0.5 acres', 'progress': 0.70},
    ];

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
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 20),

          ...crops.map((crop) {
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
                      value: crop['progress'] as double,
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
    final days = [
      {'day': 'Mon', 'value': 0.60},
      {'day': 'Tue', 'value': 0.90},
      {'day': 'Wed', 'value': 0.40},
      {'day': 'Thu', 'value': 0.75},
      {'day': 'Fri', 'value': 0.50},
      {'day': 'Sat', 'value': 1.00},
      {'day': 'Sun', 'value': 0.30},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Irrigation Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Illustrative irrigation activity',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((item) {
                final value = item['value'] as double;

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
    final recommendations = [
      {
        'icon': Icons.water_drop_outlined,
        'title': 'Monitor soil moisture',
        'description':
            'Check soil moisture before your next irrigation session.',
      },
    {
        'icon': Icons.cloud_outlined,
        'title': 'Check weather conditions',
        'description':
            'Review rainfall forecasts before planning irrigation.',
      },
    {
        'icon': Icons.eco_outlined,
        'title': 'Track crop growth',
        'description':
            'Keep crop planting dates and growth stages updated.',
      },
    ];

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

        ...recommendations.map((item) {
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

  // --------------------------------------------------
  // COMMON CARD STYLE
  // --------------------------------------------------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade200),
    );
  }
}
