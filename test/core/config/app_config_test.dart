import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/core/config/app_config.dart';

void main() {
  test('selects mock mode when public Supabase configuration is absent', () {
    final config = AppConfig.fromEnvironment({});

    expect(config.isSupabaseConfigured, isFalse);
  });

  test('accepts a secure Supabase URL and an anon key', () {
    final config = AppConfig.fromEnvironment({
      'SUPABASE_URL': 'https://example.supabase.co',
      'SUPABASE_ANON_KEY': 'public-anon-key',
    });

    expect(config.isSupabaseConfigured, isTrue);
  });
}
