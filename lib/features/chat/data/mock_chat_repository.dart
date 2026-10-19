import 'dart:async';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/conversation.dart';
class MockChatRepository implements ChatRepository {
  final _messages = <String, List<ChatMessage>>{};
  final _streams = <String, StreamController<List<ChatMessage>>>{};
  @override Stream<List<Conversation>> watchConversations() => Stream.value(const [Conversation(id: 'demo-conversation', title: 'Relay demo')]);
  @override Stream<List<ChatMessage>> watchMessages(String id) { final stream = _streams.putIfAbsent(id, () => StreamController<List<ChatMessage>>.broadcast()); stream.add(List.unmodifiable(_messages[id] ?? [])); return stream.stream; }
  @override Future<ChatMessage> sendTextMessage({required String conversationId, required String text}) async { if (text.trim().isEmpty) throw ArgumentError.value(text, 'text', 'must not be blank'); final message = ChatMessage(id: 'message-${(_messages[conversationId]?.length ?? 0) + 1}', conversationId: conversationId, text: text.trim(), status: MessageStatus.sent, createdAt: DateTime.now()); final list = _messages.putIfAbsent(conversationId, () => []); list.add(message); _streams[conversationId]?.add(List.unmodifiable(list)); return message; }
}
