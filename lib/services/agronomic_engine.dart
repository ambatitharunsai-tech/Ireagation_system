import '../models/crop_profile.dart';
import 'weather_service.dart';
import '../database/daos/crop_dao.dart';

class AgronomicEngine {
  /// Calculates Growing Degree Days (GDD) for a single day
  static double calculateDailyGDD(CropProfile profile, double dailyMaxTemp, double dailyMinTemp) {
    // Cap max temperature
    double maxT = dailyMaxTemp > profile.maxTemperatureGDD ? profile.maxTemperatureGDD : dailyMaxTemp;
    // Cap min temperature
    double minT = dailyMinTemp < profile.baseTemperature ? profile.baseTemperature : dailyMinTemp;
    
    // Average
    double avgT = (maxT + minT) / 2.0;
    
    double gdd = avgT - profile.baseTemperature;
    return gdd > 0 ? gdd : 0;
  }

  /// Calculates simplified Crop Evapotranspiration (ETc) in mm
  /// ETc = ETo * Kc. (ETo = reference evapotranspiration, which we approximate using temp/humidity/wind)
  static double calculateETc(CropProfile profile, String? growthStage, WeatherData current, DailyForecast forecast) {
    // ETo approximation (Hargreaves-Samani simplified or similar based on available data)
    // Since we only have basic weather data, we use a very simplified empirical proxy:
    // Temp factor (higher temp = more ET), Humidity factor (higher RH = less ET), Wind factor (more wind = more ET)
    
    double tMean = current.temperature ?? 20.0;
    double rhFactor = (100 - (current.humidity ?? 50.0)) / 100.0;
    double windFactor = 1 + ((current.windSpeed ?? 5.0) / 100.0); // Simple multiplier
    
    // Base approximate ETo (mm/day)
    double eto = (tMean * 0.2) * rhFactor * windFactor;
    if (eto < 0) eto = 0;
    
    double kc = profile.getKcForStage(growthStage);
    
    return eto * kc;
  }

  /// Generates Disease Risk Alerts based on 5-day weather and crop profile
  static List<String> assessDiseaseRisk(CropProfile profile, List<DailyForecast> forecast5Days) {
    List<String> alerts = [];
    
    if (profile.susceptibleToHighHumidity) {
      // Check if we have consecutive days of high humidity (> 80%) and moderate temps (15-25C)
      int consecutiveHighRiskDays = 0;
      for (var day in forecast5Days) {
        if ((day.precipitationProbability ?? 0.0) > 0.5 && (day.tempMax ?? 0) >= 15 && (day.tempMax ?? 0) <= 28) {
          consecutiveHighRiskDays++;
        } else {
          consecutiveHighRiskDays = 0;
        }
        
        if (consecutiveHighRiskDays >= 2) {
          alerts.add('High risk of fungal disease (e.g. Blight/Rust) due to consecutive humid, warm days. Consider preventative fungicide.');
          break; // Only alert once
        }
      }
    }
    
    if (profile.susceptibleToFrost) {
      for (var day in forecast5Days) {
        if ((day.tempMin ?? 10) <= 2) {
          alerts.add('Frost warning! Temperatures expected to drop to ${day.tempMin}°C. Cover crops if possible.');
          break;
        }
      }
    }
    
    return alerts;
  }

  /// Calculates NPK depletion (in kg) based on total harvested yield (kg)
  static Map<String, double> calculateNutrientDepletion(CropProfile profile, double totalYieldKg) {
    // profile values are in grams per 1 kg of yield. We return kg of nutrient depleted.
    return {
      'Nitrogen (N)': (profile.nDepletionPerKg * totalYieldKg) / 1000.0,
      'Phosphorus (P)': (profile.pDepletionPerKg * totalYieldKg) / 1000.0,
      'Potassium (K)': (profile.kDepletionPerKg * totalYieldKg) / 1000.0,
    };
  }
}
