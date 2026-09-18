import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/farm_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/iot_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/add_crop_dialog.dart';
import '../../widgets/add_task_dialog.dart';
import '../../widgets/add_finance_dialog.dart';
import 'weather_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(context, listen: false).fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final farm = Provider.of<FarmProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);
    final iot = Provider.of<IoTProvider>(context);
    final weatherProv = Provider.of<WeatherProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);

    final userName = auth.currentUser?.name ?? lang.t('Farmer');

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${lang.t("Hello")}, $userName 👋',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (weatherProv.lastLocation != null)
              Text(
                '📍 ${weatherProv.lastLocation!.locationName}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              farm.loadData(auth.currentUser!.id);
              finance.loadData(auth.currentUser!.id);
              weatherProv.fetchWeather();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (auth.currentUser != null) {
            await Future.wait([
              farm.loadData(auth.currentUser!.id),
              finance.loadData(auth.currentUser!.id),
              weatherProv.fetchWeather(),
            ]);
          }
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (farm.error != null)
              _buildErrorBanner(farm.error!, () => farm.clearError()),

            _buildWeatherCard(weatherProv, lang, context),
            const SizedBox(height: 24),

            _buildFarmHealth(iot, weatherProv, lang),
            const SizedBox(height: 24),

            _buildIrrigationOverview(iot, lang),
            const SizedBox(height: 24),

            _buildWaterManagement(iot, lang),
            const SizedBox(height: 24),

            _buildAlerts(iot, lang),
            const SizedBox(height: 24),

            _buildSectionTitle(lang.t('Quick Actions')),
            const SizedBox(height: 12),
            _buildQuickActions(Theme.of(context)),
            const SizedBox(height: 24),

            _buildSectionTitle(lang.t('Crops Overview')),
            const SizedBox(height: 12),
            _buildCropsList(farm),
            const SizedBox(height: 24),

            _buildSectionTitle(lang.t('Pending Tasks')),
            const SizedBox(height: 12),
            _buildTasksList(farm),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildWeatherCard(
    WeatherProvider wp,
    LanguageProvider lang,
    BuildContext context,
  ) {
    final weather = wp.currentWeather;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WeatherDetailsScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: wp.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : weather == null
            ? Center(
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      lang.t(
                        wp.error ?? 'Weather unavailable\nSet farm location or enable GPS',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weather.temperature != null
                                ? '${weather.temperature}°C'
                                : lang.t('No data'),
                            style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            lang.t(weather.condition),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.wb_sunny, color: Colors.amber, size: 64),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeatherDetail(
                        Icons.water_drop,
                        '${weather.humidity ?? "--"}%',
                        lang.t('Humidity'),
                      ),
                      _buildWeatherDetail(
                        Icons.air,
                        '${weather.windSpeed ?? "--"} km/h',
                        lang.t('Wind'),
                      ),
                      _buildWeatherDetail(
                        Icons.beach_access,
                        '${weather.precipitationProbability ?? "--"}%',
                        lang.t('Rain'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${weather.isCached ? lang.t("CACHED") : lang.t("LIVE")} • ${lang.t("Updated")} ${DateFormat.jm().format(weather.timestamp)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFarmHealth(
    IoTProvider iot,
    WeatherProvider wp,
    LanguageProvider lang,
  ) {
    String status = 'UNKNOWN';
    Color color = Colors.grey;
    String message = 'Insufficient data';

    if (iot.sensors.isNotEmpty) {
      bool anyOffline = iot.sensors.any((s) => !s.isOnline);
      bool extremeWeather = false;
      if (wp.currentWeather != null) {
        if ((wp.currentWeather!.temperature ?? 25) > 40 ||
            (wp.currentWeather!.temperature ?? 25) < 0) {
          extremeWeather = true;
        }
      }

      if (anyOffline) {
        status = 'ATTENTION REQUIRED';
        color = Colors.orange;
        message = 'Some sensors are offline';
      } else if (extremeWeather) {
        status = 'CRITICAL';
        color = Colors.red;
        message = 'Extreme weather conditions detected';
      } else {
        status = 'GOOD';
        color = Colors.green;
        message = 'All systems nominal';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('Farm Health'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  lang.t(status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  lang.t(message),
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIrrigationOverview(IoTProvider iot, LanguageProvider lang) {
    final actuators = iot.actuators;
    final pump = actuators.isNotEmpty ? actuators.first : null;

    final moistureSensors = iot.sensors.where(
      (s) => s.deviceType == 'moisture_sensor',
    );
    String moisture = lang.t('No data');
    if (moistureSensors.isNotEmpty &&
        moistureSensors.first.latestTelemetry?.soilMoisture != null) {
      moisture =
          '${moistureSensors.first.latestTelemetry?.soilMoisture!.toStringAsFixed(1)}%';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(lang.t('Irrigation Overview')),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.t('Mode:'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    iot.autoIrrigation ? lang.t('Auto') : lang.t('Manual'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.t('Soil Moisture:'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    moisture,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.t('Pump State:'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    pump == null
                        ? lang.t('UNKNOWN')
                        : (!pump.isOnline
                              ? lang.t('OFFLINE')
                              : ((pump.currentPumpState == 'ON' ||
                                        pump.currentValveState == 'ON')
                                    ? lang.t('ON')
                                    : lang.t('OFF'))),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: pump == null
                          ? Colors.grey
                          : (!pump.isOnline
                                ? Colors.orange
                                : ((pump.currentPumpState == 'ON' ||
                                          pump.currentValveState == 'ON')
                                      ? Colors.green
                                      : Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaterManagement(IoTProvider iot, LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(lang.t('Water Management')),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWaterStat(
                lang.t('Tank Level'),
                lang.t('No data'),
                Icons.opacity,
              ),
              _buildWaterStat(
                lang.t("Today's Usage"),
                lang.t('No data'),
                Icons.water,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaterStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAlerts(IoTProvider iot, LanguageProvider lang) {
    if (iot.alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(lang.t('Alerts')),
        const SizedBox(height: 12),
        ...iot.alerts.take(3).map((alert) {
          final color = alert.severity == 'CRITICAL'
              ? Colors.red
              : Colors.orange;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              leading: Icon(Icons.warning_amber_rounded, color: color),
              title: Text(
                lang.t(alert.message),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color.shade700,
                ),
              ),
              subtitle: Text(
                DateFormat.jm().format(alert.createdAt),
                style: TextStyle(fontSize: 12, color: color.shade600),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildErrorBanner(String message, VoidCallback onDismiss) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onDismiss,
            color: Colors.red.shade700,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    final lang = Provider.of<LanguageProvider>(context);
    return Row(
      children: [
        Expanded(
          child: _buildActionChip(
            lang.t('Add Crop'),
            Icons.add_circle_outline,
            Colors.green,
            onTap: () => AddCropDialog.show(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionChip(
            lang.t('Add Task'),
            Icons.playlist_add,
            Colors.orange,
            onTap: () => AddTaskDialog.show(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionChip(
            lang.t('Add Expense'),
            Icons.money_off,
            Colors.red,
            onTap: () => AddFinanceDialog.show(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionChip(
            lang.t('Add Sale'),
            Icons.sell,
            Colors.blue,
            onTap: () => AddFinanceDialog.show(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCropsList(FarmProvider farm) {
    final lang = Provider.of<LanguageProvider>(context);
    if (farm.crops.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.grass, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                lang.t('No crops added yet'),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayCrops = farm.crops.take(3).toList();
    return Column(
      children: displayCrops.map((crop) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: crop.status == 'Active'
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              child: Icon(
                Icons.grass,
                color: crop.status == 'Active' ? Colors.green : Colors.grey,
              ),
            ),
            title: Text(
              crop.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${crop.growthStage ?? lang.t("Unknown stage")} • ${crop.area ?? 0} ${lang.t("acres")}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (crop.notes != null && crop.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${lang.t("Notes")}: ${crop.notes}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: crop.status == 'Active'
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                lang.t(crop.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: crop.status == 'Active' ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTasksList(FarmProvider farm) {
    final lang = Provider.of<LanguageProvider>(context);
    final pending = farm.tasks
        .where((t) => t.status == 'Pending')
        .take(3)
        .toList();

    if (pending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.task_alt, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                lang.t('All caught up!'),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: pending.map((task) {
        final priorityColor = task.priority == 'High'
            ? Colors.red
            : task.priority == 'Medium'
            ? Colors.orange
            : Colors.green;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: priorityColor.withValues(alpha: 0.1),
              child: Icon(Icons.flag, color: priorityColor, size: 20),
            ),
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                task.date,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                lang.t(task.priority),
                style: TextStyle(
                  fontSize: 12,
                  color: priorityColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionChip(
    String label,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
