import 'package:flutter_test/flutter_test.dart';
import 'package:ireagation_system/services/irrigation_engine.dart';
import 'package:ireagation_system/models/iot_models.dart';
import 'package:ireagation_system/services/weather_service.dart';

void main() {
  group('IrrigationEngine Tests', () {
    test('evaluate returns true when moisture is below threshold', () {
      final engine = IrrigationEngine();
      
      final sensors = [
        IoTDevice(id: 's1', farmId: 'f1', zoneId: 'z1', name: 'Sensor 1', deviceType: 'soil_moisture', isOnline: true)
          ..latestTelemetry = TelemetryReading(deviceId: 's1', timestamp: DateTime.now(), receivedAt: DateTime.now(), soilMoisture: 25.0)
      ];

      final decision = engine.evaluate(
        devices: sensors,
        weather: null,
        moistureThreshold: 30.0,
        isAutoMode: true,
      );

      expect(decision.shouldIrrigate, true);
    });

    test('evaluate returns false if weather predicts high rain', () {
      final engine = IrrigationEngine();

      final sensors = [
        IoTDevice(id: 's1', farmId: 'f1', zoneId: 'z1', name: 'Sensor 1', deviceType: 'soil_moisture', isOnline: true)
          ..latestTelemetry = TelemetryReading(deviceId: 's1', timestamp: DateTime.now(), receivedAt: DateTime.now(), soilMoisture: 25.0)
      ];

      final mockWeather = WeatherData(
        temperature: 20,
        humidity: 80,
        windSpeed: 10,
        precipitationProbability: 80,
        timestamp: DateTime.now(),
      );

      final decision = engine.evaluate(
        devices: sensors,
        weather: mockWeather,
        moistureThreshold: 30.0,
        isAutoMode: true,
      );

      expect(decision.shouldIrrigate, false);
      expect(decision.reason, 'High rain probability');
    });
  });
}
