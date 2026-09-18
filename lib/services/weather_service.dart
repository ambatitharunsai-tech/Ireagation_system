import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherData {
  final double? temperature;
  final double? humidity;
  final double? windSpeed;
  final double? precipitationProbability;
  final int? weatherCode;
  final String? locationName;
  final DateTime timestamp;
  final bool isCached;

  WeatherData({
    this.temperature,
    this.humidity,
    this.windSpeed,
    this.precipitationProbability,
    this.weatherCode,
    this.locationName,
    required this.timestamp,
    this.isCached = false,
  });

  String get condition {
    if (weatherCode == null) return 'Unknown';
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode! <= 3) return 'Partly Cloudy';
    if (weatherCode! <= 48) return 'Foggy';
    if (weatherCode! <= 67) return 'Rainy';
    if (weatherCode! <= 77) return 'Snowy';
    if (weatherCode! <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'precipitationProbability': precipitationProbability,
    'weatherCode': weatherCode,
    'locationName': locationName,
    'timestamp': timestamp.toIso8601String(),
    'isCached': isCached,
  };

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
    temperature: json['temperature']?.toDouble(),
    humidity: json['humidity']?.toDouble(),
    windSpeed: json['windSpeed']?.toDouble(),
    precipitationProbability: json['precipitationProbability']?.toDouble(),
    weatherCode: json['weatherCode'],
    locationName: json['locationName'],
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'])
        : DateTime.now(),
    isCached: json['isCached'] ?? true,
  );
}

class DailyForecast {
  final DateTime date;
  final double? tempMax;
  final double? tempMin;
  final double? precipitationProbability;
  final int? weatherCode;

  DailyForecast({
    required this.date,
    this.tempMax,
    this.tempMin,
    this.precipitationProbability,
    this.weatherCode,
  });

  String get condition {
    if (weatherCode == null) return 'Unknown';
    if (weatherCode == 0) return 'Clear';
    if (weatherCode! <= 3) return 'Cloudy';
    if (weatherCode! <= 48) return 'Foggy';
    if (weatherCode! <= 67) return 'Rain';
    if (weatherCode! <= 77) return 'Snow';
    if (weatherCode! <= 99) return 'Storm';
    return '?';
  }

  String get icon {
    if (weatherCode == null) return '❓';
    if (weatherCode == 0) return '☀️';
    if (weatherCode! <= 3) return '⛅';
    if (weatherCode! <= 48) return '🌫️';
    if (weatherCode! <= 67) return '🌧️';
    if (weatherCode! <= 77) return '❄️';
    if (weatherCode! <= 99) return '⛈️';
    return '🌤️';
  }
}

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _cacheKey = 'weather_cache';
  static const String _cacheTimeKey = 'weather_cache_time';
  static const String _forecastCacheKey = 'forecast_cache';

  Future<WeatherData?> fetchWeather(
    double lat,
    double lon,
    String locationName,
  ) async {
    final prefs = await SharedPreferences.getInstance();

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
          temperature: current['temperature_2m']?.toDouble(),
          humidity: current['relative_humidity_2m']?.toDouble(),
          precipitationProbability: current['precipitation_probability']
              ?.toDouble(),
          weatherCode: current['weather_code'],
          windSpeed: current['wind_speed_10m']?.toDouble(),
          locationName: locationName,
          timestamp: DateTime.now(),
          isCached: false,
        );

        await prefs.setString(_cacheKey, json.encode(weather.toJson()));
        await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());

        return weather;
      }
    } catch (e) {
      debugPrint('WeatherService.fetchWeather error: $e');
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        final w = WeatherData.fromJson(json.decode(cachedData));
        return WeatherData(
          temperature: w.temperature,
          humidity: w.humidity,
          windSpeed: w.windSpeed,
          precipitationProbability: w.precipitationProbability,
          weatherCode: w.weatherCode,
          locationName: w.locationName,
          timestamp: w.timestamp,
          isCached: true,
        );
      }
    }
    return null;
  }

  Future<List<DailyForecast>> fetchForecast(double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code'
      '&forecast_days=7',
    );

    final prefs = await SharedPreferences.getInstance();

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
              tempMax: tempMax.length > i && tempMax[i] != null
                  ? tempMax[i].toDouble()
                  : null,
              tempMin: tempMin.length > i && tempMin[i] != null
                  ? tempMin[i].toDouble()
                  : null,
              precipitationProbability: precip.length > i && precip[i] != null
                  ? precip[i].toDouble()
                  : null,
              weatherCode: codes.length > i ? codes[i] : null,
            ),
          );
        }

        await prefs.setString(
          _forecastCacheKey,
          json.encode(
            forecasts
                .map(
                  (f) => {
                    'date': f.date.toIso8601String(),
                    'tempMax': f.tempMax,
                    'tempMin': f.tempMin,
                    'precipitationProbability': f.precipitationProbability,
                    'weatherCode': f.weatherCode,
                  },
                )
                .toList(),
          ),
        );

        return forecasts;
      }
    } catch (e) {
      debugPrint('WeatherService.fetchForecast error: $e');
      final cachedStr = prefs.getString(_forecastCacheKey);
      if (cachedStr != null) {
        final List<dynamic> decoded = json.decode(cachedStr);
        return decoded
            .map(
              (j) => DailyForecast(
                date: DateTime.parse(j['date']),
                tempMax: j['tempMax']?.toDouble(),
                tempMin: j['tempMin']?.toDouble(),
                precipitationProbability: j['precipitationProbability']
                    ?.toDouble(),
                weatherCode: j['weatherCode'],
              ),
            )
            .toList();
      }
    }
    return [];
  }
}
