import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/config_providers.dart';
import '../data/supabase_contact_repository.dart';
import '../domain/contact.dart';
import '../domain/contact_repository.dart';
import '../domain/registered_user.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  if (!ref.watch(appConfigProvider).isSupabaseConfigured) {
    return _UnavailableContactRepository();
  }
  return SupabaseContactRepository(Supabase.instance.client);
});

final contactsProvider = StreamProvider<List<Contact>>(
  (ref) => ref.watch(contactRepositoryProvider).watchContacts(),
);

final registeredUsersProvider = FutureProvider<List<RegisteredUser>>(
  (ref) => ref.watch(contactRepositoryProvider).fetchRegisteredUsers(),
);

class _UnavailableContactRepository implements ContactRepository {
  @override
  Stream<List<Contact>> watchContacts() => Stream.value(const []);

  @override
  Future<void> saveContact({
    required String displayName,
    required String phoneE164,
  }) => throw StateError('Configure Supabase before saving contacts.');

  @override
  Future<void> setMyPhoneIdentity(String phoneE164) async {}

  @override
  Future<List<RegisteredUser>> fetchRegisteredUsers() async => const [];
}
