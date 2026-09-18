import 'dart:async';

import 'package:flutter/material.dart';

import '../services/iot_service.dart';
import '../services/gemini_ai_service.dart';
import '../services/weather_service.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/task_dao.dart';
import '../database/daos/finance_dao.dart';

class IoTAlert {
  final String id;
  final String deviceId;
  final String deviceName;
  final String message;
  final String severity;
  final DateTime timestamp;
  bool isRead;

  IoTAlert({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
  });
}

class SensorReading {
  final DateTime timestamp;
  final double value;
  SensorReading(this.timestamp, this.value);
}

class IoTProvider extends ChangeNotifier {
  final IoTService _iotService = IoTService();
  final GeminiAIService _geminiService = GeminiAIService();

  final List<IoTAlert> _alerts = [];
  bool _autoIrrigation = true;
  double _moistureThreshold = 30.0;
  Timer? _pollingTimer;

  List<IoTDevice> get devices => _iotService.devices;
  List<IoTAlert> get alerts => _alerts;
  int get unreadAlertCount => _alerts.where((a) => !a.isRead).length;
  bool get autoIrrigation => _autoIrrigation;
  double get moistureThreshold => _moistureThreshold;

  List<IoTDevice> get sensors =>
      _iotService.devices.where((d) => d.type.contains('sensor')).toList();
  List<IoTDevice> get actuators => _iotService.devices
      .where((d) => d.type == 'pump' || d.type == 'valve')
      .toList();
  int get onlineCount => _iotService.devices.where((d) => d.isOnline).length;

  Future<void> connect(String farmId) async {
    // In production, broker URL and credentials come from secure config
    await _iotService.connectMqtt(
      'test.mosquitto.org',
      'ireagation_app_${DateTime.now().millisecondsSinceEpoch}',
      farmId,
    );

    // Polling UI since mqtt updates aren't directly linked to provider yet
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      notifyListeners();
    });
  }

  void toggleDevice(String deviceId) {
    final device = _iotService.devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => IoTDevice(id: '', name: '', type: ''),
    );
    if (device.id.isNotEmpty) {
      final cmd = device.isActive ? 'PUMP_OFF' : 'PUMP_ON';
      _iotService.sendCommand(deviceId, cmd, 'flutter_app');
      // Optimistic update
      device.isActive = !device.isActive;
      notifyListeners();
    }
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
    // Return empty for now as real history requires backend TSDB
    return [];
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // AI Agent stubs for UI compatibility
  bool get isAiAgentActive => _autoIrrigation;
  String get lastAiRecommendation => 'Handled by local rule engine safely.';
  List<dynamic> get aiLogs => [];

  // Dummy getter for aiAgent to satisfy UI
  dynamic get aiAgent => null;

  void toggleAiAgent() {
    setAutoIrrigation(!_autoIrrigation);
  }

  Future<void> runAiEvaluationWithContext(List<dynamic> crops) async {
    // Stubbed to satisfy UI compilation.
  }

  Future<String> getAiResponse(
    String query, {
    List<dynamic>? crops,
    List<dynamic>? tasks,
    List<dynamic>? expenses,
    List<dynamic>? sales,
    dynamic weather,
  }) async {
    return 'AI Assistant is currently operating securely from the backend. Real-time Gemini inference will respond here once edge functions are live.';
  }
}
