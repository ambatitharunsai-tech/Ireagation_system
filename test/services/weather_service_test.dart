import 'package:flutter_test/flutter_test.dart';
import 'package:ireagation_system/services/weather_service.dart';

void main() {
  group('WeatherService', () {
    test('WeatherData.fromJson parses valid data correctly', () {
      final json = {
        'temperature': 30.5,
        'humidity': 50.0,
        'windSpeed': 10.0,
        'precipitationProbability': 20.0,
        'weatherCode': 1,
        'locationName': 'New York',
        'timestamp': '2023-01-01T10:00:00Z',
        'isCached': false,
      };

      final data = WeatherData.fromJson(json);
      expect(data.temperature, 30.5);
      expect(data.humidity, 50.0);
      expect(data.windSpeed, 10.0);
      expect(data.precipitationProbability, 20.0);
      expect(data.weatherCode, 1);
      expect(data.locationName, 'New York');
      expect(data.condition, 'Partly Cloudy');
      expect(data.isCached, false);
    });

    test('WeatherData.fromJson handles missing fields without defaulting to 0', () {
      final json = {
        'timestamp': '2023-01-01T10:00:00Z',
      };

      final data = WeatherData.fromJson(json);
      expect(data.temperature, isNull);
      expect(data.humidity, isNull);
      expect(data.windSpeed, isNull);
      expect(data.precipitationProbability, isNull);
      expect(data.weatherCode, isNull);
      expect(data.locationName, isNull);
      expect(data.condition, 'Unknown');
    });
  });

  group('DailyForecast', () {
    test('DailyForecast handles missing fields without defaulting to 0', () {
      final forecast = DailyForecast(
        date: DateTime.now(),
      );
      
      expect(forecast.tempMax, isNull);
      expect(forecast.tempMin, isNull);
      expect(forecast.precipitationProbability, isNull);
      expect(forecast.weatherCode, isNull);
      expect(forecast.condition, 'Unknown');
      expect(forecast.icon, '❓');
    });
  });
}
