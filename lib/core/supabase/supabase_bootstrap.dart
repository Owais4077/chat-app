import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

typedef SupabaseInitializer =
    Future<void> Function({required String url, required String anonKey});

abstract final class SupabaseBootstrap {
  static Future<bool> initialize(
    AppConfig config, {
    SupabaseInitializer? initializer,
  }) async {
    if (!config.isSupabaseConfigured) {
      return false;
    }

    await (initializer ?? _initializeSdk)(
      url: config.supabaseUrl!,
      anonKey: config.supabaseAnonKey!,
    );
    return true;
  }

  static Future<void> _initializeSdk({
    required String url,
    required String anonKey,
  }) => Supabase.initialize(url: url, publishableKey: anonKey);
}
