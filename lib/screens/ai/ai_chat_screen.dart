import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

import '../../providers/farm_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/iot_provider.dart';
import '../../services/weather_service.dart';
import '../../config/api_keys.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  WeatherData? _weather;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _messages.add(
      _ChatMessage(
        text:
            'Hello! I\'m your Smart Agriculture AI Agent. 🌱🤖\n\n'
            'I have access to your **live IoT sensors**, **crop data**, and **weather** to give you personalized advice.\n\n'
            '${ApiKeys.hasGeminiKey ? "✅ Gemini AI connected — I'll give you intelligent analysis!" : "💡 Add a Gemini API key in Settings for AI-powered responses."}\n\n'
            'Try asking me:\n'
            '• "Analyze my farm"\n'
            '• "Should I irrigate today?"\n'
            '• "Check my sensors"',
        isUser: false,
      ),
    );
  }

  Future<void> _fetchWeather() async {
    _weather = await WeatherService().fetchWeather();
  }

  Future<void> _sendMessage([String? override]) async {
    final query = override ?? _msgCtrl.text.trim();
    if (query.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: query, isUser: true));
      _msgCtrl.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    final farm = Provider.of<FarmProvider>(context, listen: false);
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final iot = Provider.of<IoTProvider>(context, listen: false);

    final response = await iot.getAiResponse(
      query,
      crops: farm.crops,
      tasks: farm.tasks,
      expenses: finance.expenses,
      sales: finance.sales,
      weather: _weather,
    );

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _analyzeFarm() async {
    setState(() {
      _messages.add(_ChatMessage(text: '📊 Analyze my farm', isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final farm = Provider.of<FarmProvider>(context, listen: false);
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final iot = Provider.of<IoTProvider>(context, listen: false);

    final analysis = await iot.getAiResponse(
      'Give me a comprehensive farm health analysis. Check all sensor readings, weather conditions, crop statuses, pending tasks, and recent finances. Identify any issues and provide specific recommendations.',
      crops: farm.crops,
      tasks: farm.tasks,
      expenses: finance.expenses,
      sales: finance.sales,
      weather: _weather,
    );

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: analysis, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final iot = Provider.of<IoTProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2E7D32),
              child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('Farm Assistant'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  lang.t('Smart Agriculture'),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // IoT context indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text(
                  '${iot.onlineCount} live',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // AI status bar
          _buildAiStatusBar(iot),

          // Quick suggestion chips (show on first visit)
          if (_messages.length <= 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _suggestionChip('🔍 Analyze my farm'),
                  _suggestionChip('💧 Should I irrigate today?'),
                  _suggestionChip('🌡️ Check sensor readings'),
                  _suggestionChip('🐛 How to prevent pests?'),
                  _suggestionChip('📈 Market price tips'),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length && _isLoading) {
                  return _buildTypingIndicator(lang);
                }
                return _buildMessageBubble(_messages[i]);
              },
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: lang.t('Ask a question about farming...'),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.grey : const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isLoading ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _messages.length > 1
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton.small(
                onPressed: _isLoading ? null : _analyzeFarm,
                backgroundColor: const Color(0xFF2E7D32),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAiStatusBar(IoTProvider iot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: ApiKeys.hasGeminiKey
          ? Colors.green.shade50
          : Colors.orange.shade50,
      child: Row(
        children: [
          Icon(
            ApiKeys.hasGeminiKey ? Icons.check_circle : Icons.info_outline,
            size: 16,
            color: ApiKeys.hasGeminiKey ? Colors.green : Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ApiKeys.hasGeminiKey
                  ? 'Gemini AI active • ${iot.sensors.length} sensors • ${iot.actuators.length} actuators'
                  : 'Offline mode — Add Gemini API key in Settings for AI responses',
              style: TextStyle(
                fontSize: 11,
                color: ApiKeys.hasGeminiKey
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () => _sendMessage(text),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF2E7D32) : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
        ),
        child: SelectableText(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(LanguageProvider lang) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.green.shade400,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              ApiKeys.hasGeminiKey ? lang.t('AI is analyzing...') : lang.t('Thinking...'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
