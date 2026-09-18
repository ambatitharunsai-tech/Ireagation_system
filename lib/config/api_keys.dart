/// Centralized API key management.
/// Users configure their own keys for production use.
class ApiKeys {
  /// Gemini API Key — get yours free at https://aistudio.google.com/apikey
  /// Leave empty to use offline fallback mode.
  static String _geminiKey = '';

  /// ThingSpeak API Key (optional) — for real IoT sensor integration.
  static String _thingSpeakReadKey = '';
  static String _thingSpeakChannelId = '';

  static String get geminiKey => _geminiKey;
  static bool get hasGeminiKey => _geminiKey.isNotEmpty;

  static String get thingSpeakReadKey => _thingSpeakReadKey;
  static String get thingSpeakChannelId => _thingSpeakChannelId;
  static bool get hasThingSpeak =>
      _thingSpeakReadKey.isNotEmpty && _thingSpeakChannelId.isNotEmpty;

  static void setGeminiKey(String key) => _geminiKey = key.trim();
  static void setThingSpeakKeys(String channelId, String readKey) {
    _thingSpeakChannelId = channelId.trim();
    _thingSpeakReadKey = readKey.trim();
  }
}
