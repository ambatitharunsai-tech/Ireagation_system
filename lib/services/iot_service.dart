import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class IoTDevice {
  final String id;
  final String name;
  final String type;
  bool isOnline;
  bool isActive;
  double? lastReading;
  String? unit;

  IoTDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isOnline = false,
    this.isActive = false,
    this.lastReading,
    this.unit,
  });
}

class IoTService {
  final List<IoTDevice> _devices = [];
  MqttServerClient? _client;
  String? _farmId;

  List<IoTDevice> get devices => _devices;

  Future<void> connectMqtt(String brokerUrl, String clientId, String farmId, {String? username, String? password}) async {
    _farmId = farmId;
    _client = MqttServerClient(brokerUrl, clientId);
    _client!.port = 1883;
    _client!.keepAlivePeriod = 60;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;

    try {
      await _client!.connect(username, password);
    } catch (e) {
      debugPrint('MQTT Exception: $e');
      _client!.disconnect();
    }
  }

  void _onConnected() {
    debugPrint('MQTT Connected. Subscribing to topics...');
    if (_farmId != null) {
      _client!.subscribe('farms/$_farmId/devices/+/telemetry', MqttQos.atLeastOnce);
      _client!.subscribe('farms/$_farmId/devices/+/status', MqttQos.atLeastOnce);
    }

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      _handleMqttMessage(c[0].topic, payload);
    });
  }

  void _onDisconnected() {
    debugPrint('MQTT Disconnected');
  }

  void _handleMqttMessage(String topic, String payload) {
    try {
      final data = jsonDecode(payload);
      final deviceId = data['device_id'];

      // Simple handling
      final device = _devices.firstWhere(
        (d) => d.id == deviceId,
        orElse: () {
          final newDevice = IoTDevice(
            id: deviceId,
            name: 'Device $deviceId',
            type: data.containsKey('soil_moisture') ? 'moisture_sensor' : 'unknown',
          );
          _devices.add(newDevice);
          return newDevice;
        },
      );

      if (topic.endsWith('/telemetry')) {
        device.isOnline = true;
        if (data.containsKey('soil_moisture')) device.lastReading = (data['soil_moisture'] as num).toDouble();
        if (data.containsKey('temperature')) device.lastReading = (data['temperature'] as num).toDouble();
        // UI should listen or we should use callbacks
      } else if (topic.endsWith('/status')) {
        device.isOnline = data['is_online'] ?? false;
        device.isActive = data['is_active'] ?? false;
      }
    } catch (e) {
      debugPrint('Error parsing MQTT: $e');
    }
  }

  void sendCommand(String deviceId, String command, String requestedBy) {
    if (_client == null || _client!.connectionStatus!.state != MqttConnectionState.connected || _farmId == null) {
      debugPrint('Cannot send command. Not connected.');
      return;
    }

    final topic = 'farms/$_farmId/devices/$deviceId/command';
    final payload = jsonEncode({
      'command': command,
      'requested_by': requestedBy,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }
}
