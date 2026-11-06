import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/core/config/app_config.dart';
import 'package:relay_messenger/core/supabase/supabase_bootstrap.dart';

void main() {
  test(
    'does not initialize Supabase when public configuration is absent',
    () async {
      var invoked = false;
      final initialized = await SupabaseBootstrap.initialize(
        const AppConfig(
          supabaseUrl: null,
          supabaseAnonKey: null,
          turnUrl: null,
          turnUsername: null,
        ),
        initializer: ({required url, required anonKey}) async => invoked = true,
      );

      expect(initialized, isFalse);
      expect(invoked, isFalse);
    },
  );

  test('initializes Supabase from valid public configuration', () async {
    String? initializedUrl;
    String? initializedKey;

    final initialized = await SupabaseBootstrap.initialize(
      const AppConfig(
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'publishable-key',
        turnUrl: null,
        turnUsername: null,
      ),
      initializer: ({required url, required anonKey}) async {
        initializedUrl = url;
        initializedKey = anonKey;
      },
    );

    expect(initialized, isTrue);
    expect(initializedUrl, 'https://project.supabase.co');
    expect(initializedKey, 'publishable-key');
  });
}
