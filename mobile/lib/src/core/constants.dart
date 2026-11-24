class AppConfig {
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tvjtoipqvedkutwpgege.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_gAoY7bvPXr889ECywOKuqA_6mG1izSq',
  );
  static const defaultCity = 'Lahore';
  static const photoBucket = 'request-photos';
  static const maxPhotos = 3;
}
