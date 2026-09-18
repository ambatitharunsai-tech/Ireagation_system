/// Centralized Supabase configuration.
/// Update these values with your Supabase project credentials.
class SupabaseConfig {
  // ------------------------------------------------------------------
  // ⚠️  REPLACE THESE WITH YOUR REAL SUPABASE PROJECT CREDENTIALS
  // ------------------------------------------------------------------
  // Go to: https://supabase.com/dashboard → Project Settings → API
  //
  // • url          → Project URL  (e.g. https://abc.supabase.co)
  // • anonKey      → the "anon / public" key (starts with eyJ…)
  //                   OR the newer sb_publishable_… format
  // ------------------------------------------------------------------
  static const String url = 'https://kamoyvzltvshnqdvhwpr.supabase.co';
  static const String anonKey =
      'sb_publishable_eLBpvbyMOBmAhejQBS9FEQ_XPk6Hei7';

  /// Demo user id used when auth is bypassed.
  static const String demoUserId = '00000000-0000-0000-0000-000000000000';
}
