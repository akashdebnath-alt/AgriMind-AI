import 'package:material_ui/material_ui.dart';

import '../../../core/app_colors.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onAddFarm;
  final VoidCallback onWater;
  final VoidCallback onCrops;
  final VoidCallback onAI;

  const QuickActions({
    super.key,
    required this.onAddFarm,
    required this.onWater,
    required this.onCrops,
    required this.onAI,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionCard(
          icon: Icons.add_location_alt_rounded,
          title: 'Add Farm',
          subtitle: 'Register land',
          onTap: onAddFarm,
        ),
        _ActionCard(
          icon: Icons.water_drop_rounded,
          title: 'Irrigation',
          subtitle: 'Water planning',
          onTap: onWater,
        ),
        _ActionCard(
          icon: Icons.grass_rounded,
          title: 'My Crops',
          subtitle: 'Manage crops',
          onTap: onCrops,
        ),
        _ActionCard(
          icon: Icons.psychology_rounded,
          title: 'AI Adviser',
          subtitle: 'Ask questions',
          onTap: onAI,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EEE7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.green, size: 23),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
