import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/domain/chat_message.dart';
import 'package:relay_messenger/features/chat/domain/chat_repository.dart';
import 'package:relay_messenger/features/chat/domain/conversation.dart';
import 'package:relay_messenger/features/chat/domain/conversation_summary.dart';
import 'package:relay_messenger/features/chat/presentation/chat_providers.dart';
import 'package:relay_messenger/features/chat/presentation/group_info_screen.dart';

void main() {
  testWidgets('ordinary members cannot see management actions', (tester) async {
    final fakeRepo = _FakeGroupChatRepository(
      members: const [
        GroupMember(
          userId: 'user-1',
          displayName: 'Owner User',
          role: GroupMemberRole.owner,
        ),
        GroupMember(
          userId: 'user-2',
          displayName: 'Regular Member',
          role: GroupMemberRole.member,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(
          home: GroupInfoScreen(
            conversationId: 'group-1',
            myRole: GroupMemberRole.member,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Owner User'), findsOneWidget);
    expect(find.text('Regular Member'), findsOneWidget);

    // Ordinary members must NOT see management buttons
    expect(find.text('Add member'), findsNothing);
    expect(find.text('Remove'), findsNothing);
    expect(find.text('Make admin'), findsNothing);
  });

  testWidgets('owners can see management actions', (tester) async {
    final fakeRepo = _FakeGroupChatRepository(
      members: const [
        GroupMember(
          userId: 'owner-id',
          displayName: 'Owner User',
          role: GroupMemberRole.owner,
        ),
        GroupMember(
          userId: 'member-id',
          displayName: 'Regular Member',
          role: GroupMemberRole.member,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(
          home: GroupInfoScreen(
            conversationId: 'group-1',
            myRole: GroupMemberRole.owner,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add member'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
    expect(find.text('Make admin'), findsOneWidget);

    // Tap Remove
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(fakeRepo.removedUserId, 'member-id');
  });

  testWidgets('failures show safe copy', (tester) async {
    final fakeRepo = _FakeGroupChatRepository(
      members: const [
        GroupMember(
          userId: 'owner-id',
          displayName: 'Owner User',
          role: GroupMemberRole.owner,
        ),
        GroupMember(
          userId: 'member-id',
          displayName: 'Regular Member',
          role: GroupMemberRole.member,
        ),
      ],
      throwOnRemove: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(
          home: GroupInfoScreen(
            conversationId: 'group-1',
            myRole: GroupMemberRole.owner,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Could not update group member.'), findsOneWidget);
  });
}

class _FakeGroupChatRepository implements ChatRepository {
  _FakeGroupChatRepository({
    this.members = const [],
    this.throwOnRemove = false,
  });

  final List<GroupMember> members;
  final bool throwOnRemove;
  String? removedUserId;

  @override
  Future<List<GroupMember>> getGroupMembers(String conversationId) async =>
      members;

  @override
  Future<void> removeGroupMember({
    required String conversationId,
    required String userId,
  }) async {
    if (throwOnRemove) {
      throw Exception('Database constraint violation: 23503');
    }
    removedUserId = userId;
  }

  @override
  Future<void> addGroupMember({
    required String conversationId,
    required String userId,
  }) async {}

  @override
  Future<void> setGroupMemberRole({
    required String conversationId,
    required String userId,
    required GroupMemberRole role,
  }) async {}

  @override
  Future<void> markConversationRead(String conversationId) async {}

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      Stream.value(const []);

  @override
  Stream<List<ConversationSummary>> watchConversationSummaries() =>
      Stream.value(const []);

  @override
  Stream<List<Conversation>> watchConversations() => Stream.value(const []);

  @override
  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    required String text,
  }) => throw UnimplementedError();

  @override
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) => throw UnimplementedError();

  @override
  Future<String> startDirectConversation(String targetUserId) =>
      throw UnimplementedError();
}

