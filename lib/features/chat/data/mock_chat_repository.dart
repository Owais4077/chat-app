import 'dart:async';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/conversation.dart';
import '../domain/conversation_summary.dart';

class MockChatRepository implements ChatRepository {
  final _messages = <String, List<ChatMessage>>{};
  final _streams = <String, StreamController<List<ChatMessage>>>{};
  final _groupMembers = <String, List<GroupMember>>{};

  @override
  Stream<List<Conversation>> watchConversations() => Stream.value(const []);

  @override
  Stream<List<ConversationSummary>> watchConversationSummaries() =>
      Stream.value(const []);

  @override
  Future<String> startDirectConversation(String targetUserId) async =>
      'direct-$targetUserId';

  @override
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) async => 'mock-group';

  @override
  Future<void> markConversationRead(String conversationId) async {}

  @override
  Stream<List<ChatMessage>> watchMessages(String id) {
    final stream = _streams.putIfAbsent(
      id,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
    stream.add(List.unmodifiable(_messages[id] ?? []));
    return stream.stream;
  }

  @override
  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be blank');
    }
    final message = ChatMessage(
      id: 'message-${(_messages[conversationId]?.length ?? 0) + 1}',
      conversationId: conversationId,
      senderId: 'demo-user',
      text: text.trim(),
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );
    final list = _messages.putIfAbsent(conversationId, () => []);
    list.add(message);
    _streams[conversationId]?.add(List.unmodifiable(list));
    return message;
  }

  @override
  Future<ChatMessage> sendMediaMessage({
    required String conversationId,
    required String mediaUrl,
    required MessageType type,
  }) async {
    final message = ChatMessage(
      id: 'message-${(_messages[conversationId]?.length ?? 0) + 1}',
      conversationId: conversationId,
      senderId: 'demo-user',
      text: mediaUrl,
      type: type,
      mediaUrl: mediaUrl,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );
    final list = _messages.putIfAbsent(conversationId, () => []);
    list.add(message);
    _streams[conversationId]?.add(List.unmodifiable(list));
    return message;
  }

  @override
  Future<List<GroupMember>> getGroupMembers(String conversationId) async =>
      _groupMembers[conversationId] ?? const [];

  @override
  Future<void> addGroupMember({
    required String conversationId,
    required String userId,
  }) async {
    final list = _groupMembers.putIfAbsent(conversationId, () => []);
    list.add(
      GroupMember(
        userId: userId,
        displayName: 'Member $userId',
        role: GroupMemberRole.member,
      ),
    );
  }

  @override
  Future<void> removeGroupMember({
    required String conversationId,
    required String userId,
  }) async {
    _groupMembers[conversationId]?.removeWhere((m) => m.userId == userId);
  }

  @override
  Future<void> setGroupMemberRole({
    required String conversationId,
    required String userId,
    required GroupMemberRole role,
  }) async {
    final list = _groupMembers[conversationId];
    if (list != null) {
      final index = list.indexWhere((m) => m.userId == userId);
      if (index != -1) {
        list[index] = GroupMember(
          userId: userId,
          displayName: list[index].displayName,
          role: role,
        );
      }
    }
  }
}
