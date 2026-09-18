import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        locName = "Current Location";
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.name ?? "Farmer"} 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            if (user?.farmName != null)
              Text(
                user!.farmName!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, size: 20, color: Colors.black87),
            ),
            onPressed: () {
              final userId = user?.id;
              if (userId != null) {
                farm.loadData(userId);
                finance.loadData(userId);
                _fetchWeather();
              }
            },
          ),
          const SizedBox(width: 8),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  if (farm.error != null)
                    _buildErrorBanner(farm.error!, () => farm.clearError()),
                  if (finance.error != null)
                    _buildErrorBanner(
                      finance.error!,
                      () => finance.clearError(),
                    ),

                  _buildWeatherCard(theme),
                  const SizedBox(height: 24),

                  _buildStatsGrid(farm, finance, theme),
                  const SizedBox(height: 24),

                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(theme),
                  const SizedBox(height: 24),

                  Text(
                    'IoT Sensors',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildIoTSummary(iot),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Crops',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '${farm.crops.length} total',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCropsList(farm),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending Tasks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '${farm.pendingTaskCount} pending',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTasksList(farm),
                  const SizedBox(height: 24),
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

  Widget _buildWeatherCard(ThemeData theme) {
    if (_loadingWeather) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade100],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (_weather == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 32, color: Colors.grey),
              SizedBox(width: 12),
              Text(
                'Weather data unavailable',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    bool isSunny = _weather!.weatherCode <= 2;
    List<Color> gradientColors = isSunny
        ? [const Color(0xFF56CCF2), const Color(0xFF2F80ED)]
        : [const Color(0xFF4B79A1), const Color(0xFF283E51)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              isSunny ? Icons.wb_sunny : Icons.cloud,
              size: 140,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _locationName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_weather!.temperature.round()}°',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _weather!.condition,
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Feels like ${_weather!.temperature.round() + 1}°',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _weatherDetailInfo(
                    Icons.water_drop_outlined,
                    'Humidity',
                    '${_weather!.humidity.round()}%',
                  ),
                  _weatherDetailInfo(
                    Icons.air,
                    'Wind',
                    '${_weather!.windSpeed.round()} km/h',
                  ),
                  _weatherDetailInfo(
                    Icons.umbrella_outlined,
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
        Icon(icon, size: 22, color: Colors.white),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    FarmProvider farm,
    FinanceProvider finance,
    ThemeData theme,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        _buildRichStatCard(
          title: 'Total Crops',
          value: '${farm.crops.length}',
          subtitle: '${farm.activeCropCount} active',
          icon: Icons.grass,
          color: Colors.green,
          progress: farm.crops.isEmpty
              ? 0
              : farm.activeCropCount / farm.crops.length,
        ),
        _buildRichStatCard(
          title: 'Active Tasks',
          value: '${farm.pendingTaskCount}',
          subtitle: '${farm.tasks.length} total tasks',
          icon: Icons.task_alt,
          color: Colors.orange,
          progress: farm.tasks.isEmpty
              ? 0
              : farm.pendingTaskCount / farm.tasks.length,
        ),
        _buildRichStatCard(
          title: 'Net Profit',
          value: '\$${finance.profit.toStringAsFixed(0)}',
          subtitle: 'Revenue - Expenses',
          icon: finance.profit >= 0 ? Icons.trending_up : Icons.trending_down,
          color: finance.profit >= 0 ? Colors.teal : Colors.red,
          progress: finance.totalRevenue == 0
              ? (finance.profit < 0 ? 1 : 0)
              : (finance.profit / finance.totalRevenue).clamp(0.0, 1.0),
        ),
        _buildRichStatCard(
          title: 'Total Revenue',
          value: '\$${finance.totalRevenue.toStringAsFixed(0)}',
          subtitle: '\$${finance.totalExpenses.toStringAsFixed(0)} exp',
          icon: Icons.account_balance_wallet,
          color: Colors.blue,
          progress: (finance.totalRevenue + finance.totalExpenses) == 0
              ? 0
              : finance.totalRevenue /
                    (finance.totalRevenue + finance.totalExpenses),
        ),
      ],
    );
  }

  Widget _buildRichStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(Icons.more_horiz, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        _buildActionChip(
          'Add Crop',
          Icons.add_circle_outline,
          Colors.green,
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
          'Add Expense',
          Icons.money_off,
          Colors.red,
          onTap: () => AddFinanceDialog.show(context),
        ),
        const SizedBox(width: 8),
        _buildActionChip(
          'Add Sale',
          Icons.sell,
          Colors.blue,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () {},
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCropsList(FarmProvider farm) {
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
                'No crops added yet',
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
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                    '${crop.growthStage ?? "Unknown stage"} • ${crop.area ?? 0} acres',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (crop.notes != null && crop.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Notes: ${crop.notes}',
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
                crop.status,
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
                'All caught up!',
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
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                task.priority,
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

  Widget _buildIoTSummary(IoTProvider iot) {
    final sensorsList = iot.sensors;
    if (sensorsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            'No sensors connected',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sensorsList.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 12),
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

          return Container(
            width: 140,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 8),
                    Text(
                      '${reading.toStringAsFixed(1)}${s.unit ?? ""}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.name.split(' - ').last,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
