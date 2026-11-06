import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/contact_repository.dart';
import '../domain/contact.dart';
import '../domain/registered_user.dart';

class SupabaseContactRepository implements ContactRepository {
  const SupabaseContactRepository(this._client);
  final SupabaseClient _client;

  @override
  Stream<List<Contact>> watchContacts() => _client
      .from('contacts')
      .stream(primaryKey: const ['id'])
      .order('display_name')
      .map(
        (rows) => rows
            .map((row) => Contact.fromSupabaseRow(row))
            .toList(growable: false),
      );

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

  @override
  Future<void> setMyPhoneIdentity(String phoneE164) async {
    await _client.rpc(
      'set_my_phone_identity',
      params: {'target_phone_e164': phoneE164},
    );
  }

  @override
  Future<List<RegisteredUser>> fetchRegisteredUsers() async {
    final currentUserId = _client.auth.currentUser?.id;
    var query = _client.from('profiles').select('id, display_name, username');
    if (currentUserId != null) {
      query = query.neq('id', currentUserId);
    }
    final rows = await query.order('display_name');
    return (rows as List)
        .map((row) => RegisteredUser.fromRow(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }
}
