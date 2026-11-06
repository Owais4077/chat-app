import 'dart:async';

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
  testWidgets('shows conversations supplied by the live chat repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(
            _FakeChatRepository(const [
              Conversation(id: 'conversation-1', title: 'Khan'),
            ]),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ChatListScreen())),
      ),
    );

    await tester.pump();

    expect(find.text('Khan'), findsOneWidget);
  });
}

class _FakeChatRepository implements ChatRepository {
  const _FakeChatRepository(this.conversations);

  final List<Conversation> conversations;

  @override
  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    required String text,
  }) => throw UnimplementedError();

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
  Stream<List<Conversation>> watchConversations() =>
      Stream.value(conversations);

  @override
  Stream<List<ConversationSummary>> watchConversationSummaries() =>
      Stream.value(
        conversations
            .map(
              (c) => ConversationSummary(
                id: c.id,
                isGroup: false,
                title: c.title,
                lastMessagePreview: '',
                lastMessageAt: null,
                unreadCount: 0,
                myRole: GroupMemberRole.member,
              ),
            )
            .toList(),
      );

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      const Stream.empty();

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
