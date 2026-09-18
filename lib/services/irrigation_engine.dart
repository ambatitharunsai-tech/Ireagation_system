import '../services/iot_service.dart';
import '../services/weather_service.dart';

class IrrigationDecision {
  final bool shouldIrrigate;
  final String reason;
  final int durationMinutes;

  IrrigationDecision(this.shouldIrrigate, this.reason, this.durationMinutes);
}

class IrrigationEngine {
  IrrigationDecision evaluate({
    required List<IoTDevice> devices,
    required WeatherData? weather,
    required double moistureThreshold,
    required bool isAutoMode,
  }) {
    if (!isAutoMode) return IrrigationDecision(false, 'Auto mode disabled', 0);

    final moistureSensors = devices.where((d) => d.type.contains('moisture'));
    if (moistureSensors.isEmpty)
      return IrrigationDecision(false, 'No sensors', 0);

    final readings = moistureSensors
        .where((d) => d.lastReading != null)
        .map((d) => d.lastReading!)
        .toList();
    if (readings.isEmpty)
      return IrrigationDecision(false, 'No valid readings', 0);

    final avgMoisture = readings.reduce((a, b) => a + b) / readings.length;

    // Safety Engine
    if (weather != null && weather.precipitationProbability > 60) {
      return IrrigationDecision(false, 'High rain probability', 0);
    }

    if (avgMoisture < moistureThreshold) {
      return IrrigationDecision(
        true,
        'Moisture below threshold ($avgMoisture < $moistureThreshold)',
        20,
      );
    }

    return IrrigationDecision(
      false,
      'Moisture levels adequate ($avgMoisture)',
      0,
    );
  }
}
