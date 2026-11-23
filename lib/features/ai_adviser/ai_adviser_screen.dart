import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../core/services/api_service.dart';
import '../farms/farm_model.dart';

class AIAdviserScreen extends StatefulWidget {
  final List<Farm>? farms;

  const AIAdviserScreen({super.key, this.farms});

  @override
  State<AIAdviserScreen> createState() => _AIAdviserScreenState();
}

class _AIAdviserScreenState extends State<AIAdviserScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  List<String> _suggestions = [
    'Why are my leaves turning yellow?',
    'How often should I irrigate my crops?',
    'How can I protect crops from pests?',
    'What should I do during heavy rainfall?',
  ];

  List<Farm> _farms = [];
  int? _selectedFarmId;
  bool _isTyping = false;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _initAdviser();
  }

  Future<void> _initAdviser() async {
    try {
      final healthy = await ApiService().checkHealth();
      if (mounted) setState(() => _isOnline = healthy);

      final suggestions = await ApiService().getAdviserSuggestions();
      if (suggestions.isNotEmpty && mounted) {
        setState(() => _suggestions = suggestions);
      }

      if (widget.farms != null && widget.farms!.isNotEmpty) {
        _farms = widget.farms!;
      } else {
        try {
          _farms = await ApiService().getFarms();
        } catch (_) {}
      }

      if (_farms.isNotEmpty && mounted) {
        setState(() {
          _selectedFarmId = _farms.first.id;
        });
      }
    } catch (_) {}
  }

  Future<void> _sendMessage({
    String? suggestedMessage,
    bool includeIrrigationAssessment = false,
  }) async {
    final message = suggestedMessage ?? _controller.text.trim();
    if (message.isEmpty || _isTyping) return;
    if (includeIrrigationAssessment && _selectedFarmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add and select a farm for an assessment.'),
        ),
      );
      return;
    }

    setState(() {
      _messages.add({'text': message, 'isUser': true});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await ApiService().sendAdviserChat(
        message,
        farmId: _selectedFarmId,
        includeIrrigationAssessment: includeIrrigationAssessment,
      );

      final reply =
          response['reply'] as String? ??
          'I received your message. Please let me know how else I can help with your crops.';
      final sources = response['sources'] as List?;
      final grounded = response['grounded'] == true;

      if (!mounted) return;

      setState(() {
        _messages.add({
          'text': reply,
          'isUser': false,
          'grounded': grounded,
          'sources': sources,
          'assessment': response['irrigation_assessment'],
        });
        _isOnline = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'text':
              'Thanks for your question! 🌱\n\n'
              'Here is quick general guidance while connecting with the agronomy engine: '
              'For crop health, check soil moisture in the root zone, avoid overwatering, and ensure proper drainage.\n\n'
              '(Offline notice: $e)',
          'isUser': false,
          'grounded': false,
        });
        _isOnline = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            if (_farms.length > 1) _buildFarmFilter(),

            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcomeScreen()
                  : _buildChatMessages(),
            ),

            if (_isTyping)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                alignment: Alignment.centerLeft,
                child: const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.green,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'AI Adviser is thinking...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDE8))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.eco, color: AppColors.green, size: 26),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Agricultural Adviser',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      _isOnline
                          ? 'Verified Knowledge Base'
                          : 'Smart Agronomy Mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isOnline ? Colors.green.shade800 : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
              tooltip: 'New Conversation',
              onPressed: _clearChat,
            ),
        ],
      ),
    );
  }

  Widget _buildFarmFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(
            Icons.landscape_outlined,
            size: 16,
            color: AppColors.green,
          ),
          const SizedBox(width: 6),
          const Text(
            'Focus Farm: ',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          DropdownButton<int?>(
            value: _selectedFarmId,
            underline: const SizedBox(),
            isDense: true,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.darkGreen,
              fontWeight: FontWeight.bold,
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Farms (General)'),
              ),
              ..._farms.map(
                (f) => DropdownMenuItem<int?>(value: f.id, child: Text(f.name)),
              ),
            ],
            onChanged: (val) {
              setState(() => _selectedFarmId = val);
            },
          ),
        ],
      ),
    );
  }

  // Welcome screen
  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),

          Center(
            child: Container(
              height: 100,
              width: 100,
              decoration: const BoxDecoration(
                color: AppColors.lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppColors.green,
                size: 55,
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Center(
            child: Text(
              'Hello, Farmer! 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Center(
            child: Text(
              'Your agricultural assistant is here to help '
              'you make better farming decisions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selectedFarmId == null
                  ? null
                  : () => _sendMessage(
                      suggestedMessage: 'Give me personalized irrigation advice for this farm.',
                      includeIrrigationAssessment: true,
                    ),
              icon: const Icon(Icons.sensors_outlined),
              label: Text(
                _selectedFarmId == null
                    ? 'Add a farm for irrigation advice'
                    : 'Assess irrigation for selected farm',
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Explore topics',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),

          const SizedBox(height: 14),

          ..._suggestions.map((suggestion) {
            return _buildSuggestionCard(suggestion);
          }),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC7E2C7)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_outlined, color: AppColors.green),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Answers are grounded in agronomic knowledge for irrigation, '
                    'yellow leaves, pest protection, and rainfall preparation.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGreen,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Suggestion card
  Widget _buildSuggestionCard(String suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _sendMessage(suggestedMessage: suggestion),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.green,
                size: 20,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  suggestion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Chat messages
  Widget _buildChatMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message['isUser'] as bool;
        final sources = message['sources'] as List?;
        final assessment = message['assessment'] as Map<String, dynamic>?;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.84,
            ),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isUser ? AppColors.green : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: isUser ? null : Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message['text'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isUser ? Colors.white : AppColors.darkGreen,
                  ),
                ),
                if (!isUser && assessment != null) ...[
                  const SizedBox(height: 12),
                  _buildAssessmentDetails(assessment),
                ],
                if (!isUser && sources != null && sources.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: sources.map((s) {
                      final title = (s is Map)
                          ? s['title'] ?? ''
                          : s.toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '📖 $title',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.darkGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssessmentDetails(Map<String, dynamic> assessment) {
    final sensor =
        assessment['virtual_sensor'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final readings =
        sensor['readings'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final prediction =
        assessment['ml_prediction'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final probability = prediction['probability'];
    final confidence = prediction['confidence'];
    final probabilityText = probability is num
        ? '${(probability * 100).round()}%'
        : '--';
    final confidenceText = confidence is num
        ? '${(confidence * 100).round()}%'
        : '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Virtual sensor readings (simulated)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _assessmentReading(
                'Soil moisture',
                readings['soil_moisture_pct'],
                '%',
              ),
              _assessmentReading(
                'Air temp',
                readings['air_temperature_c'],
                ' C',
              ),
              _assessmentReading(
                'Soil temp',
                readings['soil_temperature_c'],
                ' C',
              ),
              _assessmentReading('Humidity', readings['humidity_pct'], '%'),
              _assessmentReading('Rainfall', readings['rainfall_mm'], ' mm'),
              _assessmentReading('ET0', readings['et0_mm'], ' mm/day'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ML: ${prediction['label'] ?? 'Unavailable'}; irrigation probability '
            '$probabilityText; model score $confidenceText (not accuracy).',
            style: const TextStyle(fontSize: 11, color: AppColors.darkGreen),
          ),
          if (assessment['decision_disagreement'] == true) ...[
            const SizedBox(height: 6),
            const Text(
              'The model and irrigation estimate differ. Check root-zone moisture.',
              style: TextStyle(fontSize: 11, color: Colors.deepOrange),
            ),
          ],
        ],
      ),
    );
  }

  Widget _assessmentReading(String label, dynamic value, String unit) {
    final reading = value is num ? '${value.toStringAsFixed(1)}$unit' : '--';
    return Text(
      '$label: $reading',
      style: const TextStyle(fontSize: 10, color: AppColors.darkGreen),
    );
  }

  // Input field
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EDE8))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask a farming question...',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Container(
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _sendMessage(),
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
