/// Centralized Supabase configuration.
/// Uses dart environment variables for secure deployment.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );
  
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder_key',
  );

  /// Demo user id used when auth is bypassed.
  static const String demoUserId = '00000000-0000-0000-0000-000000000000';
}
