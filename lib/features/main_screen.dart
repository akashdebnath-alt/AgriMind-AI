
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'dashboard/dashboard_screen.dart';
import 'farms/farm_model.dart';
import 'farms/farms_screen.dart';
import 'farms/add_farm_screen.dart';
import 'farms/farm_details_screen.dart';
import 'crops/crop_model.dart';
import 'crops/crops_screen.dart';
import 'weather/weather_screen.dart';
import 'irrigation/irrigation_screen.dart';
import 'ai_adviser/ai_adviser_screen.dart';
import 'insights/insights_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Temporary farm and crop data.
  // Later, these will be connected to the backend database.
  final List<Farm> _farms = [];
  final List<Crop> _crops = [];

  double get _totalArea {
    return _farms.fold(
      0.0,
      (total, farm) => total + farm.area,
    );
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ADD FARM
  Future<void> _addFarm() async {
    final Farm? newFarm = await Navigator.push<Farm>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddFarmScreen(),
      ),
    );

    if (newFarm == null || !mounted) return;

    setState(() {
      _farms.add(newFarm);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Farm added successfully!'),
      ),
    );
  }

  // OPEN FARM DETAILS
  void _openFarmDetails(int index) {
    if (index < 0 || index >= _farms.length) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FarmDetailsScreen(
          farm: _farms[index],
          onEdit: () => _editFarm(index),
          onDelete: () => _deleteFarm(index),
        ),
      ),
    );
  }

  // EDIT FARM
  Future<void> _editFarm(int index) async {
    if (index < 0 || index >= _farms.length) return;

    final Farm? updatedFarm = await Navigator.push<Farm>(
      context,
      MaterialPageRoute(
        builder: (_) => AddFarmScreen(
          existingFarm: _farms[index],
        ),
      ),
    );

    if (updatedFarm == null || !mounted) return;

    setState(() {
      _farms[index] = updatedFarm;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Farm updated successfully!'),
      ),
    );
  }

  // DELETE FARM
  Future<void> _deleteFarm(int index) async {
    if (index < 0 || index >= _farms.length) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete farm?'),
        content: Text(
          'Are you sure you want to delete "${_farms[index].name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final deletedFarmName = _farms[index].name;

    setState(() {
      _farms.removeAt(index);

      // Remove crops belonging to the deleted farm.
      _crops.removeWhere(
        (crop) => crop.farmName == deletedFarmName,
      );
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Farm and its associated crops deleted.'),
      ),
    );
  }

  // OPEN CROP MANAGEMENT
  void _openCrops() {
    final farmNames = _farms
        .map((farm) => farm.name)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CropsScreen(
          farmNames: farmNames,
          crops: _crops,
          onCropsChanged: (updatedCrops) {
            _crops
              ..clear()
              ..addAll(updatedCrops);
          },
        ),
      ),
    );
  }

  // OPEN AI ADVISER
  void _showAIMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AIAdviserScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        farmCount: _farms.length,
        totalArea: _totalArea,
        onAddFarm: _addFarm,
        onOpenFarms: () => _selectTab(1),
        onOpenWater: () => _selectTab(3),
        onOpenCrops: _openCrops,
        onOpenAI: _showAIMessage,
      ),

      FarmsScreen(
        farms: _farms,
        onAddFarm: _addFarm,
        onFarmTap: _openFarmDetails,
      ),

      const WeatherScreen(),

      const IrrigationScreen(),

      const InsightsScreen(),

      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        indicatorColor: AppColors.lightGreen,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.landscape_outlined),
            selectedIcon: Icon(Icons.landscape),
            label: 'Farms',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Weather',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Water',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
