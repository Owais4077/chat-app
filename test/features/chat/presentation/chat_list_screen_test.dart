import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/domain/chat_message.dart';
import 'package:relay_messenger/features/chat/domain/chat_repository.dart';
import 'package:relay_messenger/features/chat/domain/conversation.dart';
import 'package:relay_messenger/features/chat/domain/conversation_summary.dart';
import 'package:relay_messenger/features/chat/presentation/chat_list_screen.dart';
import 'package:relay_messenger/features/chat/presentation/chat_providers.dart';

void main() {
  testWidgets('shows an empty conversations state', (tester) async {
    final fakeRepo = _FakeChatRepository(summaries: const []);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: ChatListScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('No conversations yet'), findsOneWidget);
  });

  testWidgets(
    'renders conversation summaries with title, preview, icon, and positive-only unread badge',
    (tester) async {
      final fakeRepo = _FakeChatRepository(
        summaries: [
          const ConversationSummary(
            id: 'direct-1',
            isGroup: false,
            title: 'Alice',
            lastMessagePreview: 'Hey there',
            lastMessageAt: null,
            unreadCount: 0,
            myRole: GroupMemberRole.member,
          ),
          const ConversationSummary(
            id: 'group-1',
            isGroup: true,
            title: 'Project Team',
            lastMessagePreview: 'Meeting at 3',
            lastMessageAt: null,
            unreadCount: 4,
            myRole: GroupMemberRole.owner,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [chatRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(home: ChatListScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Hey there'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      expect(find.text('Project Team'), findsOneWidget);
      expect(find.text('Meeting at 3'), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);

      expect(find.text('4'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    },
  );

  testWidgets('shows menu actions for new message and new group', (
    tester,
  ) async {
    final fakeRepo = _FakeChatRepository(summaries: const []);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: ChatListScreen()),
      ),
    );
    await tester.pump();

    final menuButton = find.byType(PopupMenuButton<String>);
    expect(menuButton, findsOneWidget);
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(find.text('New message'), findsOneWidget);
    expect(find.text('New group'), findsOneWidget);
  });
}

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({required this.summaries});

  final List<ConversationSummary> summaries;

  @override
  Stream<List<ConversationSummary>> watchConversationSummaries() =>
      Stream.value(summaries);

  @override
  Stream<List<Conversation>> watchConversations() => Stream.value(const []);

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      const Stream.empty();

  @override
  Future<String> startDirectConversation(String targetUserId) =>
      throw UnimplementedError();

  @override
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) => throw UnimplementedError();

  @override
  Future<void> markConversationRead(String conversationId) =>
      throw UnimplementedError();

  @override
  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    required String text,
  }) => throw UnimplementedError();
}
