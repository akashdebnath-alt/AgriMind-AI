
import 'package:flutter/material.dart';
import 'farm_model.dart';

class FarmDetailsScreen extends StatelessWidget {
  final Farm farm;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FarmDetailsScreen({
    super.key,
    required this.farm,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF246B45);
    const darkGreen = Color(0xFF17452D);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7F2),
        title: const Text('Farm details'),
        foregroundColor: darkGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit farm',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete farm',
            onPressed: onDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF246B45), Color(0xFF17452D)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Icon(
                Icons.agriculture_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 22),

          Text(
            farm.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  farm.location,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Farm information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),

          const SizedBox(height: 14),

          _DetailCard(
            icon: Icons.square_foot_rounded,
            title: 'Farm area',
            value: '${farm.area} ${farm.areaUnit}',
          ),

          _DetailCard(
            icon: Icons.terrain_rounded,
            title: 'Soil type',
            value: farm.soilType,
          ),

          _DetailCard(
            icon: Icons.location_on_rounded,
            title: 'Location',
            value: farm.location,
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit farm information'),
              style: FilledButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete farm'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1E7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF246B45)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
