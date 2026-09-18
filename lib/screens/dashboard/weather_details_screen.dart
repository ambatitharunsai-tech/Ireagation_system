import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/weather_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/weather_service.dart';

class WeatherDetailsScreen extends StatelessWidget {
  const WeatherDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherProv = Provider.of<WeatherProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final current = weatherProv.currentWeather;
    final forecast = weatherProv.forecast;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('Weather Forecast')),
      ),
      body: weatherProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : current == null
              ? Center(child: Text(lang.t('Weather data unavailable.')))
              : RefreshIndicator(
                  onRefresh: weatherProv.fetchWeather,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(current, lang),
                      const SizedBox(height: 24),
                      Text(
                        lang.t('7-Day Forecast'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...forecast.map((f) => _buildForecastDay(context, f, lang)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(WeatherData current, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                current.locationName ?? lang.t('Unknown Location'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            current.temperature != null ? '${current.temperature}°C' : lang.t('No data'),
            style: const TextStyle(
              fontSize: 64,
              color: Colors.white,
              fontWeight: FontWeight.w300,
            ),
          ),
          Text(
            lang.t(current.condition),
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem(Icons.water_drop, '${current.humidity ?? "--"}%', lang.t('Humidity')),
              _buildDetailItem(Icons.air, '${current.windSpeed ?? "--"} km/h', lang.t('Wind')),
              _buildDetailItem(Icons.beach_access, '${current.precipitationProbability ?? "--"}%', lang.t('Rain Prob')),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${current.isCached ? lang.t("CACHED") : lang.t("LIVE")} • ${lang.t("Updated")} ${DateFormat.jm().format(current.timestamp)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
      ],
    );
  }

  Widget _buildForecastDay(BuildContext context, DailyForecast forecast, LanguageProvider lang) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Text(forecast.icon, style: const TextStyle(fontSize: 28)),
        title: Text(
          DateFormat('EEEE, MMM d').format(forecast.date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(lang.t(forecast.condition)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${forecast.tempMax ?? "--"}°', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${forecast.tempMin ?? "--"}°', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildForecastDetail(Icons.water_drop, lang.t('Rain Prob'), '${forecast.precipitationProbability ?? "--"}%'),
                _buildForecastDetail(Icons.thermostat, lang.t('Max Temp'), '${forecast.tempMax ?? "--"}°C'),
                _buildForecastDetail(Icons.thermostat_outlined, lang.t('Min Temp'), '${forecast.tempMin ?? "--"}°C'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildForecastDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
