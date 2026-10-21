import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/contacts/domain/contact_repository.dart';
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
}

class _FakeContactRepository implements ContactRepository {
  String? name;
  String? phone;

  @override
  Future<void> saveContact({required String displayName, required String phoneE164}) async {
    name = displayName;
    phone = phoneE164;
  }
}
