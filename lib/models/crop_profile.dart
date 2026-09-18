class CropProfile {
  final String name;
  final int optimalTempMin;
  final int optimalTempMax;
  final double optimalMoistureMin;
  final double optimalMoistureMax;

  const CropProfile({
    required this.name,
    required this.optimalTempMin,
    required this.optimalTempMax,
    required this.optimalMoistureMin,
    required this.optimalMoistureMax,
  });
}

const defaultCropProfiles = {
  'Wheat': CropProfile(name: 'Wheat', optimalTempMin: 15, optimalTempMax: 25, optimalMoistureMin: 40, optimalMoistureMax: 70),
  'Rice': CropProfile(name: 'Rice', optimalTempMin: 20, optimalTempMax: 35, optimalMoistureMin: 60, optimalMoistureMax: 90),
  'Tomato': CropProfile(name: 'Tomato', optimalTempMin: 18, optimalTempMax: 28, optimalMoistureMin: 50, optimalMoistureMax: 75),
};
