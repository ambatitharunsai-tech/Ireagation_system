import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/iot_service.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/task_dao.dart';
import '../database/daos/finance_dao.dart';
import '../services/weather_service.dart';

class GeminiAIService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> getSmartAdvice({
    required String query,
    required List<IoTDevice> devices,
    List<Crop>? crops,
    List<FarmTask>? tasks,
    List<Expense>? expenses,
    List<Sale>? sales,
    WeatherData? weather,
  }) async {
    try {
      final context = {
        'devices': devices.map((d) => {
          'name': d.name,
          'type': d.type,
          'lastReading': d.lastReading,
          'isOnline': d.isOnline,
        }).toList(),
        'crops': crops?.map((c) => c.name).toList() ?? [],
        'weather': weather != null ? {
          'temperature': weather.temperature,
          'rainProbability': weather.precipitationProbability,
        } : null,
      };

      final response = await _supabase.functions.invoke(
        'gemini-advisor',
        body: {
          'query': query,
          'context': context,
        },
      );

      if (response.status == 200) {
        final data = response.data;
        if (data != null && data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      return 'I could not generate advice at this time. Please try again later.';
    } catch (e) {
      debugPrint('GeminiAIService error: $e');
      return 'An error occurred connecting to the AI service.';
    }
  }
}
