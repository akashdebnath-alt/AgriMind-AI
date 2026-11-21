
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  bool _irrigatedToday = false;

  final List<Map<String, String>> _history = [
    {
      'date': 'Yesterday',
      'amount': '450 L',
      'method': 'Drip irrigation',
    },
    {
      'date': '18 Nov 2026',
      'amount': '600 L',
      'method': 'Drip irrigation',
    },
    {
      'date': '16 Nov 2026',
      'amount': '500 L',
      'method': 'Manual irrigation',
    },
  ];

  void _markIrrigated() {
    setState(() {
      _irrigatedToday = true;

      _history.insert(0, {
        'date': 'Today',
        'amount': '450 L',
        'method': 'Drip irrigation',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Irrigation marked as completed!'),
      ),
    );
  }

  void _scheduleIrrigation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Irrigation scheduling will be available soon.'),
      ),
    );
  }

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
                'Irrigation Management',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Monitor and manage your farm water usage.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 24),

              // Water overview card
              _buildWaterOverview(),

              const SizedBox(height: 20),

              // Water requirement
              _buildWaterRequirement(),

              const SizedBox(height: 20),

              // Next irrigation
              _buildNextIrrigation(),

              const SizedBox(height: 20),

              // Action buttons
              _buildActionButtons(),

              const SizedBox(height: 28),

              // History
              _buildHistory(),

              const SizedBox(height: 20),

              // Information note
              _buildInfoNote(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Water overview
  Widget _buildWaterOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.darkGreen,
            AppColors.green,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.water_drop,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Water Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            _irrigatedToday ? 'Irrigation completed' : 'Water status',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _irrigatedToday ? 'Completed Today ✓' : 'Needs Monitoring',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Smart water management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Water requirement
  Widget _buildWaterRequirement() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Water Requirement',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              _requirementItem(
                'Daily Estimate',
                '450 L',
                Icons.water_drop,
              ),
              const SizedBox(width: 12),
              _requirementItem(
                'Weekly Estimate',
                '3,150 L',
                Icons.calendar_month,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Illustrative water estimates',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirementItem(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.green, size: 22),

            const SizedBox(height: 10),

            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 5),

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
      ),
    );
  }

  // Next irrigation
  Widget _buildNextIrrigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppColors.green,
              ),
              SizedBox(width: 10),
              Text(
                'Next Irrigation',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.calendar_today,
                color: AppColors.green,
                size: 22,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _irrigatedToday
                          ? 'Next irrigation not scheduled'
                          : 'Tomorrow morning',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGreen,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _irrigatedToday
                          ? 'Create a new schedule when needed.'
                          : 'Suggested time: 6:00 AM - 8:00 AM',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _irrigatedToday ? null : _markIrrigated,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              _irrigatedToday
                  ? 'Irrigation Completed'
                  : 'Mark as Irrigated',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.lightGreen,
              disabledForegroundColor: AppColors.darkGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _scheduleIrrigation,
            icon: const Icon(Icons.add_alarm),
            label: const Text('Schedule Irrigation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.green,
              side: const BorderSide(color: AppColors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Irrigation history
  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Irrigation History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGreen,
          ),
        ),

        const SizedBox(height: 14),

        ..._history.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: AppColors.green,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['date'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGreen,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        item['method'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  item['amount'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Information note
  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.green,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Water recommendations will later use crop stage, '
              'soil type, weather, rainfall and farm area to '
              'calculate irrigation requirements.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.darkGreen,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Common card style
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.grey.shade200,
      ),
    );
  }
}
