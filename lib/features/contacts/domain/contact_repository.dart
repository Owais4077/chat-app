import 'contact.dart';

abstract interface class ContactRepository {
  Stream<List<Contact>> watchContacts();
  Future<void> saveContact({
    required String displayName,
    required String phoneE164,
  });
}
