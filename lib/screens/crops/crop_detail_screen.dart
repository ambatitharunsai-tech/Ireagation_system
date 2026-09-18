import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/farm_provider.dart';
import '../../providers/iot_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/language_provider.dart';
import '../../database/daos/crop_dao.dart';
import '../../widgets/add_crop_dialog.dart';

class CropDetailScreen extends StatefulWidget {
  final Crop crop;

  const CropDetailScreen({super.key, required this.crop});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {

  bool _isLoadingHarvests = true;
  List<Harvest> _harvests = [];
  bool _isLoadingHistory = true;
  List<CropStageHistory> _history = [];


  @override
  void initState() {
    super.initState();
    _loadHarvests();
    _loadHistory();
  }


  Future<void> _loadHistory() async {
    final farm = Provider.of<FarmProvider>(context, listen: false);
    final results = await farm.getStageHistory(widget.crop.id);
    if (mounted) {
      setState(() {
        _history = results;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadHarvests() async {
    final farm = Provider.of<FarmProvider>(context, listen: false);
    final results = await farm.getHarvestsForCrop(widget.crop.id);
    if (mounted) {
      setState(() {
        _harvests = results;
        _isLoadingHarvests = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final crop = widget.crop;

    // Status color
    Color statusColor = Colors.grey;
    if (crop.status == 'Active') statusColor = Colors.green;
    if (crop.status == 'Harvested') statusColor = Colors.orange;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(crop.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: lang.t('Edit Crop'),
              onPressed: () {
                AddCropDialog.show(context, crop: crop);
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: lang.t('Overview')),
              Tab(text: lang.t('Timeline')),
              Tab(text: lang.t('Harvests')),
              Tab(text: lang.t('Sensors')),
              Tab(text: lang.t('Weather')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(lang, crop, statusColor),
            _buildTimelineTab(lang, crop),
            _buildHarvestsTab(lang, crop),
            _buildSensorsTab(lang, crop),
            _buildWeatherTab(lang, crop),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    LanguageProvider lang,
    Crop crop,
    Color statusColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(lang, crop, statusColor),
          const SizedBox(height: 24),
          _buildInfoSection(lang, crop),
          if (crop.notes != null && crop.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              lang.t('Notes'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(crop.notes!, style: const TextStyle(height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusHeader(
    LanguageProvider lang,
    Crop crop,
    Color statusColor,
  ) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.grass, size: 40, color: statusColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (crop.variety != null && crop.variety!.isNotEmpty)
                Text(
                  crop.variety!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  lang.t(crop.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(LanguageProvider lang, Crop crop) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(
              lang,
              Icons.square_foot,
              'Area',
              crop.area != null
                  ? '${crop.area} ${lang.t(crop.areaUnit ?? "acres")}'
                  : 'Not set',
            ),
            const Divider(),
            _infoRow(
              lang,
              Icons.eco,
              'Growth Stage',
              crop.growthStage != null ? lang.t(crop.growthStage!) : 'Not set',
            ),
            const Divider(),
            _infoRow(
              lang,
              Icons.landscape,
              'Soil Type',
              crop.soilType != null ? lang.t(crop.soilType!) : 'Not set',
            ),
            const Divider(),
            _infoRow(
              lang,
              Icons.water_drop,
              'Irrigation',
              crop.irrigationMethod != null
                  ? lang.t(crop.irrigationMethod!)
                  : 'Not set',
            ),
            const Divider(),
            _infoRow(
              lang,
              Icons.calendar_today,
              'Sowing Date',
              crop.sowingDate != null
                  ? DateFormat.yMMMd().format(crop.sowingDate!)
                  : 'Not set',
            ),
            const Divider(),
            _infoRow(
              lang,
              Icons.event,
              'Expected Harvest',
              crop.expectedHarvestDate != null
                  ? DateFormat.yMMMd().format(crop.expectedHarvestDate!)
                  : 'Not set',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    LanguageProvider lang,
    IconData icon,
    String labelKey,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(
            lang.t(labelKey),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(LanguageProvider lang, Crop crop) {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_history.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _history.length,
        itemBuilder: (ctx, i) {
          final h = _history[i];
          return _timelineNode(lang, h.newStage, h.changedAt, true, isLast: i == _history.length - 1);
        },
      );
    }

    if (crop.sowingDate == null) {
      return Center(child: Text(lang.t('Stage history unavailable')));
    }
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _timelineNode(lang, 'Planting', crop.sowingDate, true),
        _timelineNode(lang, 'Seedling', crop.sowingDate?.add(const Duration(days: 14)), crop.growthStage == 'Seedling' || crop.growthStage != null),
        _timelineNode(lang, 'Vegetative', null, crop.growthStage == 'Vegetative'),
        _timelineNode(lang, 'Flowering', null, crop.growthStage == 'Flowering'),
        _timelineNode(lang, 'Fruiting', null, crop.growthStage == 'Fruiting'),
        _timelineNode(lang, 'Maturity', crop.expectedHarvestDate, crop.growthStage == 'Harvest Ready'),
        _timelineNode(lang, 'Harvested', crop.status == 'Harvested' ? DateTime.now() : null, crop.status == 'Harvested', isLast: true),
      ],
    );
  }

  Widget _timelineNode(
    LanguageProvider lang,
    String title,
    DateTime? date,
    bool isReached, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isReached ? Colors.green : Colors.grey.shade300,
                    border: Border.all(
                      color: isReached ? Colors.green : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isReached ? Colors.green : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.t(title),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isReached
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isReached ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (date != null)
                    Text(
                      DateFormat.yMMMd().format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestsTab(LanguageProvider lang, Crop crop) {
    if (_isLoadingHarvests) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_harvests.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      lang.t('Total Yield'),
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                    Text(
                      '${_harvests.fold<double>(0, (p, c) => p + c.quantity)} kg',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      lang.t('Harvests'),
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                    Text(
                      '${_harvests.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _harvests.length,
              itemBuilder: (ctx, i) {
                final h = _harvests[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.shopping_basket, color: Colors.white),
                  ),
                  title: Text('${h.quantity} ${h.quantityUnit}'),
                  subtitle: Text(DateFormat.yMMMd().format(h.harvestDate)),
                );
              },
            ),
          ),
        ] else ...[
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.t('No harvest records yet.'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSensorsTab(LanguageProvider lang, Crop crop) {
    final iot = Provider.of<IoTProvider>(context);
    final devices = iot.devices.where((d) => d.deviceType.contains('moisture') || d.deviceType.contains('temp')).toList();
    
    if (devices.isEmpty) {
      return Center(child: Text(lang.t('No sensor data available.')));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: devices.length,
      itemBuilder: (ctx, i) {
        final d = devices[i];
        return Card(
          child: ListTile(
            leading: Icon(d.deviceType.contains('moisture') ? Icons.water_drop : Icons.thermostat),
            title: Text(d.name),
            subtitle: Text(d.isOnline ? 'LIVE' : 'OFFLINE'),
            trailing: Text(
              d.latestTelemetry != null ? '${d.latestTelemetry!.soilMoisture ?? d.latestTelemetry!.temperature ?? '0.0'}' : 'UNAVAILABLE',
              style: TextStyle(fontWeight: FontWeight.bold, color: d.isOnline ? Colors.green : Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherTab(LanguageProvider lang, Crop crop) {
    final weather = Provider.of<WeatherProvider>(context);
    final current = weather.currentWeather;
    
    if (current == null) {
      return Center(child: Text(lang.t('Weather unavailable')));
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.thermostat, color: Colors.orange),
            title: Text('${current.temperature}°C'),
            subtitle: Text(current.condition),
          ),
          ListTile(
            leading: const Icon(Icons.water_drop, color: Colors.blue),
            title: Text('${current.humidity}%'),
            subtitle: Text(lang.t('Humidity')),
          ),
          ListTile(
            leading: const Icon(Icons.air, color: Colors.grey),
            title: Text('${current.windSpeed} km/h'),
            subtitle: Text(lang.t('Wind Speed')),
          ),
        ],
      ),
    );
  }

}