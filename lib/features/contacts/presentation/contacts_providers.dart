import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/config_providers.dart';
import '../data/supabase_contact_repository.dart';
import '../domain/contact_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  if (!ref.watch(appConfigProvider).isSupabaseConfigured) {
    return _UnavailableContactRepository();
  }
  return SupabaseContactRepository(Supabase.instance.client);
});

class _UnavailableContactRepository implements ContactRepository {
  @override
  Future<void> saveContact({
    required String displayName,
    required String phoneE164,
  }) => throw StateError('Configure Supabase before saving contacts.');
}
