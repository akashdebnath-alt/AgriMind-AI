import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import 'farm_model.dart';

class FarmsScreen extends StatelessWidget {
  final List<Farm> farms;
  final VoidCallback onAddFarm;
  final ValueChanged<int> onFarmTap;
  final Future<void> Function()? onRefresh;

  const FarmsScreen({
    super.key,
    required this.farms,
    required this.onAddFarm,
    required this.onFarmTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Widget listContent = farms.isEmpty
        ? _EmptyFarms(onAddFarm: onAddFarm)
        : ListView.builder(
            itemCount: farms.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) {
              final farm = farms[index];

              return _FarmCard(farm: farm, onTap: () => onFarmTap(index));
            },
          );

    if (onRefresh != null) {
      listContent = RefreshIndicator(
        onRefresh: onRefresh!,
        color: AppColors.green,
        child: listContent,
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Farms',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Manage your agricultural lands',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    onPressed: onAddFarm,
                    icon: const Icon(Icons.add_rounded, color: AppColors.green),
                    tooltip: 'Add farm',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.green, AppColors.darkGreen],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.agriculture_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registered Farms',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          farms.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.eco_rounded,
                    color: Colors.white24,
                    size: 55,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your farmland',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ),
                Text(
                  '${farms.length} total',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Expanded(child: listContent),
          ],
        ),
      ),
    );
  }
}

class _EmptyFarms extends StatelessWidget {
  final VoidCallback onAddFarm;

  const _EmptyFarms({required this.onAddFarm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5ECE5)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No farms added yet',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your farmland to start managing crops, '
                'weather and irrigation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: onAddFarm,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Your First Farm'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  final Farm farm;
  final VoidCallback onTap;

  const _FarmCard({required this.farm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE5ECE5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: AppColors.green,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      farm.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.green,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      farm.location,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FarmTag(
                    icon: Icons.landscape_outlined,
                    text: '${farm.area} ${farm.areaUnit}',
                  ),
                  _FarmTag(icon: Icons.terrain_rounded, text: farm.soilType),
                  if (farm.cropCount > 0)
                    _FarmTag(
                      icon: Icons.eco_rounded,
                      text: '${farm.cropCount} crops',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FarmTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.green),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
