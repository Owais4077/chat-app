import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/domain/chat_message.dart';
import 'package:relay_messenger/features/chat/domain/chat_repository.dart';
import 'package:relay_messenger/features/chat/domain/conversation.dart';
import 'package:relay_messenger/features/chat/domain/conversation_summary.dart';
import 'package:relay_messenger/features/chat/presentation/chat_providers.dart';
import 'package:relay_messenger/features/chat/presentation/create_group_screen.dart';
import 'package:relay_messenger/features/contacts/domain/contact.dart';
import 'package:relay_messenger/features/contacts/domain/registered_user.dart';
import 'package:relay_messenger/features/contacts/domain/contact_repository.dart';
import 'package:relay_messenger/features/contacts/presentation/contacts_providers.dart';

void main() {
  testWidgets(
    'blank group name shows validation without invoking createGroup',
    (tester) async {
      final chatRepo = _FakeChatRepository();
      final contactRepo = _FakeContactRepository(
        contacts: const [
          Contact(
            id: 'contact-1',
            displayName: 'Bob',
            phoneE164: '+923001234567',
            registeredUserId: 'user-bob',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(chatRepo),
            contactRepositoryProvider.overrideWithValue(contactRepo),
          ],
          child: const MaterialApp(home: CreateGroupScreen()),
        ),
      );
      await tester.pump();

      // Select member Bob
      await tester.tap(find.text('Bob'));
      await tester.pump();

      // Tap Create group without entering a name
      await tester.tap(find.widgetWithText(FilledButton, 'Create group'));
      await tester.pump();

      expect(find.text('Enter a group name'), findsOneWidget);
      expect(chatRepo.createGroupCalled, isFalse);
    },
  );

  testWidgets(
    'no members selected shows validation without invoking createGroup',
    (tester) async {
      final chatRepo = _FakeChatRepository();
      final contactRepo = _FakeContactRepository(
        contacts: const [
          Contact(
            id: 'contact-1',
            displayName: 'Bob',
            phoneE164: '+923001234567',
            registeredUserId: 'user-bob',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(chatRepo),
            contactRepositoryProvider.overrideWithValue(contactRepo),
          ],
          child: const MaterialApp(home: CreateGroupScreen()),
        ),
      );
      await tester.pump();

      // Enter name
      await tester.enterText(
        find.widgetWithText(TextField, 'Group name'),
        'Core Team',
      );
      // Tap Create group without selecting any members
      await tester.tap(find.widgetWithText(FilledButton, 'Create group'));
      await tester.pump();

      expect(find.text('Select at least one member'), findsOneWidget);
      expect(chatRepo.createGroupCalled, isFalse);
    },
  );

  testWidgets(
    'valid name and selected registered contacts invokes createGroup',
    (tester) async {
      final chatRepo = _FakeChatRepository();
      final contactRepo = _FakeContactRepository(
        contacts: const [
          Contact(
            id: 'c-1',
            displayName: 'Bob',
            phoneE164: '+923001234567',
            registeredUserId: 'user-bob',
          ),
          Contact(
            id: 'c-2',
            displayName: 'Alice',
            phoneE164: '+923007654321',
            registeredUserId: 'user-alice',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(chatRepo),
            contactRepositoryProvider.overrideWithValue(contactRepo),
          ],
          child: const MaterialApp(home: CreateGroupScreen()),
        ),
      );
      await tester.pump();

      // Enter name
      await tester.enterText(
        find.widgetWithText(TextField, 'Group name'),
        'Developers',
      );

      // Select Bob
      await tester.tap(find.text('Bob'));
      await tester.pump();

      // Tap Create group
      await tester.tap(find.widgetWithText(FilledButton, 'Create group'));
      await tester.pump();

      expect(chatRepo.createGroupCalled, isTrue);
      expect(chatRepo.lastCreatedName, 'Developers');
      expect(chatRepo.lastCreatedMemberIds, ['user-bob']);
    },
  );
}

class _FakeChatRepository implements ChatRepository {
  bool createGroupCalled = false;
  String? lastCreatedName;
  List<String>? lastCreatedMemberIds;

  @override
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    createGroupCalled = true;
    lastCreatedName = name;
    lastCreatedMemberIds = memberIds;
    return 'group-123';
  }

  @override
  Stream<List<ConversationSummary>> watchConversationSummaries() =>
      Stream.value(const []);

  @override
  Stream<List<Conversation>> watchConversations() => Stream.value(const []);

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      const Stream.empty();

  @override
  Future<String> startDirectConversation(String targetUserId) =>
      throw UnimplementedError();

  @override
  Future<void> markConversationRead(String conversationId) =>
      throw UnimplementedError();

  @override
  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    required String text,
  }) => throw UnimplementedError();

  @override
  Future<ChatMessage> sendMediaMessage({
    required String conversationId,
    required String mediaUrl,
    required MessageType type,
  }) => throw UnimplementedError();

  @override
  Future<List<GroupMember>> getGroupMembers(String conversationId) async =>
      const [];

  @override
  Future<void> addGroupMember({
    required String conversationId,
    required String userId,
  }) async {}

  @override
  Future<void> removeGroupMember({
    required String conversationId,
    required String userId,
  }) async {}

  @override
  Future<void> setGroupMemberRole({
    required String conversationId,
    required String userId,
    required GroupMemberRole role,
  }) async {}
}

class _FakeContactRepository implements ContactRepository {
  const _FakeContactRepository({this.contacts = const []});

  final List<Contact> contacts;

  @override
  Stream<List<Contact>> watchContacts() => Stream.value(contacts);

  @override
  Future<void> saveContact({
    required String displayName,
    required String phoneE164,
  }) async {}

  @override
  Future<void> setMyPhoneIdentity(String phoneE164) async {}

  @override
  Future<List<RegisteredUser>> fetchRegisteredUsers() async => const [];
}
