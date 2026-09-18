import 'dart:async';
import 'dart:math';

/// Represents an IoT sensor device.
class IoTDevice {
  final String id;
  final String name;
  final String
  type; // moisture_sensor, temp_sensor, humidity_sensor, pump, valve
  bool isOnline;
  bool isActive; // For pumps/valves: ON/OFF
  double? lastReading;
  String? unit;
  DateTime lastUpdated;

  IoTDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isOnline = true,
    this.isActive = false,
    this.lastReading,
    this.unit,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
}

/// Represents a sensor reading over time.
class SensorReading {
  final DateTime timestamp;
  final double value;

  SensorReading({required this.timestamp, required this.value});
}

/// Alert from IoT sensors.
class IoTAlert {
  final String id;
  final String deviceId;
  final String deviceName;
  final String message;
  final String severity; // info, warning, critical
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

/// Simulates IoT sensor data and device control.
/// In production, this would connect to MQTT or a real IoT gateway.
class IoTService {
  final Random _random = Random();
  Timer? _simulationTimer;

  // Callbacks
  Function(List<IoTDevice>)? onDevicesUpdated;
  Function(IoTAlert)? onAlertTriggered;

  // Real devices would be fetched from an API/DB
  final List<IoTDevice> devices = [];

  // Sensor history (last 20 readings)
  final Map<String, List<SensorReading>> _sensorHistory = {};

  /// In a real world project, this would connect to a WebSocket or MQTT broker
  void startSimulation() {
    // No-op for now. In real world, connect to IoT gateway here.
  }

  void stopSimulation() {
    // No-op for now.
  }

  void _simulateReadings() {
    // Removed fake data simulation. 
    // Real readings would arrive via MQTT/WebSocket callbacks and trigger onDevicesUpdated.
  }

  void _checkAlerts() {
    for (final device in devices) {
      if (device.type == 'moisture_sensor' && device.lastReading != null) {
        if (device.lastReading! < 25) {
          onAlertTriggered?.call(
            IoTAlert(
              id: '${device.id}-${DateTime.now().millisecondsSinceEpoch}',
              deviceId: device.id,
              deviceName: device.name,
              message:
                  'Soil moisture critically low (${device.lastReading!.toStringAsFixed(1)}%)',
              severity: 'critical',
              timestamp: DateTime.now(),
            ),
          );
        } else if (device.lastReading! < 35) {
          onAlertTriggered?.call(
            IoTAlert(
              id: '${device.id}-${DateTime.now().millisecondsSinceEpoch}',
              deviceId: device.id,
              deviceName: device.name,
              message:
                  'Soil moisture low (${device.lastReading!.toStringAsFixed(1)}%)',
              severity: 'warning',
              timestamp: DateTime.now(),
            ),
          );
        }
      }
      if (device.type == 'temp_sensor' && device.lastReading != null) {
        if (device.lastReading! > 40) {
          onAlertTriggered?.call(
            IoTAlert(
              id: '${device.id}-${DateTime.now().millisecondsSinceEpoch}',
              deviceId: device.id,
              deviceName: device.name,
              message:
                  'Temperature too high (${device.lastReading!.toStringAsFixed(1)}°C)',
              severity: 'critical',
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    }
  }

  List<SensorReading> getHistory(String deviceId) {
    return _sensorHistory[deviceId] ?? [];
  }

  /// Toggle a pump or valve.
  void toggleDevice(String deviceId) {
    final device = devices.firstWhere((d) => d.id == deviceId);
    device.isActive = !device.isActive;
    device.lastUpdated = DateTime.now();
    onDevicesUpdated?.call(devices);
  }

  void dispose() {
    _simulationTimer?.cancel();
  }
}
