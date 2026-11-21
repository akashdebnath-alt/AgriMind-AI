
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class AIAdviserScreen extends StatefulWidget {
  const AIAdviserScreen({super.key});

  @override
  State<AIAdviserScreen> createState() => _AIAdviserScreenState();
}

class _AIAdviserScreenState extends State<AIAdviserScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];

  final List<String> _suggestions = [
    'Why are my leaves turning yellow?',
    'How often should I irrigate my crops?',
    'How can I protect crops from pests?',
    'What should I do during heavy rainfall?',
  ];

  void _sendMessage([String? suggestedMessage]) {
    final message = suggestedMessage ?? _controller.text.trim();

    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
      });

      _messages.add({
        'text': 'Thanks for your question! 🌱\n\n'
            'The AgriMind AI Adviser is currently being prepared. '
            'Once the AI backend is connected, I will be able to '
            'provide farming guidance based on your crops, soil, '
            'weather and farm conditions.\n\n'
            'For now, this is a demo chat interface.',
        'isUser': false,
      });
    });

    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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

            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcomeScreen()
                  : _buildChatMessages(),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8EDE8),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.eco,
              color: AppColors.green,
              size: 26,
            ),
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
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 6),

                    const Text(
                      'Demo mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              decoration: BoxDecoration(
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
          )),

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
              color: const Color(0xFFFFF4DF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'AI responses will be available after '
                    'connecting the backend.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.5,
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
        onTap: () => _sendMessage(suggestion),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
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

              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
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

        return Align(
          alignment: isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.green
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: isUser
                  ? null
                  : Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              message['text'] as String,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isUser
                    ? Colors.white
                    : AppColors.darkGreen,
              ),
            ),
          ),
        );
      },
    );
  }

  // Input field
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE8EDE8),
          ),
        ),
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
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
