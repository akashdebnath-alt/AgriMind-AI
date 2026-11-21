
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'crop_model.dart';
import 'add_crop_screen.dart';

class CropsScreen extends StatefulWidget {
  final List<String> farmNames;
  final List<Crop> crops;
  final ValueChanged<List<Crop>> onCropsChanged;

  const CropsScreen({
    super.key,
    required this.farmNames,
    required this.crops,
    required this.onCropsChanged,
  });

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  List<Crop> get _crops => widget.crops;

  void _updateCrops(List<Crop> updatedCrops) {
    widget.onCropsChanged(updatedCrops);
  }

  Future<void> _addCrop() async {
    if (widget.farmNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please register a farm before adding a crop.',
          ),
        ),
      );
      return;
    }

    final crop = await Navigator.push<Crop>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCropScreen(
          farmNames: widget.farmNames,
        ),
      ),
    );

    if (crop != null && mounted) {
      _updateCrops([..._crops, crop]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crop added successfully!'),
        ),
      );
    }
  }

  Future<void> _editCrop(int index) async {
    final updated = await Navigator.push<Crop>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCropScreen(
          farmNames: widget.farmNames,
          existingCrop: _crops[index],
        ),
      ),
    );

    if (updated != null && mounted) {
      final updatedCrops = List<Crop>.from(_crops);
      updatedCrops[index] = updated;

      _updateCrops(updatedCrops);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crop updated successfully!'),
        ),
      );
    }
  }

  Future<void> _deleteCrop(int index) async {
    final crop = _crops[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Crop?'),
        content: Text(
          'Are you sure you want to delete ${crop.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final updatedCrops = List<Crop>.from(_crops);
      updatedCrops.removeAt(index);

      _updateCrops(updatedCrops);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crop deleted successfully.'),
        ),
      );
    }
  }

  void _viewCrop(Crop crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                crop.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Farm: ${crop.farmName}'),
              const SizedBox(height: 16),
              _detail('Variety', crop.variety),
              _detail('Area', '${crop.area} acres'),
              _detail(
                'Planting Date',
                _formatDate(crop.plantingDate),
              ),
              _detail('Growth Stage', crop.growthStage),
              _detail('Season', crop.season),
              _detail(
                'Days Since Planting',
                '${crop.daysSincePlanting} days',
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crop Management',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Manage your crops and growing seasons',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _addCrop,
                    icon: const Icon(Icons.add_circle),
                    color: AppColors.green,
                    iconSize: 34,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.grass,
                      color: Colors.white,
                      size: 35,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Registered Crops',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${_crops.length}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _crops.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        20, 0, 20, 20,
                      ),
                      itemCount: _crops.length,
                      itemBuilder: (context, index) {
                        final crop = _crops[index];
                        return _cropCard(crop, index);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCrop,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Crop'),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grass,
              size: 80,
              color: Colors.green.shade200,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Crops Registered',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first crop to start managing your cultivation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addCrop,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Crop'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cropCard(Crop crop, int index) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: AppColors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        crop.variety,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCrop(index);
                    } else if (value == 'delete') {
                      _deleteCrop(index);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: Colors.grey.shade200),

            Row(
              children: [
                Expanded(
                  child: _cardInfo(
                    Icons.landscape_outlined,
                    'Farm',
                    crop.farmName,
                  ),
                ),
                Expanded(
                  child: _cardInfo(
                    Icons.square_foot,
                    'Area',
                    '${crop.area} acres',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _cardInfo(
                    Icons.calendar_today,
                    'Planted',
                    _formatDate(crop.plantingDate),
                  ),
                ),
                Expanded(
                  child: _cardInfo(
                    Icons.trending_up,
                    'Stage',
                    crop.growthStage,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _viewCrop(crop),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardInfo(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: AppColors.green,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
