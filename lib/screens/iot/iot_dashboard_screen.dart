import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/iot_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/iot_models.dart';

class IotDashboardScreen extends StatefulWidget {
  const IotDashboardScreen({super.key});

  @override
  State<IotDashboardScreen> createState() => _IotDashboardScreenState();
}

class _IotDashboardScreenState extends State<IotDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iot = context.watch<IoTProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: Colors.blue.shade700,
              title: Text(
                lang.t('IoT Dashboard'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () => _showAlerts(context, iot, lang),
                    ),
                    if (iot.unreadAlertCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${iot.unreadAlertCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => iot.connect('farm_123'),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi, color: Colors.white70, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${iot.onlineCount} ${lang.t('Devices Online')}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const Spacer(),
                            _buildMqttState(iot.connectionState, lang),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(text: lang.t('Overview')),
                  Tab(text: lang.t('Devices')),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(context, iot, lang),
            _buildDevicesTab(context, iot, lang),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended( heroTag: "iot_fab",
        onPressed: () {
          // Placeholder for pairing device
        },
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(lang.t('Add Device'), style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildMqttState(MqttConnectionStateApp state, LanguageProvider lang) {
    Color c;
    String text;
    switch (state) {
      case MqttConnectionStateApp.CONNECTED:
        c = Colors.greenAccent;
        text = 'MQTT CONNECTED';
        break;
      case MqttConnectionStateApp.CONNECTING:
      case MqttConnectionStateApp.RECONNECTING:
        c = Colors.orangeAccent;
        text = 'CONNECTING...';
        break;
      case MqttConnectionStateApp.DISCONNECTED:
      case MqttConnectionStateApp.ERROR:
      default:
        c = Colors.redAccent;
        text = 'MQTT OFFLINE';
        break;
    }
    return Row(
      children: [
        Icon(Icons.circle, color: c, size: 10),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildOverviewTab(BuildContext context, IoTProvider iot, LanguageProvider lang) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEmergencyStopCard(iot, lang),
        const SizedBox(height: 16),
        _buildAiAdvisorCard(iot, lang),
        const SizedBox(height: 16),
        _buildQuickStats(iot, lang),
        const SizedBox(height: 24),
        Text(
          lang.t('Automation Settings'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildAutomationSettings(iot, lang),
      ],
    );
  }

  Widget _buildEmergencyStopCard(IoTProvider iot, LanguageProvider lang) {
    return Card(
      color: iot.emergencyStop ? Colors.red.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: iot.emergencyStop ? Colors.red : Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: iot.emergencyStop ? Colors.red : Colors.orange, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        iot.emergencyStop ? lang.t('EMERGENCY STOP ACTIVE') : lang.t('Emergency Control'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: iot.emergencyStop ? Colors.red.shade800 : Colors.black87,
                        ),
                      ),
                      Text(
                        iot.emergencyStop
                            ? lang.t('All automated irrigation is suspended.')
                            : lang.t('Instantly halt all pumps and automation.'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: iot.emergencyStop,
                  activeColor: Colors.red,
                  onChanged: (val) => iot.setEmergencyStop(val),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAdvisorCard(IoTProvider iot, LanguageProvider lang) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: Colors.purple.shade400),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.t('AI Advisor'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    lang.t(iot.lastAiRecommendation),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(IoTProvider iot, LanguageProvider lang) {
    int activeActuators = iot.actuators.where((d) => d.currentPumpState == 'ON' || d.currentValveState == 'ON').length;
    return Row(
      children: [
        Expanded(
          child: _statCard(
            lang.t('Sensors'),
            '${iot.sensors.length}',
            Icons.sensors,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            lang.t('Active Pumps'),
            '$activeActuators',
            Icons.water_drop,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationSettings(IoTProvider iot, LanguageProvider lang) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(lang.t('Auto Irrigation')),
              subtitle: Text(lang.t('Trigger pumps based on soil moisture')),
              value: iot.autoIrrigation,
              onChanged: iot.emergencyStop ? null : (v) => iot.setAutoIrrigation(v),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(lang.t('Moisture Threshold')),
                  const Spacer(),
                  Text(
                    '${iot.moistureThreshold.toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ),
            Slider(
              value: iot.moistureThreshold,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${iot.moistureThreshold.toInt()}%',
              onChanged: (v) => iot.setMoistureThreshold(v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesTab(BuildContext context, IoTProvider iot, LanguageProvider lang) {
    if (iot.devices.isEmpty) {
      return Center(
        child: Text(
          lang.t('No devices found.'),
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: iot.devices.length,
      itemBuilder: (ctx, i) {
        final device = iot.devices[i];
        if (device.deviceType == 'pump' || device.deviceType == 'valve') {
          return _buildActuatorCard(device, iot, lang);
        } else {
          return _buildSensorCard(device, lang);
        }
      },
    );
  }

  Widget _buildSensorCard(IoTDevice device, LanguageProvider lang) {
    final state = device.state;
    final tel = device.latestTelemetry;
    
    String mainValue = lang.t('No reading');
    String unit = '';
    
    if (tel != null) {
      if (tel.soilMoisture != null) {
        mainValue = tel.soilMoisture!.toStringAsFixed(1);
        unit = '%';
      } else if (tel.temperature != null) {
        mainValue = tel.temperature!.toStringAsFixed(1);
        unit = '°C';
      } else if (tel.waterLevel != null) {
        mainValue = tel.waterLevel!.toStringAsFixed(1);
        unit = '%';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.sensors, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _buildDeviceStateBadge(state, lang),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  mainValue,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  unit,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tel != null ? _timeAgo(tel.receivedAt, lang) : lang.t('Never'),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActuatorCard(IoTDevice device, IoTProvider iot, LanguageProvider lang) {
    final isOnline = device.state == DeviceState.LIVE || device.state == DeviceState.STALE;
    final isRunning = device.currentPumpState == 'ON' || device.currentValveState == 'ON';
    final cmdState = iot.getCommandStateForDevice(device.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _buildDeviceStateBadge(device.state, lang),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('Status'),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.currentPumpState == null ? lang.t('UNKNOWN') : (isRunning ? lang.t('RUNNING') : lang.t('OFF')),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: device.currentPumpState == null ? Colors.grey : (isRunning ? Colors.blue : Colors.black87),
                      ),
                    ),
                  ],
                ),
                if (cmdState != null && cmdState != CommandState.COMPLETED && cmdState != CommandState.FAILED && cmdState != CommandState.REJECTED)
                  Row(
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Text(
                        cmdState.name,
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: (isOnline && !iot.emergencyStop) ? () => iot.toggleDevice(device.id, 'user_manual') : null,
                    icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(isRunning ? lang.t('Stop') : lang.t('Start')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunning ? Colors.red.shade50 : Colors.green.shade50,
                      foregroundColor: isRunning ? Colors.red : Colors.green.shade700,
                      elevation: 0,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStateBadge(DeviceState state, LanguageProvider lang) {
    Color color;
    String text;
    switch (state) {
      case DeviceState.LIVE:
        color = Colors.green;
        text = 'LIVE';
        break;
      case DeviceState.STALE:
        color = Colors.orange;
        text = 'STALE';
        break;
      case DeviceState.OFFLINE:
        color = Colors.red;
        text = 'OFFLINE';
        break;
      case DeviceState.UNKNOWN:
      default:
        color = Colors.grey;
        text = 'UNKNOWN';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        lang.t(text),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAlerts(BuildContext context, IoTProvider iot, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    lang.t('Alerts'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (iot.alerts.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        iot.clearAllAlerts();
                        Navigator.pop(ctx);
                      },
                      child: Text(lang.t('Clear All')),
                    ),
                ],
              ),
            ),
            Expanded(
              child: iot.alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang.t('No alerts'),
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: iot.alerts.length,
                      itemBuilder: (ctx, i) {
                        final alert = iot.alerts[i];
                        final color = alert.severity == 'CRITICAL'
                            ? Colors.red
                            : alert.severity == 'WARNING'
                            ? Colors.orange
                            : Colors.blue;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: alert.isRead ? null : color.withOpacity(0.05),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.15),
                              radius: 18,
                              child: Icon(
                                alert.deviceId == 'ai-agent'
                                    ? Icons.auto_awesome
                                    : alert.severity == 'CRITICAL'
                                        ? Icons.error
                                        : alert.severity == 'WARNING'
                                            ? Icons.warning
                                            : Icons.info,
                                color: color,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              alert.message,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: alert.isRead ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${alert.deviceId} • ${_timeAgo(alert.createdAt, lang)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                            onTap: () => iot.markAlertRead(alert.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt, LanguageProvider lang) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return lang.t('just now');
    if (diff.inMinutes < 60) return '${diff.inMinutes}${lang.t('m ago')}';
    if (diff.inHours < 24) return '${diff.inHours}${lang.t('h ago')}';
    return '${diff.inDays}${lang.t('d ago')}';
  }
}
