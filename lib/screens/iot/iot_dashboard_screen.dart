import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/iot_provider.dart';
import '../../providers/farm_provider.dart';
import '../../services/iot_service.dart';

class IoTDashboardScreen extends StatelessWidget {
  const IoTDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final iot = Provider.of<IoTProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Devices'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showAlerts(context, iot),
              ),
              if (iot.unreadAlertCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status bar
          _buildStatusBar(iot),
          const SizedBox(height: 16),

          // AI Agent Card
          _buildAiAgentCard(context, iot),
          const SizedBox(height: 16),

          // Auto irrigation card
          _buildAutoIrrigationCard(context, iot),
          const SizedBox(height: 20),

          // Sensors section
          const Text(
            '📡 Sensors',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...iot.sensors.map((d) => _buildSensorCard(context, d, iot)),
          const SizedBox(height: 20),

          // Actuators section
          const Text(
            '⚡ Pumps & Valves',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...iot.actuators.map((d) => _buildActuatorCard(d, iot)),
          const SizedBox(height: 20),

          // AI Agent Logs
          if (iot.aiLogs.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🤖 AI Agent Log',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => iot.aiAgent.clearLogs(),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...iot.aiLogs.take(10).map((log) => _buildLogTile(log)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAiAgentCard(BuildContext context, IoTProvider iot) {
    return Card(
      color: iot.isAiAgentActive
          ? Colors.deepPurple.shade50
          : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iot.isAiAgentActive
                        ? Colors.deepPurple.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: iot.isAiAgentActive
                        ? Colors.deepPurple
                        : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Agent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        iot.isAiAgentActive
                            ? 'Monitoring sensors & managing irrigation'
                            : 'Tap to enable AI-powered farm management',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: iot.isAiAgentActive,
                  onChanged: (_) => iot.toggleAiAgent(),
                  activeThumbColor: Colors.deepPurple,
                ),
              ],
            ),
            if (iot.isAiAgentActive && iot.lastAiRecommendation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.deepPurple.shade400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        iot.lastAiRecommendation,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (iot.isAiAgentActive) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final crops = Provider.of<FarmProvider>(
                      context,
                      listen: false,
                    ).crops;
                    await iot.runAiEvaluationWithContext(crops);
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text(
                    'Evaluate Now',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogTile(dynamic log) {
    final color = log.type == 'action'
        ? Colors.blue
        : log.type == 'error'
        ? Colors.red
        : log.type == 'evaluation'
        ? Colors.deepPurple
        : Colors.grey;
    final icon = log.type == 'action'
        ? Icons.flash_on
        : log.type == 'error'
        ? Icons.error_outline
        : log.type == 'evaluation'
        ? Icons.analytics
        : Icons.info_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.message,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Text(
            _timeAgo(log.timestamp),
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(IoTProvider iot) {
    return Row(
      children: [
        _buildStatusChip(
          '${iot.onlineCount}/${iot.devices.length}',
          'Online',
          Icons.sensors,
          Colors.green,
        ),
        const SizedBox(width: 12),
        _buildStatusChip(
          '${iot.actuators.where((d) => d.isActive).length}',
          'Active',
          Icons.power,
          Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildStatusChip(
          '${iot.unreadAlertCount}',
          'Alerts',
          Icons.warning_amber,
          iot.unreadAlertCount > 0 ? Colors.orange : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStatusChip(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoIrrigationCard(BuildContext context, IoTProvider iot) {
    return Card(
      color: iot.autoIrrigation ? Colors.green.shade50 : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.water,
                  color: iot.autoIrrigation ? Colors.green : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Irrigation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        iot.autoIrrigation
                            ? 'Pump starts when moisture < ${iot.moistureThreshold.round()}%'
                            : 'Manual control mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: iot.autoIrrigation,
                  onChanged: (val) => iot.setAutoIrrigation(val),
                  activeThumbColor: Colors.green,
                ),
              ],
            ),
            if (iot.autoIrrigation) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Threshold:', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Slider(
                      value: iot.moistureThreshold,
                      min: 15,
                      max: 60,
                      divisions: 9,
                      label: '${iot.moistureThreshold.round()}%',
                      activeColor: Colors.green,
                      onChanged: (val) => iot.setMoistureThreshold(val),
                    ),
                  ),
                  Text(
                    '${iot.moistureThreshold.round()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(
    BuildContext context,
    IoTDevice device,
    IoTProvider iot,
  ) {
    final reading = device.lastReading ?? 0;
    Color valueColor;
    IconData icon;

    switch (device.type) {
      case 'moisture_sensor':
        icon = Icons.water_drop;
        valueColor = reading < 30
            ? Colors.red
            : reading < 50
            ? Colors.orange
            : Colors.blue;
        break;
      case 'temp_sensor':
        icon = Icons.thermostat;
        valueColor = reading > 35
            ? Colors.red
            : reading > 28
            ? Colors.orange
            : Colors.green;
        break;
      case 'humidity_sensor':
        icon = Icons.cloud;
        valueColor = Colors.teal;
        break;
      default:
        icon = Icons.sensors;
        valueColor = Colors.grey;
    }

    double progress;
    switch (device.type) {
      case 'moisture_sensor':
        progress = reading / 100;
        break;
      case 'temp_sensor':
        progress = reading / 50;
        break;
      case 'humidity_sensor':
        progress = reading / 100;
        break;
      default:
        progress = 0;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSensorDetail(context, device, iot),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: valueColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: valueColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: device.isOnline
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              device.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${reading.toStringAsFixed(1)}${device.unit ?? ""}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: valueColor,
                        ),
                      ),
                      Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  backgroundColor: Colors.grey.shade200,
                  color: valueColor,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActuatorCard(IoTDevice device, IoTProvider iot) {
    final isActive = device.isActive;
    final color = isActive ? Colors.blue : Colors.grey;
    final icon = device.type == 'pump'
        ? Icons.water
        : Icons.water_drop_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isActive ? Colors.blue.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isActive ? '● RUNNING' : '○ OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => iot.toggleDevice(device.id),
              icon: Icon(isActive ? Icons.stop : Icons.play_arrow),
              label: Text(isActive ? 'Stop' : 'Start'),
              style: FilledButton.styleFrom(
                backgroundColor: isActive
                    ? Colors.red.shade100
                    : Colors.green.shade100,
                foregroundColor: isActive ? Colors.red : Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSensorDetail(
    BuildContext context,
    IoTDevice device,
    IoTProvider iot,
  ) {
    final history = iot.getSensorHistory(device.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              device.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Type: ${device.type.replaceAll("_", " ").toUpperCase()}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _detailStat(
                  'Current',
                  '${device.lastReading?.toStringAsFixed(1) ?? "--"}${device.unit ?? ""}',
                ),
                const SizedBox(width: 24),
                if (history.length >= 2) ...[
                  _detailStat(
                    'Min',
                    '${history.map((r) => r.value).reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}${device.unit ?? ""}',
                  ),
                  const SizedBox(width: 24),
                  _detailStat(
                    'Max',
                    '${history.map((r) => r.value).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}${device.unit ?? ""}',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Recent Readings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              Text('No data yet', style: TextStyle(color: Colors.grey.shade500))
            else
              SizedBox(
                height: 60,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: history.map((r) {
                    final minVal = history
                        .map((r) => r.value)
                        .reduce((a, b) => a < b ? a : b);
                    final maxVal = history
                        .map((r) => r.value)
                        .reduce((a, b) => a > b ? a : b);
                    final range = maxVal - minVal + 1;
                    final normalizedHeight =
                        ((r.value - minVal) / range) * 50 + 10;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: normalizedHeight,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade300,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showAlerts(BuildContext context, IoTProvider iot) {
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
                  const Text(
                    'Alerts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (iot.alerts.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        iot.clearAllAlerts();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear All'),
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
                            'No alerts',
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
                        final color = alert.severity == 'critical'
                            ? Colors.red
                            : alert.severity == 'warning'
                            ? Colors.orange
                            : Colors.blue;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: alert.isRead
                              ? null
                              : color.withValues(alpha: 0.05),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              radius: 18,
                              child: Icon(
                                alert.deviceId == 'ai-agent'
                                    ? Icons.auto_awesome
                                    : alert.severity == 'critical'
                                    ? Icons.error
                                    : alert.severity == 'warning'
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
                                fontWeight: alert.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${alert.deviceName} • ${_timeAgo(alert.timestamp)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
