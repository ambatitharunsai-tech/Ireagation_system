import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/iot_service.dart';

/// Data access object for IoT devices and sensor readings in Supabase.
class IoTDao {
  final SupabaseClient _client = Supabase.instance.client;

  /// Upsert all devices for a user.
  Future<void> saveDevices(String userId, List<IoTDevice> devices) async {
    try {
      final rows = devices
          .map(
            (d) => {
              'id': d.id,
              'user_id': userId,
              'name': d.name,
              'type': d.type,
              'is_online': d.isOnline,
              'is_active': d.isActive,
              'last_reading': d.lastReading,
              'unit': d.unit,
              'updated_at': DateTime.now().toIso8601String(),
            },
          )
          .toList();

      await _client.from('iot_devices').upsert(rows);
    } catch (e) {
      debugPrint('IoTDao.saveDevices error: $e');
    }
  }

  /// Load devices for a user.
  Future<List<IoTDevice>> getDevices(String userId) async {
    try {
      final response = await _client
          .from('iot_devices')
          .select()
          .eq('user_id', userId);

      return response
          .map(
            (map) => IoTDevice(
              id: map['id'] ?? '',
              name: map['name'] ?? '',
              type: map['type'] ?? '',
              isOnline: map['is_online'] ?? true,
              isActive: map['is_active'] ?? false,
              lastReading: map['last_reading'] != null
                  ? (map['last_reading'] as num).toDouble()
                  : null,
              unit: map['unit'],
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('IoTDao.getDevices error: $e');
      return [];
    }
  }

  /// Save a sensor reading.
  Future<void> saveSensorReading(
    String deviceId,
    String userId,
    double value,
  ) async {
    try {
      await _client.from('sensor_readings').insert({
        'device_id': deviceId,
        'user_id': userId,
        'value': value,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('IoTDao.saveSensorReading error: $e');
    }
  }

  /// Get sensor reading history.
  Future<List<SensorReading>> getSensorHistory(
    String deviceId, {
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('sensor_readings')
          .select()
          .eq('device_id', deviceId)
          .order('recorded_at', ascending: false)
          .limit(limit);

      return response
          .map(
            (map) => SensorReading(
              timestamp: DateTime.parse(map['recorded_at']),
              value: (map['value'] as num).toDouble(),
            ),
          )
          .toList()
          .reversed
          .toList();
    } catch (e) {
      debugPrint('IoTDao.getSensorHistory error: $e');
      return [];
    }
  }

  /// Save an AI recommendation.
  Future<void> saveRecommendation(
    String userId,
    String recommendation, {
    String? deviceId,
  }) async {
    try {
      await _client.from('ai_recommendations').insert({
        'user_id': userId,
        'device_id': deviceId,
        'recommendation': recommendation,
      });
    } catch (e) {
      debugPrint('IoTDao.saveRecommendation error: $e');
    }
  }

  /// Get AI recommendation history.
  Future<List<Map<String, dynamic>>> getRecommendations(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from('ai_recommendations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('IoTDao.getRecommendations error: $e');
      return [];
    }
  }
}
