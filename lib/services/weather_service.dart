import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Holds current weather information.
class WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final double precipitationProbability;
  final int weatherCode;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  String get condition {
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode <= 3) return 'Partly Cloudy';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 67) return 'Rainy';
    if (weatherCode <= 77) return 'Snowy';
    if (weatherCode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
}

/// Daily forecast data.
class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitationProbability;
  final int weatherCode;

  DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  String get condition {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode <= 3) return 'Cloudy';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 67) return 'Rain';
    if (weatherCode <= 77) return 'Snow';
    if (weatherCode <= 99) return 'Storm';
    return '?';
  }

  String get icon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 67) return '🌧️';
    if (weatherCode <= 77) return '❄️';
    if (weatherCode <= 99) return '⛈️';
    return '🌤️';
  }
}

/// Fetches real weather data from the Open-Meteo API (free, no key required).
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Fetch current weather for given coordinates.
  /// Defaults to Bangalore, India (12.97, 77.59) if no coordinates provided.
  Future<WeatherData?> fetchWeather({
    double lat = 12.97,
    double lon = 77.59,
  }) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,wind_speed_10m',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        if (current == null) return null;

        return WeatherData(
          temperature: (current['temperature_2m'] ?? 0).toDouble(),
          humidity: (current['relative_humidity_2m'] ?? 0).toDouble(),
          precipitationProbability: (current['precipitation_probability'] ?? 0)
              .toDouble(),
          weatherCode: current['weather_code'] ?? 0,
          windSpeed: (current['wind_speed_10m'] ?? 0).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('WeatherService.fetchWeather error: $e');
    }
    return null;
  }

  /// Fetch 7-day daily forecast.
  Future<List<DailyForecast>> fetchForecast({
    double lat = 12.97,
    double lon = 77.59,
  }) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code'
      '&forecast_days=7',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daily = data['daily'];
        if (daily == null) return [];

        final dates = List<String>.from(daily['time'] ?? []);
        final tempMax = List.from(daily['temperature_2m_max'] ?? []);
        final tempMin = List.from(daily['temperature_2m_min'] ?? []);
        final precip = List.from(daily['precipitation_probability_max'] ?? []);
        final codes = List.from(daily['weather_code'] ?? []);

        final forecasts = <DailyForecast>[];
        for (int i = 0; i < dates.length && i < 7; i++) {
          forecasts.add(
            DailyForecast(
              date: DateTime.parse(dates[i]),
              tempMax: (tempMax[i] ?? 0).toDouble(),
              tempMin: (tempMin[i] ?? 0).toDouble(),
              precipitationProbability: (precip[i] ?? 0).toDouble(),
              weatherCode: codes[i] ?? 0,
            ),
          );
        }
        return forecasts;
      }
    } catch (e) {
      debugPrint('WeatherService.fetchForecast error: $e');
    }
    return [];
  }
}
