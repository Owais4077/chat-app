import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/contacts/domain/contact.dart';

void main() {
  test('maps a private saved-contact row without exposing it elsewhere', () {
    final contact = Contact.fromSupabaseRow({
      'id': 'contact-1',
      'display_name': 'Khan',
      'phone_e164': '+923001234567',
      'registered_user_id': 'user-2',
    });

    expect(contact.displayName, 'Khan');
    expect(contact.registeredUserId, 'user-2');
  });
}
