import 'package:flutter/foundation.dart';

enum DeviceState { LIVE, STALE, OFFLINE, UNKNOWN, ERROR }
enum MqttConnectionStateApp { DISCONNECTED, CONNECTING, CONNECTED, RECONNECTING, ERROR }
enum CommandState { PENDING, SENT, ACKNOWLEDGED, EXECUTING, COMPLETED, REJECTED, FAILED, TIMEOUT, UNKNOWN }

class IoTDevice {
  final String id;
  final String farmId;
  final String zoneId;
  final String name;
  final String deviceType;
  final String? hardwareModel;
  final String? firmwareVersion;
  
  bool isOnline;
  DateTime? lastSeenAt;
  double? batteryLevel;
  String? signalStrength;
  final DateTime registeredAt;

  // Real-time parsed state for convenience in UI
  TelemetryReading? latestTelemetry;
  String? currentPumpState;
  String? currentValveState;

  IoTDevice({
    required this.id,
    required this.farmId,
    required this.zoneId,
    required this.name,
    required this.deviceType,
    this.hardwareModel,
    this.firmwareVersion,
    this.isOnline = false,
    this.lastSeenAt,
    this.batteryLevel,
    this.signalStrength,
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime.now();

  DeviceState get state {
    if (!isOnline) return DeviceState.OFFLINE;
    if (lastSeenAt == null) return DeviceState.UNKNOWN;
    final diff = DateTime.now().difference(lastSeenAt!);
    if (diff.inMinutes > 30) return DeviceState.STALE;
    return DeviceState.LIVE;
  }
}

class TelemetryReading {
  final String deviceId;
  final DateTime timestamp;
  final DateTime receivedAt;
  
  final double? soilMoisture;
  final double? temperature;
  final double? humidity;
  final double? waterLevel;
  final double? flowRate;
  final bool? rainDetected;
  final String? pumpState;
  final String? valveState;

  TelemetryReading({
    required this.deviceId,
    required this.timestamp,
    required this.receivedAt,
    this.soilMoisture,
    this.temperature,
    this.humidity,
    this.waterLevel,
    this.flowRate,
    this.rainDetected,
    this.pumpState,
    this.valveState,
  });

  factory TelemetryReading.fromJson(Map<String, dynamic> json) {
    // Validate inputs to prevent crashes
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) {
        if (value.isNaN || value.isInfinite) return null;
        return value.toDouble();
      }
      if (value is String) return double.tryParse(value);
      return null;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    return TelemetryReading(
      deviceId: json['device_id']?.toString() ?? '',
      timestamp: parseDate(json['timestamp']) ?? DateTime.now(), // Fallback to received time only if missing
      receivedAt: DateTime.now(),
      soilMoisture: parseDouble(json['soil_moisture']),
      temperature: parseDouble(json['temperature']),
      humidity: parseDouble(json['humidity']),
      waterLevel: parseDouble(json['water_level']),
      flowRate: parseDouble(json['flow_rate']),
      rainDetected: json['rain_detected'] as bool?,
      pumpState: json['pump_state']?.toString(),
      valveState: json['valve_state']?.toString(),
    );
  }
}

class DeviceStatus {
  final String deviceId;
  final bool online;
  final String? pumpState;
  final String? valveState;
  final double? batteryLevel;
  final String? signalStrength;
  final DateTime timestamp;

  DeviceStatus({
    required this.deviceId,
    required this.online,
    this.pumpState,
    this.valveState,
    this.batteryLevel,
    this.signalStrength,
    required this.timestamp,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return DeviceStatus(
      deviceId: json['device_id']?.toString() ?? '',
      online: json['is_online'] ?? json['online'] ?? false,
      pumpState: json['pump_state']?.toString(),
      valveState: json['valve_state']?.toString(),
      batteryLevel: parseDouble(json['battery_level']),
      signalStrength: json['signal_strength']?.toString(),
      timestamp: json['timestamp'] != null ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

class IrrigationCommand {
  final String commandId;
  final String deviceId;
  final String zoneId;
  final String command; // e.g., PUMP_ON, PUMP_OFF
  final String requestedBy;
  final DateTime requestedAt;
  CommandState state;
  DateTime? acknowledgedAt;
  DateTime? completedAt;
  String? failureReason;

  IrrigationCommand({
    required this.commandId,
    required this.deviceId,
    required this.zoneId,
    required this.command,
    required this.requestedBy,
    required this.requestedAt,
    this.state = CommandState.PENDING,
    this.acknowledgedAt,
    this.completedAt,
    this.failureReason,
  });
}

class CommandAck {
  final String commandId;
  final String deviceId;
  final String command;
  final String status;
  final DateTime timestamp;

  CommandAck({
    required this.commandId,
    required this.deviceId,
    required this.command,
    required this.status,
    required this.timestamp,
  });

  factory CommandAck.fromJson(Map<String, dynamic> json) {
    return CommandAck(
      commandId: json['command_id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      command: json['command']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      timestamp: json['timestamp'] != null ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

class IoTAlertModel {
  final String id;
  final String deviceId;
  final String zoneId;
  final String type;
  final String message;
  final String severity; // INFO, WARNING, CRITICAL
  final DateTime createdAt;
  DateTime? readAt;
  DateTime? resolvedAt;
  bool get isRead => readAt != null;

  IoTAlertModel({
    required this.id,
    required this.deviceId,
    required this.zoneId,
    required this.type,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.readAt,
    this.resolvedAt,
  });
}
