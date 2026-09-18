import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/gemini_ai_service.dart';
import '../services/iot_service.dart';
import '../services/weather_service.dart';
import '../database/daos/crop_dao.dart';

/// AI Agent that periodically evaluates farm conditions and takes autonomous actions.
/// This is the brain of the smart agriculture system.
class AIAgent {
  final GeminiAIService _aiService = GeminiAIService();
  final WeatherService _weatherService = WeatherService();
  Timer? _evaluationTimer;

  bool _isActive = false;
  bool get isActive => _isActive;

  String _lastRecommendation = '';
  String get lastRecommendation => _lastRecommendation;

  DateTime? _lastEvaluationTime;
  DateTime? get lastEvaluationTime => _lastEvaluationTime;

  final List<AgentLog> _logs = [];
  List<AgentLog> get logs => List.unmodifiable(_logs);

  // Callbacks
  Function(String deviceId)? onToggleDevice;
  Function(String message, String severity)? onAlert;
  Function()? onStateChanged;

  /// Start periodic farm evaluation.
  void start() {
    if (_isActive) return;
    _isActive = true;
    _addLog('AI Agent activated', 'info');
    onStateChanged?.call();

    // First evaluation immediately
    // Timer set for periodic checks
    _evaluationTimer?.cancel();
    _evaluationTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      // The provider calls evaluate() on its own schedule
    });
  }

  /// Stop the agent.
  void stop() {
    _isActive = false;
    _evaluationTimer?.cancel();
    _evaluationTimer = null;
    _addLog('AI Agent paused', 'info');
    onStateChanged?.call();
  }

  /// Evaluate current farm conditions and decide on actions.
  Future<AIDecision> evaluate({
    required List<IoTDevice> devices,
    required List<Crop> crops,
  }) async {
    if (!_isActive) {
      return AIDecision(
        action: 'NONE',
        reason: 'Agent is paused',
        confidence: 0,
      );
    }

    try {
      // Fetch current weather
      WeatherData? weather;
      try {
        weather = await _weatherService.fetchWeather();
      } catch (_) {
        debugPrint('AIAgent: Could not fetch weather');
      }

      // Ask AI to evaluate
      final decision = await _aiService.evaluateIoTAction(
        devices: devices,
        crops: crops,
        weather: weather,
      );

      _lastEvaluationTime = DateTime.now();
      _lastRecommendation = decision.reason;

      // Execute action if confidence is high enough
      if (decision.confidence >= 0.7 && decision.action != 'NONE') {
        final pump = devices.where((d) => d.type == 'pump').firstOrNull;
        if (pump != null) {
          final shouldStart = decision.action == 'START' && !pump.isActive;
          final shouldStop = decision.action == 'STOP' && pump.isActive;

          if (shouldStart || shouldStop) {
            onToggleDevice?.call(pump.id);
            final actionText = shouldStart ? 'Started pump' : 'Stopped pump';
            _addLog('$actionText: ${decision.reason}', 'action');
            onAlert?.call(
              '🤖 AI Agent: $actionText — ${decision.reason}',
              'info',
            );
          }
        }
      }

      _addLog(
        'Evaluated: ${decision.reason} (${(decision.confidence * 100).toStringAsFixed(0)}% confidence)',
        'evaluation',
      );
      onStateChanged?.call();

      return decision;
    } catch (e) {
      debugPrint('AIAgent.evaluate error: $e');
      _addLog('Evaluation failed: $e', 'error');
      return AIDecision(
        action: 'NONE',
        reason: 'Evaluation error',
        confidence: 0,
      );
    }
  }

  /// Get AI analysis of the whole farm.
  Future<String> getFullAnalysis({
    required List<IoTDevice> devices,
    required List<Crop> crops,
  }) async {
    WeatherData? weather;
    try {
      weather = await _weatherService.fetchWeather();
    } catch (_) {}

    return _aiService.analyzeFarm(
      devices: devices,
      crops: crops,
      weather: weather,
    );
  }

  void _addLog(String message, String type) {
    _logs.insert(
      0,
      AgentLog(message: message, type: type, timestamp: DateTime.now()),
    );
    if (_logs.length > 100) _logs.removeLast();
  }

  void clearLogs() {
    _logs.clear();
    onStateChanged?.call();
  }

  void dispose() {
    _evaluationTimer?.cancel();
  }
}

/// A log entry from the AI agent.
class AgentLog {
  final String message;
  final String type; // info, action, evaluation, error
  final DateTime timestamp;

  AgentLog({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}
