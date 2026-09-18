import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/iot_service.dart';
import '../models/iot_models.dart';

class IoTProvider extends ChangeNotifier {
  late final IoTService _iotService;

  final List<IoTAlertModel> _alerts = [];
  final List<IrrigationCommand> _pendingCommands = [];
  
  bool _autoIrrigation = false; // Automation mode
  double _moistureThreshold = 30.0;
  Timer? _pollingTimer;
  bool _emergencyStop = false; // Emergency stop state

  IoTProvider() {
    _iotService = IoTService(
      onTelemetryReceived: _onTelemetry,
      onStatusReceived: _onStatus,
      onCommandAck: _onAck,
      onConnectionStateChanged: _onConnectionChange,
    );
  }

  List<IoTDevice> get devices => _iotService.devices;
  List<IoTAlertModel> get alerts => _alerts;
  int get unreadAlertCount => _alerts.where((a) => !a.isRead).length;
  bool get autoIrrigation => _autoIrrigation;
  double get moistureThreshold => _moistureThreshold;
  bool get emergencyStop => _emergencyStop;

  MqttConnectionStateApp get connectionState => _iotService.connectionState;

  List<IoTDevice> get sensors =>
      _iotService.devices.where((d) => d.latestTelemetry != null || d.deviceType == 'sensor').toList();
  List<IoTDevice> get actuators => _iotService.devices
      .where((d) => d.deviceType == 'pump' || d.deviceType == 'valve')
      .toList();
  int get onlineCount => _iotService.devices.where((d) => d.isOnline).length;

  Future<void> connect(String farmId) async {
    const broker = String.fromEnvironment('MQTT_BROKER', defaultValue: 'mqtt.ireagation.local');
    const port = int.fromEnvironment('MQTT_PORT', defaultValue: 1883);
    const secure = bool.fromEnvironment('MQTT_SECURE', defaultValue: false);
    const user = String.fromEnvironment('MQTT_USER', defaultValue: 'app');
    const pass = String.fromEnvironment('MQTT_PASS', defaultValue: 'secret');

    await _iotService.connectMqtt(
      broker,
      'app_${const Uuid().v4().substring(0, 8)}',
      farmId,
      username: user.isNotEmpty ? user : null,
      password: pass.isNotEmpty ? pass : null,
      port: port,
      secure: secure,
    );

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      // Re-evaluate freshness UI states
      notifyListeners();
    });
  }

  void _onConnectionChange() {
    notifyListeners();
  }

  void _onTelemetry(TelemetryReading reading) {
    notifyListeners();
  }

  void _onStatus(DeviceStatus status) {
    notifyListeners();
  }

  void _onAck(CommandAck ack) {
    final cmdIdx = _pendingCommands.indexWhere((c) => c.commandId == ack.commandId);
    if (cmdIdx != -1) {
      final cmd = _pendingCommands[cmdIdx];
      if (ack.status == 'accepted') {
        cmd.state = CommandState.ACKNOWLEDGED;
        cmd.acknowledgedAt = ack.timestamp;
      } else if (ack.status == 'completed') {
        cmd.state = CommandState.COMPLETED;
        cmd.completedAt = ack.timestamp;
        _pendingCommands.removeAt(cmdIdx);
      } else {
        cmd.state = CommandState.FAILED;
        cmd.failureReason = ack.status;
        _pendingCommands.removeAt(cmdIdx);
      }
      notifyListeners();
    }
  }

  void toggleDevice(String deviceId, String requestedBy) {
    if (_emergencyStop) return; // Block physical commands if emergency stop

    final device = _iotService.devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => IoTDevice(id: '', farmId: '', zoneId: '', name: '', deviceType: ''),
    );
    if (device.id.isEmpty) return;

    final targetState = device.currentPumpState == 'ON' ? 'PUMP_OFF' : 'PUMP_ON';
    
    final cmd = IrrigationCommand(
      commandId: const Uuid().v4(),
      deviceId: deviceId,
      zoneId: device.zoneId,
      command: targetState,
      requestedBy: requestedBy,
      requestedAt: DateTime.now(),
    );
    _pendingCommands.add(cmd);
    _iotService.sendCommand(cmd);
    notifyListeners(); // Update UI to show 'PENDING'
  }

  void setEmergencyStop(bool value) {
    _emergencyStop = value;
    if (_emergencyStop) {
      // Auto-irrigation is immediately killed
      _autoIrrigation = false;
      // Broadcast stop to all actuators
      for (final actuator in actuators) {
        final cmd = IrrigationCommand(
          commandId: const Uuid().v4(),
          deviceId: actuator.id,
          zoneId: actuator.zoneId,
          command: 'PUMP_OFF',
          requestedBy: 'SYSTEM_EMERGENCY',
          requestedAt: DateTime.now(),
        );
        _pendingCommands.add(cmd);
        _iotService.sendCommand(cmd);
      }
    }
    notifyListeners();
  }

  void setAutoIrrigation(bool value) {
    if (_emergencyStop && value) return; // Cannot enable auto during emergency
    _autoIrrigation = value;
    notifyListeners();
  }

  void setMoistureThreshold(double value) {
    _moistureThreshold = value;
    notifyListeners();
  }

  void markAlertRead(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      _alerts[idx].readAt = DateTime.now();
      notifyListeners();
    }
  }

  void clearAllAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  CommandState? getCommandStateForDevice(String deviceId) {
    final cmds = _pendingCommands.where((c) => c.deviceId == deviceId).toList();
    if (cmds.isEmpty) return null;
    return cmds.last.state;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _iotService.disconnect();
    super.dispose();
  }

  // AI Agent stubs for UI compatibility (AI is advisory only)
  bool get isAiAgentActive => false; 
  String get lastAiRecommendation => 'AI recommendations unavailable';
  List<dynamic> get aiLogs => [];
  dynamic get aiAgent => null;

  void toggleAiAgent() {
    // AI cannot manage hardware directly
  }

  Future<void> runAiEvaluationWithContext(List<dynamic> crops) async {
    // Stub
  }

  Future<String> getAiResponse(
    String query, {
    List<dynamic>? crops,
    List<dynamic>? tasks,
    List<dynamic>? expenses,
    List<dynamic>? sales,
    dynamic weather,
  }) async {
    return 'AI Assistant is currently advisory only. Waiting for backend AI connectivity.';
  }

  void addSimulatedDevice() {
    final newId = 'sim_${const Uuid().v4().substring(0, 6)}';
    final isSensor = _iotService.devices.length % 2 == 0;
    
    final device = IoTDevice(
      id: newId,
      farmId: 'simulated_farm',
      zoneId: 'Zone 1',
      name: isSensor ? 'Soil Sensor $newId' : 'Water Pump $newId',
      deviceType: isSensor ? 'sensor' : 'pump',
    );
    device.isOnline = true;
    device.batteryLevel = 95.0;
    device.signalStrength = '-50 dBm';
    device.lastSeenAt = DateTime.now();

    if (isSensor) {
      device.latestTelemetry = TelemetryReading(
        deviceId: newId,
        soilMoisture: 35.5,
        temperature: 25.0,
        humidity: 60.0,
        timestamp: DateTime.now(),
        receivedAt: DateTime.now(),
      );
    }

    _iotService.devices.add(device);
    notifyListeners();
  }

}