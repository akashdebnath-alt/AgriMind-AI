
import 'package:flutter/material.dart';
import 'farm_model.dart';

class AddFarmScreen extends StatefulWidget {
  final Farm? existingFarm;

  const AddFarmScreen({
    super.key,
    this.existingFarm,
  });

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _areaController;

  late String _areaUnit;
  late String _soilType;

  final List<String> _soilTypes = [
    'Loamy',
    'Clay',
    'Sandy',
    'Silty',
    'Black soil',
    'Red soil',
    'Unknown',
  ];

  bool get isEditing => widget.existingFarm != null;

  @override
  void initState() {
    super.initState();

    final farm = widget.existingFarm;

    _nameController = TextEditingController(text: farm?.name ?? '');
    _locationController = TextEditingController(text: farm?.location ?? '');
    _areaController = TextEditingController(
      text: farm != null ? farm.area.toString() : '',
    );

    _areaUnit = farm?.areaUnit ?? 'Acres';
    _soilType = farm?.soilType ?? 'Loamy';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _saveFarm() {
    if (!_formKey.currentState!.validate()) return;

    final farm = Farm(
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      area: double.parse(_areaController.text.trim()),
      areaUnit: _areaUnit,
      soilType: _soilType,
    );

    Navigator.pop(context, farm);
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF246B45);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F2),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit farm' : 'Add your farm'),
        backgroundColor: const Color(0xFFF4F7F2),
        foregroundColor: const Color(0xFF17452D),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F1E7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.landscape_rounded, size: 38, color: green),
                  const SizedBox(height: 12),
                  Text(
                    isEditing ? 'Update your farm' : 'Tell us about your farm',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17452D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'These details help AgriMind AI provide better '
                    'crop and irrigation recommendations.',
                    style: TextStyle(height: 1.5, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildLabel('Farm name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(
                'e.g. Green Valley Farm',
                Icons.agriculture_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your farm name';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            _buildLabel('Farm location'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              decoration: _inputDecoration(
                'Village, district or address',
                Icons.location_on_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the farm location';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            _buildLabel('Farm area'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _areaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      'Enter area',
                      Icons.square_foot_rounded,
                    ),
                    validator: (value) {
                      final area = double.tryParse(value ?? '');
                      if (area == null || area <= 0) {
                        return 'Enter a valid area';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _areaUnit,
                    decoration: _inputDecoration('', null),
                    items: const [
                      DropdownMenuItem(value: 'Acres', child: Text('Acres')),
                      DropdownMenuItem(
                        value: 'Hectares',
                        child: Text('Hectares'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _areaUnit = value);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildLabel('Soil type'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _soilType,
              decoration: _inputDecoration('', Icons.terrain_rounded),
              items: _soilTypes.map((soil) {
                return DropdownMenuItem(
                  value: soil,
                  child: Text(soil),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _soilType = value);
                }
              },
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _saveFarm,
                icon: Icon(
                  isEditing ? Icons.save_rounded : Icons.check_circle_outline,
                ),
                label: Text(
                  isEditing ? 'Update farm' : 'Save farm',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Color(0xFF17452D),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E8E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF246B45),
          width: 1.5,
        ),
      ),
    );
  }
}
