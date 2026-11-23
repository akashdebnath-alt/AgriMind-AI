import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../core/services/api_service.dart';
import '../farms/farm_model.dart';

class IrrigationScreen extends StatefulWidget {
  final List<Farm>? farms;
  final VoidCallback? onAddFarm;

  const IrrigationScreen({super.key, this.farms, this.onAddFarm});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  bool _isAiLoading = false;
  Map<String, dynamic>? _aiAssessment;
  String? _aiReply;
  List<dynamic> _aiSources = [];
  List<Farm> _farms = [];
  int? _selectedFarmId;

  bool _irrigatedToday = false;
  String _statusText = 'Needs Monitoring';
  String _dailyEstimate = '450 L';
  String _weeklyEstimate = '3,150 L';
  String _nextIrrigationTitle = 'Tomorrow morning';
  String _nextIrrigationSubtitle = 'Suggested time: 6:00 AM - 8:00 AM';
  String _note =
      'Estimates use crop stage, area, weather and rainfall (ETc = Kc x ET0).';

  List<Map<String, dynamic>> _history = [
    {
      'date_label': 'Yesterday',
      'amount_liters': 450.0,
      'method': 'Drip irrigation',
    },
    {
      'date_label': '18 Nov 2026',
      'amount_liters': 600.0,
      'method': 'Drip irrigation',
    },
    {
      'date_label': '16 Nov 2026',
      'amount_liters': 500.0,
      'method': 'Manual irrigation',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadIrrigationData();
  }

  Future<void> _loadIrrigationData({bool isRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.farms != null && widget.farms!.isNotEmpty) {
        _farms = widget.farms!;
      } else {
        try {
          _farms = await ApiService().getFarms();
        } catch (_) {}
      }

      if (_farms.isNotEmpty && _selectedFarmId == null) {
        _selectedFarmId = _farms.first.id;
      }

      final overview = await ApiService().getIrrigationOverview(
        farmId: _selectedFarmId,
      );

      if (overview.isNotEmpty && mounted) {
        setState(() {
          _irrigatedToday = overview['irrigated_today'] == true;
          _statusText =
              overview['status'] ??
              (_irrigatedToday ? 'Completed Today ✓' : 'Needs Monitoring');

          final daily = overview['daily_estimate_liters'];
          if (daily != null) {
            _dailyEstimate = '${(daily as num).round()} L';
          }
          final weekly = overview['weekly_estimate_liters'];
          if (weekly != null) {
            _weeklyEstimate = '${(weekly as num).round()} L';
          }

          final nxt = overview['next_irrigation'] as Map<String, dynamic>?;
          if (nxt != null) {
            _nextIrrigationTitle =
                nxt['label'] ??
                (_irrigatedToday
                    ? 'Next irrigation not scheduled'
                    : 'Tomorrow morning');
            _nextIrrigationSubtitle = nxt['suggested_window'] != null
                ? 'Suggested time: ${nxt['suggested_window']}'
                : (_irrigatedToday
                      ? 'Create a new schedule when needed.'
                      : '6:00 AM - 8:00 AM');
          }

          if (overview['history'] is List &&
              (overview['history'] as List).isNotEmpty) {
            _history = (overview['history'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          }

          if (overview['note'] != null) {
            _note = overview['note'].toString();
          }
        });
      }
    } catch (_) {
      // Keep existing/sample data for graceful display
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markIrrigated() async {
    if (_selectedFarmId == null && _farms.isNotEmpty) {
      _selectedFarmId = _farms.first.id;
    }

    setState(() => _isActionLoading = true);

    if (_selectedFarmId != null) {
      try {
        final result = await ApiService().logIrrigation(
          farmId: _selectedFarmId!,
          method: 'Drip irrigation',
        );

        if (!mounted) return;

        setState(() {
          _irrigatedToday = true;
          _statusText = 'Completed Today ✓';
          _nextIrrigationTitle = 'Next irrigation not scheduled';
          _nextIrrigationSubtitle = 'Watering complete for today.';

          _history.insert(0, {
            'date_label': 'Today',
            'amount_liters': result['amount_liters'] ?? 450.0,
            'method': result['method'] ?? 'Drip irrigation',
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Irrigation marked as completed in backend!'),
            backgroundColor: AppColors.green,
          ),
        );
      } catch (e) {
        // Fallback demo behavior
        setState(() {
          _irrigatedToday = true;
          _statusText = 'Completed Today ✓';
          _history.insert(0, {
            'date_label': 'Today',
            'amount_liters': 450.0,
            'method': 'Drip irrigation',
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked as completed (Offline: $e)')),
        );
      } finally {
        if (mounted) {
          setState(() => _isActionLoading = false);
        }
      }
    } else {
      // No farm registered yet
      setState(() {
        _irrigatedToday = true;
        _statusText = 'Completed Today ✓';
        _history.insert(0, {
          'date_label': 'Today',
          'amount_liters': 450.0,
          'method': 'Drip irrigation',
        });
        _isActionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Irrigation marked as completed (Demo mode)!'),
        ),
      );
    }
  }

  Future<void> _scheduleIrrigation() async {
    if (_farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please register a farm before scheduling irrigation.'),
        ),
      );
      return;
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 30);
    final amountController = TextEditingController(text: '450');
    String selectedMethod = 'Drip irrigation';
    int farmId = _selectedFarmId ?? _farms.first.id!;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Schedule Irrigation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Farm:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: farmId,
                    items: _farms
                        .map(
                          (f) => DropdownMenuItem(
                            value: f.id,
                            child: Text(f.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => farmId = val);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Date & Time:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 60),
                              ),
                            );
                            if (d != null) {
                              setDialogState(() => selectedDate = d);
                            }
                          },
                          child: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime,
                            );
                            if (t != null) {
                              setDialogState(() => selectedTime = t);
                            }
                          },
                          child: Text(selectedTime.format(ctx)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Amount (Liters):',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 450',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Method:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMethod,
                    items: const [
                      DropdownMenuItem(
                        value: 'Drip irrigation',
                        child: Text('Drip irrigation'),
                      ),
                      DropdownMenuItem(
                        value: 'Sprinkler',
                        child: Text('Sprinkler'),
                      ),
                      DropdownMenuItem(
                        value: 'Flood irrigation',
                        child: Text('Flood irrigation'),
                      ),
                      DropdownMenuItem(
                        value: 'Manual irrigation',
                        child: Text('Manual irrigation'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedMethod = val);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final scheduledDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  final amount =
                      double.tryParse(amountController.text.trim()) ?? 450.0;
                  Navigator.pop(dialogCtx);

                  try {
                    await ApiService().scheduleIrrigation(
                      farmId: farmId,
                      scheduledFor: scheduledDateTime,
                      amountLiters: amount,
                      method: selectedMethod,
                    );
                    _loadIrrigationData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Irrigation scheduled successfully!'),
                          backgroundColor: AppColors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Scheduled locally: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Schedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _requestAiIrrigationAdvice() async {
    final farmId = _selectedFarmId;
    if (farmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please register and select a farm first.'),
        ),
      );
      return;
    }

    setState(() {
      _isAiLoading = true;
      _aiAssessment = null;
      _aiReply = null;
      _aiSources = [];
    });
    try {
      final response = await ApiService().sendAdviserChat(
        'Give me personalized irrigation advice for this farm.',
        farmId: farmId,
        includeIrrigationAssessment: true,
      );
      if (!mounted) return;
      final assessment = response['irrigation_assessment'];
      if (assessment is! Map<String, dynamic>) {
        throw ApiException(
          'The adviser did not return an irrigation assessment.',
        );
      }
      setState(() {
        _aiAssessment = assessment;
        _aiReply = response['reply']?.toString();
        _aiSources = response['sources'] is List
            ? response['sources'] as List
            : [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get AI irrigation advice: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadIrrigationData(isRefresh: true),
          color: AppColors.green,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Irrigation Management',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Monitor and manage your farm water usage.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.green,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Farm selector if multiple farms
                if (_farms.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedFarmId,
                        isExpanded: true,
                        items: _farms.map((f) {
                          return DropdownMenuItem<int>(
                            value: f.id,
                            child: Text(
                              '🌱 ${f.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && val != _selectedFarmId) {
                            setState(() {
                              _selectedFarmId = val;
                              _aiAssessment = null;
                              _aiReply = null;
                              _aiSources = [];
                            });
                            _loadIrrigationData();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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

                if (_aiAssessment != null) ...[
                  const SizedBox(height: 20),
                  _buildAiAssessment(),
                ],

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
          colors: [AppColors.darkGreen, AppColors.green],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: Colors.white, size: 28),
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
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: 8),

          Text(
            _statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  'Smart water management (FAO-56)',
                  style: TextStyle(color: Colors.white, fontSize: 13),
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
                _dailyEstimate,
                Icons.water_drop,
              ),
              const SizedBox(width: 12),
              _requirementItem(
                'Weekly Estimate',
                _weeklyEstimate,
                Icons.calendar_month,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Scientific baseline: ETc = Kc x ET0 minus rainfall',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _requirementItem(String title, String value, IconData icon) {
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
              Icon(Icons.schedule, color: AppColors.green),
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
                      _nextIrrigationTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGreen,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _nextIrrigationSubtitle,
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
          child: FilledButton.icon(
            onPressed: _isAiLoading ? null : _requestAiIrrigationAdvice,
            icon: _isAiLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.psychology_outlined),
            label: Text(
              _isAiLoading ? 'Assessing farm...' : 'Get AI Irrigation Advice',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: Colors.white,
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
          child: ElevatedButton.icon(
            onPressed: (_irrigatedToday || _isActionLoading)
                ? null
                : _markIrrigated,
            icon: _isActionLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _irrigatedToday ? 'Irrigation Completed' : 'Mark as Irrigated',
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

  Widget _buildAiAssessment() {
    final assessment = _aiAssessment ?? const <String, dynamic>{};
    final sensor =
        assessment['virtual_sensor'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final readings =
        sensor['readings'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final prediction =
        assessment['ml_prediction'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final decision =
        prediction['label']?.toString() ?? 'Prediction unavailable';
    final probability = prediction['probability'];
    final probabilityPercent = probability is num
        ? '${(probability * 100).round()}%'
        : '--';
    final confidence = prediction['confidence'];
    final confidencePercent = confidence is num
        ? '${(confidence * 100).round()}%'
        : '--';
    final existingPlan =
        assessment['existing_plan'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final disagreement = assessment['decision_disagreement'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sensors_outlined, color: AppColors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Virtual Sensor & AI Assessment',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sensor['notice']?.toString() ??
                'Simulated readings; no physical sensor is connected.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _sensorValue('Soil moisture', readings['soil_moisture_pct'], '%'),
              _sensorValue('Air temp', readings['air_temperature_c'], ' C'),
              _sensorValue('Soil temp', readings['soil_temperature_c'], ' C'),
              _sensorValue('Humidity', readings['humidity_pct'], '%'),
              _sensorValue('Rainfall', readings['rainfall_mm'], ' mm'),
              _sensorValue('ET0', readings['et0_mm'], ' mm/day'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'ML prediction: $decision. Irrigation probability: $probabilityPercent; '
            'model score: $confidencePercent (not real-world accuracy).',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          if (existingPlan['daily_liters'] is num) ...[
            const SizedBox(height: 8),
            Text(
              'Existing irrigation estimate: '
              '${(existingPlan['daily_liters'] as num).round()} L today.',
              style: const TextStyle(fontSize: 12, color: AppColors.darkGreen),
            ),
          ],
          if (disagreement) ...[
            const SizedBox(height: 8),
            const Text(
              'The model and irrigation estimate differ. Check root-zone moisture before deciding.',
              style: TextStyle(fontSize: 12, color: Colors.deepOrange),
            ),
          ],
          if (_aiReply != null) ...[
            const SizedBox(height: 12),
            Text(_aiReply!, style: const TextStyle(fontSize: 13, height: 1.45)),
          ],
          if (_aiSources.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Knowledge: ${_aiSources.map((source) => source is Map ? source['title'] : source).join(', ')}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sensorValue(String label, dynamic value, String unit) {
    final display = value is num ? '${value.toStringAsFixed(1)}$unit' : '--';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $display',
        style: const TextStyle(fontSize: 12, color: AppColors.darkGreen),
      ),
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

        if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Center(
              child: Text(
                'No irrigation logs yet. Mark as irrigated to record history.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          )
        else
          ..._history.map((item) {
            final date = item['date_label'] ?? item['date'] ?? 'Recent';
            final method = item['method'] ?? 'Drip irrigation';
            final amount = item['amount_liters'] != null
                ? '${(item['amount_liters'] as num).round()} L'
                : (item['amount'] ?? '-- L');

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
                    child: const Icon(Icons.water_drop, color: AppColors.green),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGreen,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          method,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    amount,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.green),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _note,
              style: const TextStyle(
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade200),
    );
  }
}
