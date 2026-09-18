import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';

import '../../providers/farm_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/iot_provider.dart';
import '../../services/weather_service.dart';
import '../../widgets/add_crop_dialog.dart';
import '../../widgets/add_task_dialog.dart';
import '../../widgets/add_finance_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weather;
  List<DailyForecast> _forecast = [];
  bool _loadingWeather = true;
  String _locationName = "Detecting...";

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() => _loadingWeather = true);

    double lat = 12.97;
    double lon = 77.59;
    String locName = "Bangalore, India";

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 3),
          ),
        );
        lat = position.latitude;
        lon = position.longitude;
        locName = "Current Location"; // Or reverse geocode if desired
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }

    final results = await Future.wait([
      _weatherService.fetchWeather(lat: lat, lon: lon),
      _weatherService.fetchForecast(lat: lat, lon: lon),
    ]);
    if (mounted) {
      setState(() {
        _weather = results[0] as WeatherData?;
        _forecast = results[1] as List<DailyForecast>;
        _locationName = locName;
        _loadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final farm = Provider.of<FarmProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);
    final iot = Provider.of<IoTProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.name ?? "Farmer"} 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (user?.farmName != null)
              Text(
                user!.farmName!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final userId = user?.id;
              if (userId != null) {
                farm.loadData(userId);
                finance.loadData(userId);
                _fetchWeather();
              }
            },
          ),
        ],
      ),
      body: farm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  await Future.wait([
                    farm.loadData(user.id),
                    finance.loadData(user.id),
                  ]);
                  _fetchWeather();
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Error banners
                  if (farm.error != null)
                    _buildErrorBanner(farm.error!, () => farm.clearError()),
                  if (finance.error != null)
                    _buildErrorBanner(
                      finance.error!,
                      () => finance.clearError(),
                    ),

                  // Weather card
                  _buildWeatherCard(theme),
                  const SizedBox(height: 16),

                  // Stats grid
                  _buildStatsGrid(farm, finance, theme),
                  const SizedBox(height: 20),

                  // IoT Sensors Quick View
                  Text(
                    'IoT Sensors',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildIoTSummary(iot),
                  const SizedBox(height: 24),

                  // Quick actions
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(theme),
                  const SizedBox(height: 24),

                  // Recent crops
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Crops',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${farm.crops.length} total',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCropsList(farm),
                  const SizedBox(height: 24),

                  // Pending tasks
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending Tasks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${farm.pendingTaskCount} pending',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTasksList(farm),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorBanner(String message, VoidCallback onDismiss) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(ThemeData theme) {
    if (_loadingWeather) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade50],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
        ),
      );
    }

    if (_weather == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: const Row(
          children: [
            Icon(Icons.cloud_off, size: 32, color: Colors.grey),
            SizedBox(width: 12),
            Text(
              'Weather data unavailable',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    bool isSunny = _weather!.weatherCode <= 2;
    List<Color> gradientColors = isSunny
        ? [const Color(0xFF4CA1AF), const Color(0xFFC4E0E5)]
        : [const Color(0xFF373B44), const Color(0xFF4286f4)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              isSunny ? Icons.wb_sunny : Icons.cloud,
              size: 100,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _locationName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '${_weather!.temperature.round()}°',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _weather!.condition,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Feels like ${_weather!.temperature.round() + 1}°',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _weatherDetailInfo(
                    Icons.water_drop,
                    'Humidity',
                    '${_weather!.humidity.round()}%',
                  ),
                  _weatherDetailInfo(
                    Icons.air,
                    'Wind',
                    '${_weather!.windSpeed.round()} km/h',
                  ),
                  _weatherDetailInfo(
                    Icons.umbrella,
                    'Rain',
                    '${_weather!.precipitationProbability.round()}%',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherDetailInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  List<double> _computeCumulativeDates(List<String> dates) {
    if (dates.isEmpty) return [];
    final parsed = dates
        .map((d) => DateTime.tryParse(d))
        .whereType<DateTime>()
        .toList();
    if (parsed.isEmpty) return [];
    parsed.sort();
    List<double> counts = [];
    double current = 0;
    for (int i = 0; i < parsed.length; i++) {
      current += 1;
      counts.add(current);
    }
    // ensure at least 2 points for a line
    if (counts.length == 1) {
      counts.add(counts.first);
    }
    return counts;
  }

  List<double> _computeProfitHistory(FinanceProvider finance) {
    final allTx = <Map<String, dynamic>>[];
    for (final e in finance.expenses) {
      allTx.add({'date': e.date, 'amount': -e.amount});
    }
    for (final s in finance.sales) {
      allTx.add({'date': s.date, 'amount': (s.price * s.quantity)});
    }
    if (allTx.isEmpty) return [];
    allTx.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    List<double> profit = [];
    double current = 0;
    for (final tx in allTx) {
      current += (tx['amount'] as double);
      profit.add(current);
    }
    if (profit.length == 1) {
      profit.add(profit.first);
    }
    return profit;
  }

  Widget _buildStatsGrid(
    FarmProvider farm,
    FinanceProvider finance,
    ThemeData theme,
  ) {
    final cropsHistory = _computeCumulativeDates(
      farm.crops.map((c) => c.sowingDate).whereType<String>().toList(),
    );
    final activeCropsHistory = _computeCumulativeDates(
      farm.crops
          .where((c) => c.status == 'Active')
          .map((c) => c.sowingDate)
          .whereType<String>()
          .toList(),
    );
    final tasksHistory = _computeCumulativeDates(
      farm.tasks.map((t) => t.date).toList(),
    );
    final profitHistory = _computeProfitHistory(finance);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          'Total Crops',
          '${farm.crops.length}',
          Icons.grass,
          const Color(0xFF2E7D32),
          cropsHistory,
        ),
        _buildStatCard(
          'Active',
          '${farm.activeCropCount}',
          Icons.eco,
          const Color(0xFF66BB6A),
          activeCropsHistory,
        ),
        _buildStatCard(
          'Tasks',
          '${farm.pendingTaskCount}',
          Icons.task_alt,
          Colors.orange,
          tasksHistory,
        ),
        _buildStatCard(
          'Profit',
          '\$${finance.profit.toStringAsFixed(0)}',
          finance.profit >= 0 ? Icons.trending_up : Icons.trending_down,
          finance.profit >= 0 ? Colors.green : Colors.red,
          profitHistory,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    List<double> sparklineData,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sparklineData.isEmpty
                          ? [const FlSpot(0, 0), const FlSpot(1, 0)]
                          : sparklineData
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                      isCurved: true,
                      color: color.withValues(alpha: 0.5),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        _buildActionChip(
          'Add Crop',
          Icons.add_circle_outline,
          const Color(0xFF2E7D32),
          onTap: () => AddCropDialog.show(context),
        ),
        const SizedBox(width: 8),
        _buildActionChip(
          'Add Task',
          Icons.playlist_add,
          Colors.orange,
          onTap: () => AddTaskDialog.show(context),
        ),
        const SizedBox(width: 8),
        _buildActionChip(
          'Log Expense',
          Icons.receipt_long,
          Colors.red,
          onTap: () => AddFinanceDialog.show(context),
        ),
      ],
    );
  }

  Widget _buildActionChip(
    String label,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropsList(FarmProvider farm) {
    if (farm.crops.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.grass, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  'No crops added yet',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final displayCrops = farm.crops.take(3).toList();
    return Column(
      children: displayCrops.map((crop) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: crop.status == 'Active'
                  ? Colors.green.shade100
                  : Colors.grey.shade200,
              child: Icon(
                Icons.grass,
                color: crop.status == 'Active' ? Colors.green : Colors.grey,
              ),
            ),
            title: Text(
              crop.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${crop.growthStage ?? "Unknown stage"} • ${crop.area ?? 0} acres',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (crop.notes != null && crop.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notes: ${crop.notes}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: crop.status == 'Active'
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                crop.status,
                style: TextStyle(
                  fontSize: 11,
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
    final pending = farm.tasks
        .where((t) => t.status == 'Pending')
        .take(3)
        .toList();

    if (pending.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.task_alt, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  'All caught up!',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: priorityColor.withValues(alpha: 0.1),
              child: Icon(Icons.flag, color: priorityColor, size: 20),
            ),
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              task.date,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.priority,
                style: TextStyle(
                  fontSize: 11,
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

  Widget _buildIoTSummary(IoTProvider iot) {
    final sensorsList = iot.sensors;
    if (sensorsList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No sensors connected',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sensorsList.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final s = sensorsList[i];
          final reading = s.lastReading ?? 0;
          Color color;
          IconData icon;

          switch (s.type) {
            case 'moisture_sensor':
              icon = Icons.water_drop;
              color = reading < 30
                  ? Colors.red
                  : reading < 50
                  ? Colors.orange
                  : Colors.blue;
              break;
            case 'temp_sensor':
              icon = Icons.thermostat;
              color = reading > 35 ? Colors.red : Colors.green;
              break;
            default:
              icon = Icons.cloud;
              color = Colors.teal;
          }

          return Card(
            color: color.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        '${reading.toStringAsFixed(1)}${s.unit ?? ""}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.name.split(' - ').last,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
