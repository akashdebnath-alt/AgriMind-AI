import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import 'crop_model.dart';

class AddCropScreen extends StatefulWidget {
  final List<String> farmNames;
  final Crop? existingCrop;

  const AddCropScreen({super.key, required this.farmNames, this.existingCrop});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _nameController = TextEditingController();
  final _varietyController = TextEditingController();
  final _areaController = TextEditingController();

  DateTime? _plantingDate;
  String? _selectedFarm;
  String _growthStage = 'Initial';
  String _season = 'Kharif';

  final List<String> _stages = [
    'Initial',
    'Development',
    'Mid-season',
    'Late-season',
    'Harvest',
  ];

  final List<String> _seasons = ['Kharif', 'Rabi', 'Zaid', 'Other'];

  bool get _isEditing => widget.existingCrop != null;

  @override
  void initState() {
    super.initState();

    final crop = widget.existingCrop;

    if (crop != null) {
      _nameController.text = crop.name;
      _varietyController.text = crop.variety;
      _areaController.text = crop.area.toString();
      _plantingDate = crop.plantingDate;
      _selectedFarm = widget.farmNames.contains(crop.farmName)
          ? crop.farmName
          : (widget.farmNames.isNotEmpty ? widget.farmNames.first : null);
      _growthStage = _stages.contains(crop.growthStage)
          ? crop.growthStage
          : 'Initial';
      _season = _seasons.contains(crop.season) ? crop.season : 'Kharif';
    } else {
      _selectedFarm = widget.farmNames.isNotEmpty
          ? widget.farmNames.first
          : null;
      _plantingDate = DateTime.now();
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _plantingDate = picked;
      });
    }
  }

  void _saveCrop() {
    final area = double.tryParse(_areaController.text.trim());

    if (_nameController.text.trim().isEmpty ||
        _areaController.text.trim().isEmpty ||
        area == null ||
        area <= 0 ||
        _selectedFarm == null ||
        _plantingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    final crop = Crop(
      id: widget.existingCrop?.id,
      farmId: widget.existingCrop?.farmId,
      name: _nameController.text.trim(),
      variety: _varietyController.text.trim().isEmpty
          ? 'Not specified'
          : _varietyController.text.trim(),
      farmName: _selectedFarm!,
      area: area,
      areaUnit: widget.existingCrop?.areaUnit ?? 'Acres',
      plantingDate: _plantingDate!,
      growthStage: _growthStage,
      season: _season,
    );

    Navigator.pop(context, crop);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _varietyController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEditing ? 'Edit Crop' : 'Add Crop')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                controller: _nameController,
                label: 'Crop Name',
                hint: 'e.g. Rice, Wheat, Tomato',
                icon: Icons.grass,
              ),

              const SizedBox(height: 16),

              _field(
                controller: _varietyController,
                label: 'Crop Variety',
                hint: 'e.g. Basmati, Swarna',
                icon: Icons.eco_outlined,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedFarm,
                decoration: _decoration(
                  'Select Farm',
                  Icons.landscape_outlined,
                ),
                items: widget.farmNames.map((farm) {
                  return DropdownMenuItem(value: farm, child: Text(farm));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedFarm = value);
                },
              ),

              const SizedBox(height: 16),

              _field(
                controller: _areaController,
                label: 'Cultivated Area',
                hint: 'Enter crop area in acres',
                icon: Icons.square_foot,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _decoration(
                    'Planting Date',
                    Icons.calendar_month,
                  ),
                  child: Text(
                    _plantingDate == null
                        ? 'Select planting date'
                        : '${_plantingDate!.day}/${_plantingDate!.month}/${_plantingDate!.year}',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _growthStage,
                decoration: _decoration('Growth Stage', Icons.trending_up),
                items: _stages.map((stage) {
                  return DropdownMenuItem(value: stage, child: Text(stage));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _growthStage = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _season,
                decoration: _decoration(
                  'Growing Season',
                  Icons.wb_sunny_outlined,
                ),
                items: _seasons.map((season) {
                  return DropdownMenuItem(value: season, child: Text(season));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _season = value);
                  }
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveCrop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Update Crop' : 'Save Crop',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _decoration(label, icon).copyWith(hintText: hint),
    );
  }
}
