import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized Supabase configuration.
/// Uses .env file for development, and dart environment variables as a fallback for production.
class SupabaseConfig {
  static String get url {
    return dotenv.env['SUPABASE_URL'] ?? 
           const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://placeholder.supabase.co');
  }

  static String get anonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ?? 
           const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'placeholder_key');
  }

  /// Demo user id used when auth is bypassed.
  static const String demoUserId = '00000000-0000-0000-0000-000000000000';
}
