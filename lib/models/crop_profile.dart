class CropProfile {
  final String name;

  // Basic Optimal ranges
  final int optimalTempMin;
  final int optimalTempMax;
  final double optimalMoistureMin;
  final double optimalMoistureMax;

  // Growing Degree Days (GDD)
  final double baseTemperature;
  final double maxTemperatureGDD;
  final int gddToMaturity; // Total heat units required for harvest

  // Evapotranspiration (Crop Coefficient Kc)
  final double kcInitial; // Seedling
  final double kcMid; // Vegetative/Flowering
  final double kcEnd; // Maturity

  // Disease Risk
  final bool susceptibleToHighHumidity;
  final bool susceptibleToFrost;

  // N-P-K Depletion (grams of nutrient depleted per 1 kg of yield)
  final double nDepletionPerKg;
  final double pDepletionPerKg;
  final double kDepletionPerKg;

  const CropProfile({
    required this.name,
    required this.optimalTempMin,
    required this.optimalTempMax,
    required this.optimalMoistureMin,
    required this.optimalMoistureMax,
    required this.baseTemperature,
    required this.maxTemperatureGDD,
    required this.gddToMaturity,
    required this.kcInitial,
    required this.kcMid,
    required this.kcEnd,
    required this.susceptibleToHighHumidity,
    required this.susceptibleToFrost,
    required this.nDepletionPerKg,
    required this.pDepletionPerKg,
    required this.kDepletionPerKg,
  });

  // Helper for ETc
  double getKcForStage(String? growthStage) {
    if (growthStage == null) return kcInitial;
    switch (growthStage.toLowerCase()) {
      case 'seedling':
      case 'germination':
        return kcInitial;
      case 'vegetative':
      case 'flowering':
      case 'fruiting':
        return kcMid;
      case 'maturity':
      case 'harvest ready':
        return kcEnd;
      default:
        return kcMid; // Safe fallback
    }
  }
}

const defaultCropProfiles = {
  'Wheat': CropProfile(
    name: 'Wheat',
    optimalTempMin: 15,
    optimalTempMax: 25,
    optimalMoistureMin: 40,
    optimalMoistureMax: 70,
    baseTemperature: 4.0,
    maxTemperatureGDD: 30.0,
    gddToMaturity: 1600,
    kcInitial: 0.3,
    kcMid: 1.15,
    kcEnd: 0.25,
    susceptibleToHighHumidity: true, // Rust
    susceptibleToFrost: false,
    nDepletionPerKg: 20.0,
    pDepletionPerKg: 8.0,
    kDepletionPerKg: 15.0,
  ),
  'Rice': CropProfile(
    name: 'Rice',
    optimalTempMin: 20,
    optimalTempMax: 35,
    optimalMoistureMin: 60,
    optimalMoistureMax: 90,
    baseTemperature: 10.0,
    maxTemperatureGDD: 35.0,
    gddToMaturity: 2200,
    kcInitial: 1.05,
    kcMid: 1.20,
    kcEnd: 0.90,
    susceptibleToHighHumidity: true, // Blast
    susceptibleToFrost: true,
    nDepletionPerKg: 15.0,
    pDepletionPerKg: 6.0,
    kDepletionPerKg: 18.0,
  ),
  'Tomato': CropProfile(
    name: 'Tomato',
    optimalTempMin: 18,
    optimalTempMax: 28,
    optimalMoistureMin: 50,
    optimalMoistureMax: 75,
    baseTemperature: 10.0,
    maxTemperatureGDD: 32.0,
    gddToMaturity: 1300,
    kcInitial: 0.6,
    kcMid: 1.15,
    kcEnd: 0.80,
    susceptibleToHighHumidity: true, // Blight
    susceptibleToFrost: true,
    nDepletionPerKg: 2.5,
    pDepletionPerKg: 0.5,
    kDepletionPerKg: 3.5, // per kg of fresh fruit
  ),
};
