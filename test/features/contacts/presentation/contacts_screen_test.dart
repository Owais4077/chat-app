import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/contacts/domain/contact_repository.dart';
import 'package:relay_messenger/features/contacts/domain/contact.dart';
import 'package:relay_messenger/features/contacts/domain/registered_user.dart';
import 'package:relay_messenger/features/contacts/presentation/contacts_providers.dart';
import 'package:relay_messenger/features/contacts/presentation/contacts_screen.dart';

void main() {
  testWidgets('saves a named international phone contact', (tester) async {
    final repository = _FakeContactRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: ContactsScreen())),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Khan');
    await tester.enterText(find.byType(TextField).at(1), '+923001234567');
    await tester.tap(find.text('Save contact'));
    await tester.pump();

    expect(repository.name, 'Khan');
    expect(repository.phone, '+923001234567');
    expect(find.text('Contact saved'), findsOneWidget);
  });

  testWidgets('shows which saved contacts can receive a message', (
    tester,
  ) async {
    final repository = _FakeContactRepository(
      contacts: const [
        Contact(
          id: 'contact-1',
          displayName: 'Khan',
          phoneE164: '+923001234567',
          registeredUserId: 'user-2',
        ),
        Contact(
          id: 'contact-2',
          displayName: 'Sara',
          phoneE164: '+923009876543',
          registeredUserId: null,
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: ContactsScreen())),
      ),
    );

    await tester.pump();

    expect(find.text('Khan'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('Not on CHAT APP'), findsOneWidget);
  });
}

class _FakeContactRepository implements ContactRepository {
  _FakeContactRepository({this.contacts = const []});

  final List<Contact> contacts;
  String? name;
  String? phone;

  @override
  Stream<List<Contact>> watchContacts() => Stream.value(contacts);

  @override
  Future<void> saveContact({
    required String displayName,
    required String phoneE164,
  }) async {
    name = displayName;
    phone = phoneE164;
  }

  @override
  Future<void> setMyPhoneIdentity(String phoneE164) async {}

  @override
  Future<List<RegisteredUser>> fetchRegisteredUsers() async => const [];
}
