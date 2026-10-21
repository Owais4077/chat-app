import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/contact_repository.dart';

class SupabaseContactRepository implements ContactRepository {
  const SupabaseContactRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<void> saveContact({
    required String displayName,
    required String phoneE164,
  }) async {
    await _client.rpc(
      'save_contact',
      params: {
        'target_display_name': displayName,
        'target_phone_e164': phoneE164,
      },
    );
  }
}
