import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'precipitationProbability': precipitationProbability,
    'weatherCode': weatherCode,
  };

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
    temperature: json['temperature']?.toDouble() ?? 0.0,
    humidity: json['humidity']?.toDouble() ?? 0.0,
    windSpeed: json['windSpeed']?.toDouble() ?? 0.0,
    precipitationProbability:
        json['precipitationProbability']?.toDouble() ?? 0.0,
    weatherCode: json['weatherCode'] ?? 0,
  );
}

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

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _cacheKey = 'weather_cache';
  static const String _cacheTimeKey = 'weather_cache_time';
  static const int _cacheDurationMinutes = 30;

  Future<WeatherData?> fetchWeather({
    double lat = 12.97,
    double lon = 77.59,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Check cache
    final cacheTime = prefs.getString(_cacheTimeKey);
    if (cacheTime != null) {
      final lastFetch = DateTime.parse(cacheTime);
      if (DateTime.now().difference(lastFetch).inMinutes <
          _cacheDurationMinutes) {
        final cachedData = prefs.getString(_cacheKey);
        if (cachedData != null) {
          return WeatherData.fromJson(json.decode(cachedData));
        }
      }
    }

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

        final weather = WeatherData(
          temperature: (current['temperature_2m'] ?? 0).toDouble(),
          humidity: (current['relative_humidity_2m'] ?? 0).toDouble(),
          precipitationProbability: (current['precipitation_probability'] ?? 0)
              .toDouble(),
          weatherCode: current['weather_code'] ?? 0,
          windSpeed: (current['wind_speed_10m'] ?? 0).toDouble(),
        );

        // Update cache
        await prefs.setString(_cacheKey, json.encode(weather.toJson()));
        await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());

        return weather;
      }
    } catch (e) {
      debugPrint('WeatherService.fetchWeather error: $e');
      // On network error, try to return cached data even if expired
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        return WeatherData.fromJson(json.decode(cachedData));
      }
    }
    return null;
  }

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
