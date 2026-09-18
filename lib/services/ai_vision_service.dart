import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_keys.dart';

class AiVisionService {
  Future<String> analyzeCropImage(XFile image) async {
    if (!ApiKeys.hasGeminiKey) {
      // Mock fallback if no API key is provided
      await Future.delayed(const Duration(seconds: 2));
      return "Diagnostic Result (Simulated):\n- The leaf shows signs of mild Nitrogen deficiency (yellowing tips).\n- No visible fungal infections.\n- Recommendation: Apply N-rich fertilizer.";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: ApiKeys.geminiKey,
      );

      final prompt = TextPart(
        "You are an expert agronomist. Analyze this crop leaf/plant image. Identify any visible diseases, nutrient deficiencies, or pests. Provide a short, structured diagnosis and a recommended treatment.",
      );
      final imageBytes = await image.readAsBytes();

      // Determine mime type
      final ext = image.name.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (ext == 'png')
        mimeType = 'image/png';
      else if (ext == 'webp')
        mimeType = 'image/webp';
      else if (ext == 'heic')
        mimeType = 'image/heic';

      final imagePart = DataPart(mimeType, imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      return response.text ?? "Analysis failed. Please try again.";
    } catch (e) {
      debugPrint('AiVisionService Error: $e');
      return "Error connecting to AI diagnostic service: $e";
    }
  }
}
