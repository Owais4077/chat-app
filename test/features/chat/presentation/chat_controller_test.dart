import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/domain/chat_message.dart';
import 'package:relay_messenger/features/chat/domain/chat_repository.dart';
import 'package:relay_messenger/features/chat/domain/conversation.dart';
import 'package:relay_messenger/features/chat/domain/conversation_summary.dart';
import 'package:relay_messenger/features/chat/data/mock_chat_repository.dart';
import 'package:relay_messenger/features/chat/presentation/chat_controller.dart';

void main() {
  test('rejects blank messages with a validation error', () async {
    final controller = ChatController(
      MockChatRepository(),
      'demo-conversation',
    );
    await controller.send('   ');
    expect(controller.error, isNotNull);
  });

  test('updates messages when the conversation stream changes', () async {
    final repository = _StreamingChatRepository();
    final controller = ChatController(repository, 'conversation-1');

    controller.startListening();
    repository.emit([
      ChatMessage(
        id: 'message-1',
        conversationId: 'conversation-1',
        text: 'Incoming message',
        status: MessageStatus.sent,
        createdAt: DateTime.utc(2026),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(controller.messages.single.text, 'Incoming message');
    controller.dispose();
  });
}

class _StreamingChatRepository implements ChatRepository {
  final _messages = StreamController<List<ChatMessage>>.broadcast();

  void emit(List<ChatMessage> messages) => _messages.add(messages);

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
  Future<String> startDirectConversation(String targetUserId) =>
      throw UnimplementedError();

  @override
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) => throw UnimplementedError();

  @override
  Future<void> markConversationRead(String conversationId) async {}

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

  @override
  Stream<List<Conversation>> watchConversations() => const Stream.empty();

  @override
  Stream<List<ConversationSummary>> watchConversationSummaries() =>
      const Stream.empty();

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      _messages.stream;
}
