import 'package:flutter_test/flutter_test.dart';
import 'package:ireagation_system/services/irrigation_engine.dart';
import 'package:ireagation_system/services/weather_service.dart';
import 'package:ireagation_system/services/iot_service.dart';

void main() {
  group('IrrigationEngine', () {
    test(
      'should activate pump when moisture is below threshold and no rain',
      () {
        final engine = IrrigationEngine();
        final weather = WeatherData(
          temperature: 30,
          humidity: 40,
          windSpeed: 10,
          precipitationProbability: 10,
          weatherCode: 0,
timestamp: DateTime.now(),
isCached: false,
        );
        final devices = [
          IoTDevice(
            id: '1',
            name: 'Sensor',
            type: 'moisture',
            lastReading: 25.0,
          ),
        ];

        final decision = engine.evaluate(
          devices: devices,
          moistureThreshold: 30.0,
          isAutoMode: true,
          weather: weather,
        );

        expect(decision.shouldIrrigate, isTrue);
        expect(decision.reason, contains('Moisture below threshold'));
      },
    );

    test('should NOT activate pump when rain is highly probable', () {
      final engine = IrrigationEngine();
      final weather = WeatherData(
        temperature: 30,
        humidity: 40,
        windSpeed: 10,
        precipitationProbability: 70, // High rain prob
        weatherCode: 65,
timestamp: DateTime.now(),
isCached: false, // Rainy
      );
      final devices = [
        IoTDevice(id: '1', name: 'Sensor', type: 'moisture', lastReading: 25.0),
      ];

      final decision = engine.evaluate(
        devices: devices,
        moistureThreshold: 30.0,
        isAutoMode: true,
        weather: weather,
      );

      expect(decision.shouldIrrigate, isFalse);
      expect(decision.reason, contains('High rain probability'));
    });
  });
}
