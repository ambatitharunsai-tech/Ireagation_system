import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const String _farmDataKey = 'farm_data_cache';
  static const String _financeDataKey = 'finance_data_cache';

  Future<void> saveFarmData(String userId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString(_farmDataKey) != null 
        ? json.decode(prefs.getString(_farmDataKey)!) as Map<String, dynamic>
        : {};
    cache[userId] = data;
    await prefs.setString(_farmDataKey, json.encode(cache));
  }

  Future<Map<String, dynamic>?> getFarmData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString(_farmDataKey);
    if (cacheString == null) return null;
    final cache = json.decode(cacheString) as Map<String, dynamic>;
    return cache[userId];
  }

  Future<void> saveFinanceData(String userId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString(_financeDataKey) != null 
        ? json.decode(prefs.getString(_financeDataKey)!) as Map<String, dynamic>
        : {};
    cache[userId] = data;
    await prefs.setString(_financeDataKey, json.encode(cache));
  }

  Future<Map<String, dynamic>?> getFinanceData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString(_financeDataKey);
    if (cacheString == null) return null;
    final cache = json.decode(cacheString) as Map<String, dynamic>;
    return cache[userId];
  }
}
