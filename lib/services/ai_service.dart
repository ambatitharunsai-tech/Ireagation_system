import 'dart:math';

import '../database/daos/crop_dao.dart';

/// Mock disease diagnosis result.
class DiseaseDiagnosis {
  final String diseaseName;
  final double confidence;
  final List<String> symptoms;
  final List<String> treatments;

  DiseaseDiagnosis({
    required this.diseaseName,
    required this.confidence,
    required this.symptoms,
    required this.treatments,
  });
}

/// Local AI assistant that provides context-aware farming advice.
class AIService {
  final Random _random = Random();

  final List<DiseaseDiagnosis> _diseases = [
    DiseaseDiagnosis(
      diseaseName: 'Early Blight',
      confidence: 0.89,
      symptoms: [
        'Brown spots on leaves',
        'Yellowing foliage',
        'Concentric rings on leaves',
      ],
      treatments: [
        'Apply copper-based fungicide',
        'Improve air circulation',
        'Remove affected leaves',
      ],
    ),
    DiseaseDiagnosis(
      diseaseName: 'Leaf Rust',
      confidence: 0.94,
      symptoms: ['Orange/brown pustules on leaves', 'Premature leaf drop'],
      treatments: [
        'Remove infected leaves',
        'Apply neem oil spray',
        'Use rust-resistant varieties',
      ],
    ),
    DiseaseDiagnosis(
      diseaseName: 'Powdery Mildew',
      confidence: 0.91,
      symptoms: [
        'White powdery coating on leaves',
        'Stunted growth',
        'Leaf curling',
      ],
      treatments: [
        'Apply sulfur-based fungicide',
        'Ensure proper spacing',
        'Water at the base of plants',
      ],
    ),
    DiseaseDiagnosis(
      diseaseName: 'Healthy Crop',
      confidence: 0.98,
      symptoms: ['No visible disease symptoms'],
      treatments: [
        'Continue current maintenance',
        'Regular monitoring recommended',
      ],
    ),
  ];

  /// Simulate disease detection from an image.
  Future<DiseaseDiagnosis> analyzeImage(String imagePath) async {
    await Future.delayed(const Duration(seconds: 2));
    return _diseases[_random.nextInt(_diseases.length)];
  }

  /// Generate context-aware farming advice based on user's crops.
  Future<String> getFarmingAdvice(String query, List<Crop> userCrops) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final cropNames = userCrops.map((c) => c.name).join(', ');
    final context = userCrops.isNotEmpty
        ? "Based on your crops ($cropNames): "
        : "";

    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('water') || lowerQuery.contains('irrigation')) {
      return "${context}Drip irrigation saves up to 50% more water compared to sprinklers. "
          "Water early morning (6-8 AM) to minimize evaporation. For most crops, maintain "
          "soil moisture at 60-80% field capacity. Consider installing soil moisture sensors "
          "for precise irrigation scheduling.";
    }

    if (lowerQuery.contains('fertilizer') ||
        lowerQuery.contains('nutrient') ||
        lowerQuery.contains('soil')) {
      return "${context}A soil test every 2 years helps optimize fertilizer use. Key nutrients:\n"
          "• Nitrogen (N): Promotes leaf growth\n"
          "• Phosphorus (P): Strengthens roots & flowers\n"
          "• Potassium (K): Improves disease resistance\n\n"
          "Apply fertilizer in split doses—50% at sowing, 25% at tillering, 25% at flowering.";
    }

    if (lowerQuery.contains('pest') ||
        lowerQuery.contains('disease') ||
        lowerQuery.contains('insect')) {
      return "${context}Integrated Pest Management (IPM) strategy:\n"
          "1. Cultural: Crop rotation every season\n"
          "2. Biological: Encourage beneficial insects (ladybugs, lacewings)\n"
          "3. Chemical: Use neem oil as first line of defense\n"
          "4. Physical: Install yellow sticky traps for whiteflies\n\n"
          "Monitor crops weekly and act at first sign of infestation.";
    }

    if (lowerQuery.contains('harvest') || lowerQuery.contains('yield')) {
      return "${context}To maximize yield:\n"
          "• Harvest at the right maturity stage—check crop-specific indicators\n"
          "• Harvest during dry weather to reduce post-harvest losses\n"
          "• Use proper storage (cool, dry, ventilated) to maintain quality\n"
          "• Grade and sort produce immediately after harvest for best market prices.";
    }

    if (lowerQuery.contains('weather') ||
        lowerQuery.contains('season') ||
        lowerQuery.contains('climate')) {
      return "${context}Weather management tips:\n"
          "• Monitor forecasts daily during critical growth stages\n"
          "• Use mulching to protect soil from extreme heat (reduces soil temp by 5-8°C)\n"
          "• Install windbreaks for crops sensitive to strong winds\n"
          "• Plan sowing dates based on historical monsoon patterns for your region.";
    }

    if (lowerQuery.contains('market') ||
        lowerQuery.contains('price') ||
        lowerQuery.contains('sell')) {
      return "${context}Market strategy tips:\n"
          "• Check local mandi prices before harvesting\n"
          "• Consider value addition (cleaning, grading, packaging)\n"
          "• Explore direct-to-consumer channels and farmer markets\n"
          "• Contract farming can provide price stability for certain crops.";
    }

    return "${context}Here are some general best practices:\n"
        "• Ensure adequate sunlight (6-8 hours daily for most crops)\n"
        "• Monitor soil moisture regularly\n"
        "• Maintain proper plant spacing for air circulation\n"
        "• Keep detailed records of inputs and outputs for cost analysis\n\n"
        "You can ask me about watering, fertilizer, pests, harvesting, weather, or market prices!";
  }
}
