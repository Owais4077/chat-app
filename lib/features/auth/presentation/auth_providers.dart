import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/config_providers.dart';
import '../data/mock_auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

final _defaultMockAuthRepository = MockAuthRepository();

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!ref.watch(appConfigProvider).isSupabaseConfigured) {
    return _defaultMockAuthRepository;
  }
  return SupabaseAuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AppUser?>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  yield repository.currentUser();
  yield* repository.authStateChanges();
});
