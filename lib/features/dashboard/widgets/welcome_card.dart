
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';

class WelcomeCard extends StatelessWidget {
  final VoidCallback onAddFarm;

  const WelcomeCard({
    super.key,
    required this.onAddFarm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E8658),
            AppColors.darkGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome, Farmer 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Grow smarter. Save water. Harvest better.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onAddFarm,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Register a Farm'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.darkGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
