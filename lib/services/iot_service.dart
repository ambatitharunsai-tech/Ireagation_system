import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/iot_models.dart';

class IoTService {
  final List<IoTDevice> _devices = [];
  MqttServerClient? _client;
  String? _farmId;
  
  MqttConnectionStateApp _connectionState = MqttConnectionStateApp.DISCONNECTED;
  MqttConnectionStateApp get connectionState => _connectionState;

  final Function(TelemetryReading)? onTelemetryReceived;
  final Function(DeviceStatus)? onStatusReceived;
  final Function(CommandAck)? onCommandAck;
  final VoidCallback? onConnectionStateChanged;

  IoTService({
    this.onTelemetryReceived,
    this.onStatusReceived,
    this.onCommandAck,
    this.onConnectionStateChanged,
  });

  List<IoTDevice> get devices => _devices;

  Future<void> connectMqtt(
    String brokerUrl,
    String clientId,
    String farmId, {
    String? username,
    String? password,
    int port = 1883,
    bool secure = false,
  }) async {
    _farmId = farmId;
    
    _updateState(MqttConnectionStateApp.CONNECTING);
    _client = MqttServerClient(brokerUrl, clientId);
    _client!.port = port;
    _client!.secure = secure;
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = true; // Enable auto-reconnect
    
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onAutoReconnect = _onAutoReconnect;
    _client!.onAutoReconnected = _onConnected;

    try {
      await _client!.connect(username, password);
    } catch (e) {
      debugPrint('MQTT Exception: $e');
      _client!.disconnect();
      _updateState(MqttConnectionStateApp.ERROR);
    }
  }

  void _updateState(MqttConnectionStateApp state) {
    _connectionState = state;
    if (onConnectionStateChanged != null) onConnectionStateChanged!();
  }

  void _onAutoReconnect() {
    _updateState(MqttConnectionStateApp.RECONNECTING);
  }

  void _onConnected() {
    debugPrint('MQTT Connected. Subscribing to topics...');
    _updateState(MqttConnectionStateApp.CONNECTED);
    
    if (_farmId != null) {
      _client!.subscribe('farms/$_farmId/devices/+/telemetry', MqttQos.atLeastOnce);
      _client!.subscribe('farms/$_farmId/devices/+/status', MqttQos.atLeastOnce);
      _client!.subscribe('farms/$_farmId/devices/+/ack', MqttQos.atLeastOnce);
    }

    // Clean up old listener if exists
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      if (c == null || c.isEmpty) return;
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      _handleMqttMessage(c[0].topic, payload);
    });
  }

  void _onDisconnected() {
    debugPrint('MQTT Disconnected');
    _updateState(MqttConnectionStateApp.DISCONNECTED);
  }

  void _handleMqttMessage(String topic, String payload) {
    try {
      final data = jsonDecode(payload);
      final deviceId = data['device_id']?.toString();
      if (deviceId == null || deviceId.isEmpty) return;

      if (topic.endsWith('/telemetry')) {
        final telemetry = TelemetryReading.fromJson(data);
        
        final device = _getOrAddDevice(deviceId, 'sensor');
        device.isOnline = true;
        device.lastSeenAt = telemetry.receivedAt; // use receivedAt since telemetry.timestamp could be old
        device.latestTelemetry = telemetry;
        
        if (onTelemetryReceived != null) onTelemetryReceived!(telemetry);
      } 
      else if (topic.endsWith('/status')) {
        final status = DeviceStatus.fromJson(data);
        
        final device = _getOrAddDevice(deviceId, 'device');
        device.isOnline = status.online;
        device.lastSeenAt = status.timestamp;
        device.batteryLevel = status.batteryLevel ?? device.batteryLevel;
        device.signalStrength = status.signalStrength ?? device.signalStrength;
        if (status.pumpState != null) device.currentPumpState = status.pumpState;
        if (status.valveState != null) device.currentValveState = status.valveState;

        if (onStatusReceived != null) onStatusReceived!(status);
      }
      else if (topic.endsWith('/ack')) {
        final ack = CommandAck.fromJson(data);
        if (onCommandAck != null) onCommandAck!(ack);
      }
    } catch (e) {
      debugPrint('Error parsing MQTT: $e');
    }
  }

  IoTDevice _getOrAddDevice(String deviceId, String defaultType) {
    return _devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () {
        final newDevice = IoTDevice(
          id: deviceId,
          farmId: _farmId ?? 'unknown',
          zoneId: 'default',
          name: 'Device $deviceId',
          deviceType: defaultType,
        );
        _devices.add(newDevice);
        return newDevice;
      },
    );
  }

  void sendCommand(IrrigationCommand command) {
    if (_client == null || _client!.connectionStatus!.state != MqttConnectionState.connected || _farmId == null) {
      debugPrint('Cannot send command. Not connected.');
      return;
    }

    final topic = 'farms/$_farmId/devices/${command.deviceId}/command';
    final payload = jsonEncode({
      'command_id': command.commandId,
      'device_id': command.deviceId,
      'command': command.command,
      'requested_by': command.requestedBy,
      'requested_at': command.requestedAt.toUtc().toIso8601String(),
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    command.state = CommandState.SENT;
  }
  
  void disconnect() {
    _client?.disconnect();
  }
}
