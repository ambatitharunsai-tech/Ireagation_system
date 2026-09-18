import 'package:flutter/foundation.dart';

import '../services/weather_service.dart';
import '../services/location_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  WeatherData? _currentWeather;
  List<DailyForecast> _forecast = [];
  bool _isLoading = false;
  String? _error;
  LocationData? _lastLocation;

  WeatherData? get currentWeather => _currentWeather;
  List<DailyForecast> get forecast => _forecast;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LocationData? get lastLocation => _lastLocation;

  Future<void> fetchWeather() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        _error = "Location unavailable. Please enable GPS.";
        _currentWeather = null;
        _forecast = [];
      } else {
        _lastLocation = location;
        _currentWeather = await _weatherService.fetchWeather(
          location.latitude,
          location.longitude,
          location.locationName,
        );
        _forecast = await _weatherService.fetchForecast(
          location.latitude,
          location.longitude,
        );
      }
    } catch (e) {
      _error = "Failed to load weather: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
