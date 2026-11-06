class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.turnUrl,
    required this.turnUsername,
  });

  final String? supabaseUrl;
  final String? supabaseAnonKey;
  final String? turnUrl;
  final String? turnUsername;

  bool get isSupabaseConfigured {
    final url = Uri.tryParse(supabaseUrl ?? '');
    return url != null &&
        url.isScheme('https') &&
        (supabaseAnonKey?.isNotEmpty ?? false);
  }

  factory AppConfig.fromEnvironment(Map<String, String> environment) =>
      AppConfig(
        supabaseUrl: environment['SUPABASE_URL'],
        supabaseAnonKey: environment['SUPABASE_ANON_KEY'],
        turnUrl: environment['TURN_URL'],
        turnUsername: environment['TURN_USERNAME'],
      );
}
