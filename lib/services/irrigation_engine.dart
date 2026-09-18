import '../models/iot_models.dart';
import '../models/crop_profile.dart';
import '../services/weather_service.dart';
import '../database/daos/crop_dao.dart';

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
    required bool isAutoMode,
    Crop? crop,
  }) {
    // 1. Core Safety Rules
    if (!isAutoMode) return IrrigationDecision(false, 'Auto mode disabled', 0);

    final moistureSensors = devices.where((d) => d.deviceType.contains('moisture') && d.isOnline);
    if (moistureSensors.isEmpty) {
      return IrrigationDecision(false, 'No active moisture sensors', 0);
    }

    final readings = moistureSensors
        .where((d) => d.latestTelemetry?.soilMoisture != null)
        .map((d) => d.latestTelemetry!.soilMoisture!)
        .toList();
    if (readings.isEmpty) {
      return IrrigationDecision(false, 'No valid, fresh readings', 0);
    }

    // 2. Weather Safety
    if (weather != null && (weather.precipitationProbability ?? 0) > 70) {
      return IrrigationDecision(false, 'High rain forecast, suppressing irrigation', 0);
    }

    // 3. Extensible Rule Architecture (Crop-aware)
    final avgMoisture = readings.reduce((a, b) => a + b) / readings.length;
    double threshold = 40.0; // Fallback default
    int maxDuration = 20;

    if (crop != null) {
      final profile = defaultCropProfiles[crop.variety ?? crop.name] ?? defaultCropProfiles[crop.name];
      if (profile != null) {
        threshold = profile.optimalMoistureMin;
        // Increase requirement during flowering
        if (crop.growthStage == 'Flowering' || crop.growthStage == 'Fruiting') {
          threshold += 10.0;
        }
        // Decrease requirement nearing harvest
        if (crop.growthStage == 'Maturity' || crop.growthStage == 'Harvest Ready') {
          threshold -= 10.0;
        }
      }
    }

    // 4. Decision
    if (avgMoisture < threshold) {
      return IrrigationDecision(
        true,
        'Moisture ($avgMoisture%) is below dynamic threshold ($threshold%) for ${crop?.name ?? 'crop'}',
        maxDuration,
      );
    }

    return IrrigationDecision(
      false,
      'Moisture levels adequate ($avgMoisture%)',
      0,
    );
  }
}
