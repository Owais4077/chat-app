import 'contact.dart';
import 'registered_user.dart';

abstract class ContactRepository {
  Stream<List<Contact>> watchContacts();
  Future<void> saveContact({
    required String displayName,
    required String phoneE164,
  });
  Future<void> setMyPhoneIdentity(String phoneE164) async {}
  Future<List<RegisteredUser>> fetchRegisteredUsers() async => const [];
}
