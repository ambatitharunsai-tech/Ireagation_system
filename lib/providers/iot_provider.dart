import 'dart:async';

import 'package:flutter/material.dart';

import '../services/iot_service.dart';
import '../services/ai_agent.dart';
import '../services/gemini_ai_service.dart';
import '../services/weather_service.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/task_dao.dart';
import '../database/daos/finance_dao.dart';
/// Manages IoT device state, sensor readings, alerts, and AI agent.
class IoTProvider extends ChangeNotifier {
  final IoTService _iotService = IoTService();
  final AIAgent _aiAgent = AIAgent();
  final GeminiAIService _geminiService = GeminiAIService();

  List<IoTDevice> _devices = [];
  final List<IoTAlert> _alerts = [];
  bool _autoIrrigation = true;
  double _moistureThreshold = 30.0;
  Timer? _aiEvalTimer;

  // AI Agent state
  final List<String> _aiRecommendations = [];

  List<IoTDevice> get devices => _devices;
  List<IoTAlert> get alerts => _alerts;
  int get unreadAlertCount => _alerts.where((a) => !a.isRead).length;
  bool get autoIrrigation => _autoIrrigation;
  double get moistureThreshold => _moistureThreshold;

  // AI Agent getters
  AIAgent get aiAgent => _aiAgent;
  bool get isAiAgentActive => _aiAgent.isActive;
  String get lastAiRecommendation => _aiAgent.lastRecommendation;
  List<AgentLog> get aiLogs => _aiAgent.logs;
  List<String> get aiRecommendations => _aiRecommendations;

  // Convenience getters
  List<IoTDevice> get sensors => _devices
      .where(
        (d) =>
            d.type == 'moisture_sensor' ||
            d.type == 'temp_sensor' ||
            d.type == 'humidity_sensor',
      )
      .toList();
  List<IoTDevice> get actuators =>
      _devices.where((d) => d.type == 'pump' || d.type == 'valve').toList();
  int get onlineCount => _devices.where((d) => d.isOnline).length;

  IoTProvider() {
    _devices = List.from(_iotService.devices);
    _iotService.onDevicesUpdated = (devices) {
      _devices = List.from(devices);

      // Auto irrigation logic (rule-based fallback)
      if (_autoIrrigation && !_aiAgent.isActive) {
        _checkAutoIrrigation();
      }

      notifyListeners();
    };
    _iotService.onAlertTriggered = (alert) {
      // Avoid duplicate alerts within 30 seconds
      final isDuplicate = _alerts.any(
        (a) =>
            a.deviceId == alert.deviceId &&
            DateTime.now().difference(a.timestamp).inSeconds < 30,
      );
      if (!isDuplicate) {
        _alerts.insert(0, alert);
        if (_alerts.length > 50) _alerts.removeLast();
        notifyListeners();
      }
    };

    // Wire up AI agent callbacks
    _aiAgent.onToggleDevice = (deviceId) {
      _iotService.toggleDevice(deviceId);
      notifyListeners();
    };
    _aiAgent.onAlert = (message, severity) {
      _alerts.insert(
        0,
        IoTAlert(
          id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
          deviceId: 'ai-agent',
          deviceName: 'AI Agent',
          message: message,
          severity: severity,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    };
    _aiAgent.onStateChanged = () {
      notifyListeners();
    };

    _iotService.startSimulation();
  }

  /// Toggle the AI Agent on/off.
  void toggleAiAgent() {
    if (_aiAgent.isActive) {
      _aiAgent.stop();
      _aiEvalTimer?.cancel();
      _aiEvalTimer = null;
    } else {
      _aiAgent.start();
      // Run first evaluation immediately
      _runAiEvaluation();
      // Schedule periodic evaluations every 60 seconds
      _aiEvalTimer?.cancel();
      _aiEvalTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        _runAiEvaluation();
      });
    }
    notifyListeners();
  }

  /// Run AI evaluation now (on demand).
  Future<void> _runAiEvaluation() async {
    // We need crops — for now we pass empty since provider doesn't have direct access
    // The AI agent uses the devices it has
    await _aiAgent.evaluate(
      devices: _devices,
      crops: [], // Crops are injected from the outside when needed
    );
    notifyListeners();
  }

  /// Run AI evaluation with crops context (called from UI).
  Future<AIDecision> runAiEvaluationWithContext(List<Crop> crops) async {
    return _aiAgent.evaluate(devices: _devices, crops: crops);
  }

  /// Get AI chat response with full context.
  Future<String> getAiResponse(
    String query, {
    List<Crop>? crops,
    List<FarmTask>? tasks,
    List<Expense>? expenses,
    List<Sale>? sales,
    WeatherData? weather,
  }) async {
    return _geminiService.getSmartAdvice(
      query: query,
      devices: _devices,
      crops: crops,
      tasks: tasks,
      expenses: expenses,
      sales: sales,
      weather: weather,
    );
  }

  /// Get full farm analysis.
  Future<String> getFullFarmAnalysis(List<Crop> crops) async {
    return _aiAgent.getFullAnalysis(devices: _devices, crops: crops);
  }

  /// Build a sensor data summary for context display.
  String getSensorSummary() {
    final sb = StringBuffer();
    for (final d in sensors) {
      sb.writeln(
        '${d.name}: ${d.lastReading?.toStringAsFixed(1) ?? "N/A"}${d.unit ?? ""}',
      );
    }
    for (final d in actuators) {
      sb.writeln('${d.name}: ${d.isActive ? "RUNNING" : "OFF"}');
    }
    return sb.toString();
  }

  void _checkAutoIrrigation() {
    final moistureSensors = _devices.where((d) => d.type == 'moisture_sensor');
    final pump = _devices.firstWhere(
      (d) => d.type == 'pump',
      orElse: () => IoTDevice(id: '', name: '', type: ''),
    );

    if (pump.id.isEmpty) return;

    final readings = moistureSensors
        .where((d) => d.lastReading != null)
        .map((d) => d.lastReading!)
        .toList();
    if (readings.isEmpty) return;

    final avgMoisture = readings.reduce((a, b) => a + b) / readings.length;

    if (avgMoisture < _moistureThreshold && !pump.isActive) {
      _iotService.toggleDevice(pump.id);
      _alerts.insert(
        0,
        IoTAlert(
          id: 'auto-${DateTime.now().millisecondsSinceEpoch}',
          deviceId: pump.id,
          deviceName: pump.name,
          message:
              'Auto-irrigation started (avg moisture: ${avgMoisture.toStringAsFixed(1)}%)',
          severity: 'info',
          timestamp: DateTime.now(),
        ),
      );
    } else if (avgMoisture > 75 && pump.isActive) {
      _iotService.toggleDevice(pump.id);
      _alerts.insert(
        0,
        IoTAlert(
          id: 'auto-${DateTime.now().millisecondsSinceEpoch}',
          deviceId: pump.id,
          deviceName: pump.name,
          message:
              'Auto-irrigation stopped (avg moisture: ${avgMoisture.toStringAsFixed(1)}%)',
          severity: 'info',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void toggleDevice(String deviceId) {
    _iotService.toggleDevice(deviceId);
    notifyListeners();
  }

  void setAutoIrrigation(bool value) {
    _autoIrrigation = value;
    notifyListeners();
  }

  void setMoistureThreshold(double value) {
    _moistureThreshold = value;
    notifyListeners();
  }

  void markAlertRead(String alertId) {
    final alert = _alerts.firstWhere(
      (a) => a.id == alertId,
      orElse: () => IoTAlert(
        id: '',
        deviceId: '',
        deviceName: '',
        message: '',
        severity: '',
        timestamp: DateTime.now(),
      ),
    );
    if (alert.id.isNotEmpty) {
      alert.isRead = true;
      notifyListeners();
    }
  }

  void clearAllAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  List<SensorReading> getSensorHistory(String deviceId) {
    return _iotService.getHistory(deviceId);
  }

  @override
  void dispose() {
    _iotService.dispose();
    _aiAgent.dispose();
    _aiEvalTimer?.cancel();
    super.dispose();
  }
}
