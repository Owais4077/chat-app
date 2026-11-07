import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/domain/chat_message.dart';
import 'package:relay_messenger/features/chat/domain/chat_repository.dart';
import 'package:relay_messenger/features/chat/domain/conversation.dart';
import 'package:relay_messenger/features/chat/domain/conversation_summary.dart';
import 'package:relay_messenger/features/chat/presentation/chat_providers.dart';
import 'package:relay_messenger/features/chat/presentation/conversation_screen.dart';

void main() {
  testWidgets('sends typed message', (tester) async {
    final fakeRepo = _FakeConversationChatRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(fakeRepo)],
        child: MaterialApp(
          home: ConversationScreen(
            repository: fakeRepo,
            conversationId: 'demo-conversation',
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Hi there');
    await tester.tap(find.bySemanticsLabel('Send message'));
    await tester.pump();
    expect(find.text('Hi there'), findsOneWidget);
  });

  testWidgets('marks conversation read on open', (tester) async {
    final fakeRepo = _FakeConversationChatRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(fakeRepo)],
        child: MaterialApp(
          home: ConversationScreen(
            repository: fakeRepo,
            conversationId: 'demo-conversation',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(fakeRepo.markedReadId, 'demo-conversation');
  });

  testWidgets(
    'exposes Group info for group conversation but not for direct conversation',
    (tester) async {
      final fakeRepo = _FakeConversationChatRepository();

      // Test direct conversation
      await tester.pumpWidget(
        ProviderScope(
          overrides: [chatRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            home: ConversationScreen(
              repository: fakeRepo,
              conversationId: 'direct-conv',
              isGroup: false,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Group info'), findsNothing);

      // Test group conversation
      await tester.pumpWidget(
        ProviderScope(
          overrides: [chatRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            home: ConversationScreen(
              repository: fakeRepo,
              conversationId: 'group-conv',
              isGroup: true,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Group info'), findsOneWidget);
    },
  );
}

class _FakeConversationChatRepository implements ChatRepository {
  String? markedReadId;

  @override
  Future<void> markConversationRead(String conversationId) async {
    markedReadId = conversationId;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      Stream.value(const []);

  @override
  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    required String text,
  }) async => ChatMessage(
    id: 'msg-1',
    conversationId: conversationId,
    text: text,
    status: MessageStatus.sent,
    createdAt: DateTime.now(),
  );

  @override
  Future<ChatMessage> sendMediaMessage({
    required String conversationId,
    required String mediaUrl,
    required MessageType type,
  }) async => ChatMessage(
    id: 'media-msg-1',
    conversationId: conversationId,
    text: mediaUrl,
    type: type,
    mediaUrl: mediaUrl,
    status: MessageStatus.sent,
    createdAt: DateTime.now(),
  );

  @override
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) => throw UnimplementedError();

  @override
  Future<String> startDirectConversation(String targetUserId) =>
      throw UnimplementedError();

  @override
  Stream<List<ConversationSummary>> watchConversationSummaries() =>
      Stream.value(const []);

  @override
  Stream<List<Conversation>> watchConversations() => Stream.value(const []);

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
