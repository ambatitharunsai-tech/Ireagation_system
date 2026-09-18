import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/task_dao.dart';
import '../database/daos/finance_dao.dart';
import '../services/iot_service.dart';
import '../services/weather_service.dart';

/// AI Service powered by Gemini API with full farm context awareness.
/// Falls back to local rule-based advice when no API key is configured.
class GeminiAIService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  /// Build a rich system prompt with live farm context.
  String _buildSystemPrompt({
    List<IoTDevice>? devices,
    List<Crop>? crops,
    List<FarmTask>? tasks,
    List<Expense>? expenses,
    List<Sale>? sales,
    WeatherData? weather,
  }) {
    final sb = StringBuffer();
    sb.writeln('You are an expert Smart Agriculture AI assistant.');
    sb.writeln(
      'You help farmers manage their crops, IoT devices, irrigation, tasks, finances, and make data-driven decisions.',
    );
    sb.writeln(
      'Keep responses concise, actionable, and friendly. Use bullet points for recommendations.',
    );
    sb.writeln('');

    if (weather != null) {
      sb.writeln('=== CURRENT WEATHER ===');
      sb.writeln('Temperature: ${weather.temperature}°C');
      sb.writeln('Humidity: ${weather.humidity}%');
      sb.writeln('Wind: ${weather.windSpeed} km/h');
      sb.writeln('Rain probability: ${weather.precipitationProbability}%');
      sb.writeln('Condition: ${weather.condition}');
      sb.writeln('');
    }

    if (devices != null && devices.isNotEmpty) {
      sb.writeln('=== LIVE IoT SENSOR DATA ===');
      for (final d in devices) {
        if (d.type == 'pump' || d.type == 'valve') {
          sb.writeln(
            '${d.name}: ${d.isActive ? "RUNNING" : "OFF"} (${d.isOnline ? "online" : "offline"})',
          );
        } else {
          sb.writeln(
            '${d.name}: ${d.lastReading?.toStringAsFixed(1) ?? "N/A"}${d.unit ?? ""} (${d.isOnline ? "online" : "offline"})',
          );
        }
      }
      sb.writeln('');
    }

    if (crops != null && crops.isNotEmpty) {
      sb.writeln('=== USER\'S CROPS ===');
      for (final c in crops) {
        sb.writeln(
          '${c.name} — Status: ${c.status}, Stage: ${c.growthStage ?? "Unknown"}, Area: ${c.area ?? 0} acres, Irrigation: ${c.irrigationMethod ?? "Unknown"}',
        );
      }
      sb.writeln('');
    }

    if (tasks != null && tasks.isNotEmpty) {
      sb.writeln('=== PENDING/IN-PROGRESS TASKS ===');
      for (final t in tasks.where((t) => t.status != 'Done')) {
        sb.writeln(
          '${t.title} (Priority: ${t.priority}) - Status: ${t.status} - Due: ${t.date}',
        );
      }
      sb.writeln('');
    }

    if (expenses != null && expenses.isNotEmpty || (sales != null && sales.isNotEmpty)) {
      sb.writeln('=== FINANCIAL OVERVIEW ===');
      if (expenses != null && expenses.isNotEmpty) {
        double totalExp = expenses.fold(0.0, (sum, item) => sum + item.amount);
        sb.writeln('Total Expenses: \$${totalExp.toStringAsFixed(2)}');
        final lastThree = expenses.take(3).toList();
        sb.writeln('Recent Expenses: ${lastThree.map((e) => "${e.category} (\$${e.amount})").join(", ")}');
      }
      if (sales != null && sales.isNotEmpty) {
        double totalSales = sales.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
        sb.writeln('Total Sales Revenue: \$${totalSales.toStringAsFixed(2)}');
      }
      sb.writeln('');
    }

    sb.writeln(
      'Based on the above real-time data, provide specific and actionable advice.',
    );
    sb.writeln(
      'If sensor data shows issues (low moisture, high temperature), proactively warn the farmer. If tasks are pending, gently remind them. If expenses are high, offer cost-saving tips.',
    );
    return sb.toString();
  }

  /// Get AI response using Gemini API with full context.
  Future<String> getSmartAdvice({
    required String query,
    List<IoTDevice>? devices,
    List<Crop>? crops,
    List<FarmTask>? tasks,
    List<Expense>? expenses,
    List<Sale>? sales,
    WeatherData? weather,
  }) async {
    if (!ApiKeys.hasGeminiKey) {
      return _fallbackAdvice(query, crops ?? [], devices);
    }

    try {
      final systemPrompt = _buildSystemPrompt(
        devices: devices,
        crops: crops,
        tasks: tasks,
        expenses: expenses,
        sales: sales,
        weather: weather,
      );

      final url = Uri.parse('$_baseUrl?key=${ApiKeys.geminiKey}');
      final body = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'parts': [
              {'text': query},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024},
      });

      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) return text as String;
        return 'I received a response but could not parse it. Please try again.';
      } else {
        debugPrint('Gemini API error ${response.statusCode}: ${response.body}');
        if (response.statusCode == 400 || response.statusCode == 403) {
          return 'API key error. Please check your Gemini API key in Settings → API Keys.';
        }
        return _fallbackAdvice(query, crops ?? [], devices);
      }
    } catch (e) {
      debugPrint('GeminiAIService error: $e');
      return _fallbackAdvice(query, crops ?? [], devices);
    }
  }

  /// Analyze farm data and produce a comprehensive report.
  Future<String> analyzeFarm({
    required List<IoTDevice> devices,
    required List<Crop> crops,
    WeatherData? weather,
  }) async {
    final query =
        'Give me a comprehensive farm health analysis. '
        'Check all sensor readings, weather conditions, and crop statuses. '
        'Identify any issues and provide specific recommendations. '
        'Format with sections: Overall Health, Irrigation Status, Crop Recommendations, Weather Advisory.';

    return getSmartAdvice(
      query: query,
      devices: devices,
      crops: crops,
      weather: weather,
    );
  }

  /// AI-driven decision for IoT device control.
  Future<AIDecision> evaluateIoTAction({
    required List<IoTDevice> devices,
    required List<Crop> crops,
    WeatherData? weather,
  }) async {
    if (!ApiKeys.hasGeminiKey) {
      return _fallbackDecision(devices, weather);
    }

    try {
      final systemPrompt = _buildSystemPrompt(
        devices: devices,
        crops: crops,
        weather: weather,
      );

      final query = '''Based on the current sensor data and weather, should I:
1. START the water pump? (if moisture is low and no rain expected)
2. STOP the water pump? (if moisture is adequate or rain is coming)
3. DO NOTHING? (if conditions are fine)

Respond in this exact JSON format:
{"action": "START" or "STOP" or "NONE", "reason": "brief explanation", "confidence": 0.0-1.0}''';

      final url = Uri.parse('$_baseUrl?key=${ApiKeys.geminiKey}');
      final body = jsonEncode({
        'system_instruction': {
          'parts': [
            {
              'text':
                  '$systemPrompt\nRespond ONLY with the JSON object, no other text.',
            },
          ],
        },
        'contents': [
          {
            'parts': [
              {'text': query},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 200},
      });

      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String?;
        if (text != null) {
          // Extract JSON from the response
          final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(text);
          if (jsonMatch != null) {
            final decision = jsonDecode(jsonMatch.group(0)!);
            return AIDecision(
              action: decision['action'] ?? 'NONE',
              reason: decision['reason'] ?? 'No reason provided',
              confidence: (decision['confidence'] ?? 0.5).toDouble(),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('GeminiAIService.evaluateIoTAction error: $e');
    }

    return _fallbackDecision(devices, weather);
  }

  /// Rule-based fallback when Gemini API is not available.
  AIDecision _fallbackDecision(List<IoTDevice>? devices, WeatherData? weather) {
    if (devices == null)
      return AIDecision(
        action: 'NONE',
        reason: 'No sensor data',
        confidence: 0.0,
      );

    final moistureSensors = devices.where((d) => d.type == 'moisture_sensor');
    final pump = devices.where((d) => d.type == 'pump').firstOrNull;

    if (moistureSensors.isEmpty || pump == null) {
      return AIDecision(
        action: 'NONE',
        reason: 'No moisture sensors or pump found',
        confidence: 0.0,
      );
    }

    final readings = moistureSensors
        .where((d) => d.lastReading != null)
        .map((d) => d.lastReading!)
        .toList();
    if (readings.isEmpty) {
      return AIDecision(
        action: 'NONE',
        reason: 'No readings available',
        confidence: 0.0,
      );
    }

    final avgMoisture = readings.reduce((a, b) => a + b) / readings.length;
    final rainExpected =
        weather != null && weather.precipitationProbability > 60;

    if (avgMoisture < 30 && !pump.isActive && !rainExpected) {
      return AIDecision(
        action: 'START',
        reason:
            'Avg soil moisture is ${avgMoisture.toStringAsFixed(1)}% (critically low). Starting irrigation.',
        confidence: 0.9,
      );
    } else if (avgMoisture > 75 && pump.isActive) {
      return AIDecision(
        action: 'STOP',
        reason:
            'Avg soil moisture is ${avgMoisture.toStringAsFixed(1)}% (sufficient). Stopping pump.',
        confidence: 0.85,
      );
    } else if (rainExpected && pump.isActive) {
      return AIDecision(
        action: 'STOP',
        reason:
            'Rain expected (${weather.precipitationProbability.toStringAsFixed(0)}% chance). Saving water.',
        confidence: 0.8,
      );
    }

    return AIDecision(
      action: 'NONE',
      reason:
          'Conditions are normal. Moisture: ${avgMoisture.toStringAsFixed(1)}%.',
      confidence: 0.7,
    );
  }

  /// Offline fallback advice.
  String _fallbackAdvice(
    String query,
    List<Crop> crops,
    List<IoTDevice>? devices,
  ) {
    final cropNames = crops.map((c) => c.name).join(', ');
    final context = crops.isNotEmpty
        ? 'Based on your crops ($cropNames): '
        : '';
    final lowerQuery = query.toLowerCase();

    // Add IoT context to responses
    String iotContext = '';
    if (devices != null && devices.isNotEmpty) {
      final moistureSensors = devices.where((d) => d.type == 'moisture_sensor');
      for (final s in moistureSensors) {
        if (s.lastReading != null && s.lastReading! < 35) {
          iotContext +=
              '\n\n⚠️ Alert: ${s.name} shows low moisture (${s.lastReading!.toStringAsFixed(1)}%). Consider irrigating.';
        }
      }
      final tempSensors = devices.where((d) => d.type == 'temp_sensor');
      for (final s in tempSensors) {
        if (s.lastReading != null && s.lastReading! > 38) {
          iotContext +=
              '\n\n⚠️ Alert: ${s.name} shows high temperature (${s.lastReading!.toStringAsFixed(1)}°C). Consider shade protection.';
        }
      }
    }

    if (lowerQuery.contains('water') || lowerQuery.contains('irrigation')) {
      return '${context}Drip irrigation saves up to 50% more water. Water early morning (6-8 AM) to minimize evaporation. Maintain soil moisture at 60-80% field capacity.$iotContext\n\n💡 Configure a Gemini API key in Settings for smarter, context-aware advice!';
    }
    if (lowerQuery.contains('fertilizer') ||
        lowerQuery.contains('nutrient') ||
        lowerQuery.contains('soil')) {
      return '${context}Key nutrients:\n• Nitrogen (N): Leaf growth\n• Phosphorus (P): Root strength\n• Potassium (K): Disease resistance\n\nApply in split doses — 50% sowing, 25% tillering, 25% flowering.$iotContext';
    }
    if (lowerQuery.contains('pest') || lowerQuery.contains('disease')) {
      return '${context}IPM strategy:\n1. Crop rotation every season\n2. Encourage beneficial insects\n3. Neem oil as first defense\n4. Yellow sticky traps for whiteflies$iotContext';
    }
    if (lowerQuery.contains('harvest') || lowerQuery.contains('yield')) {
      return '${context}To maximize yield:\n• Harvest at right maturity stage\n• Harvest during dry weather\n• Use proper storage (cool, dry)\n• Grade and sort for best prices$iotContext';
    }
    if (lowerQuery.contains('analyz') ||
        lowerQuery.contains('status') ||
        lowerQuery.contains('check')) {
      final sensorReport =
          devices
              ?.where((d) => d.type != 'pump' && d.type != 'valve')
              .map(
                (d) =>
                    '• ${d.name}: ${d.lastReading?.toStringAsFixed(1) ?? "N/A"}${d.unit ?? ""}',
              )
              .join('\n') ??
          'No sensors connected';
      final cropsText = crops.isEmpty
          ? "No crops tracked."
          : "Crops: ${crops.map((c) => '${c.name} (${c.status})').join(', ')}";
      return '$context📊 Farm Status Report:\n\n$sensorReport\n\n$cropsText$iotContext';
    }

    return '${context}I can help with watering, fertilizer, pests, harvesting, weather planning, and market strategies. Ask me anything!$iotContext\n\n💡 Add a Gemini API key in Settings → API Keys for AI-powered analysis!';
  }
}

/// Represents an AI decision about device control.
class AIDecision {
  final String action; // START, STOP, NONE
  final String reason;
  final double confidence;

  AIDecision({
    required this.action,
    required this.reason,
    required this.confidence,
  });
}
