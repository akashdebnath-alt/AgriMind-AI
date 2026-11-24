import 'package:material_ui/material_ui.dart';

import '../core/app_colors.dart';
import '../core/services/api_service.dart';
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
  final bool isDemoMode;

  const MainScreen({super.key, this.isDemoMode = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _loadError;

  final List<Farm> _farms = [];
  final List<Crop> _crops = [];
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic>? _weatherSnippet;

  double get _totalArea {
    final serverTotal = _dashboardData['total_area_acres'];
    if (serverTotal is num) return serverTotal.toDouble();
    return _farms.fold(
      0.0,
      (total, farm) =>
          total +
          (farm.areaAcres ??
              (farm.areaUnit == 'Hectares' ? farm.area * 2.47105 : farm.area)),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (widget.isDemoMode) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = null;
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    final errors = <String>[];
    List<Farm>? fetchedFarms;
    List<Crop>? fetchedCrops;
    Map<String, dynamic>? dashboard;
    Map<String, dynamic>? weather;

    try {
      fetchedFarms = await ApiService().getFarms();
    } catch (e) {
      errors.add('Farms: $e');
    }
    try {
      fetchedCrops = await ApiService().getCrops();
    } catch (e) {
      errors.add('Crops: $e');
    }
    try {
      dashboard = await ApiService().getDashboard();
    } catch (e) {
      errors.add('Dashboard: $e');
    }
    try {
      weather = await ApiService().getWeather();
    } catch (e) {
      errors.add('Weather: $e');
    }

    if (mounted) {
      setState(() {
        if (fetchedFarms != null) {
          _farms
            ..clear()
            ..addAll(fetchedFarms);
        }
        if (fetchedCrops != null) {
          _crops
            ..clear()
            ..addAll(fetchedCrops);
        }
        if (dashboard != null) _dashboardData = dashboard;
        if (fetchedFarms != null || weather != null) _weatherSnippet = weather;
        _loadError = errors.isEmpty ? null : errors.join('\n');
        _isLoading = false;
      });
    }
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
      MaterialPageRoute(builder: (_) => const AddFarmScreen()),
    );

    if (newFarm == null || !mounted) return;

    if (widget.isDemoMode) {
      setState(() {
        _farms.add(newFarm);
      });
      return;
    }

    try {
      final saved = await ApiService().createFarm(newFarm);
      if (!mounted) return;
      setState(() => _farms.add(saved));
      await _loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Farm added and saved to backend!'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save farm: $e')));
      }
    }
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
        builder: (_) => AddFarmScreen(existingFarm: _farms[index]),
      ),
    );

    if (updatedFarm == null || !mounted) return;

    try {
      final saved = widget.isDemoMode
          ? updatedFarm
          : await ApiService().updateFarm(updatedFarm);
      if (!mounted) return;
      setState(() => _farms[index] = saved);
      if (!widget.isDemoMode) await _loadAllData();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isDemoMode
                ? 'Farm updated in demo mode.'
                : 'Farm updated successfully!',
          ),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not update farm: $e')));
      }
    }
  }

  // DELETE FARM
  Future<void> _deleteFarm(int index) async {
    if (index < 0 || index >= _farms.length) return;

    final farm = _farms[index];

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete farm?'),
        content: Text(
          'Are you sure you want to delete "${farm.name}"?\nThis will also delete associated crops.',
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
            child: Text('Delete', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (!widget.isDemoMode && farm.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This farm cannot be deleted without an ID.'),
        ),
      );
      return;
    }
    if (!widget.isDemoMode) {
      try {
        await ApiService().deleteFarm(farm.id!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not delete farm: $e')));
        }
        return;
      }
    }

    final deletedFarmName = farm.name;

    setState(() {
      _farms.removeAt(index);
      _crops.removeWhere(
        (crop) => crop.farmName == deletedFarmName || crop.farmId == farm.id,
      );
    });

    _loadAllData();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm and its associated crops deleted.')),
      );
    }
  }

  // OPEN CROP MANAGEMENT
  void _openCrops() {
    final farmNames = _farms.map((farm) => farm.name).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CropsScreen(
          farmNames: farmNames,
          crops: _crops,
          onRefresh: _loadAllData,
          onAddCropRequest: (newCrop) async {
            if (widget.isDemoMode) return newCrop;
            final saved = await ApiService().createCrop(newCrop);
            return saved;
          },
          onEditCropRequest: (updatedCrop) async {
            if (widget.isDemoMode) return updatedCrop;
            final saved = await ApiService().updateCrop(updatedCrop);
            return saved;
          },
          onDeleteCropRequest: (crop) async {
            if (widget.isDemoMode) return true;
            if (crop.id == null) {
              throw ApiException('This crop cannot be deleted without an ID.');
            }
            await ApiService().deleteCrop(crop.id!);
            return true;
          },
          onCropsChanged: (updatedCrops) {
            setState(() {
              _crops
                ..clear()
                ..addAll(updatedCrops);
            });
          },
        ),
      ),
    );
  }

  // OPEN AI ADVISER
  void _showAIMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AIAdviserScreen(farms: _farms)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        farmCount: _farms.length,
        totalArea: _totalArea,
        cropCount: _dashboardData['crop_count'] ?? _crops.length,
        irrigationStatus: _dashboardData['irrigation_status'] ?? 'Pending',
        weatherSnippet: _weatherSnippet,
        onRefresh: _loadAllData,
        onAddFarm: _addFarm,
        onOpenFarms: () => _selectTab(1),
        onOpenWater: () => _selectTab(3),
        onOpenCrops: _openCrops,
        onOpenAI: _showAIMessage,
        onOpenWeather: () => _selectTab(2),
      ),

      FarmsScreen(
        farms: _farms,
        onAddFarm: _addFarm,
        onFarmTap: _openFarmDetails,
        onRefresh: _loadAllData,
      ),

      WeatherScreen(farms: _farms, onAddFarm: _addFarm),

      IrrigationScreen(farms: _farms, onAddFarm: _addFarm),

      const InsightsScreen(),

      ProfileScreen(onOpenFarms: () => _selectTab(1)),
    ];

    return Scaffold(
      body: Column(
        children: [
          if (_loadError != null)
            MaterialBanner(
              content: Text('Some data could not be loaded:\n$_loadError'),
              actions: [
                TextButton(onPressed: _loadAllData, child: const Text('Retry')),
              ],
            ),
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.green,
              backgroundColor: AppColors.lightGreen,
            ),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
        ],
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
