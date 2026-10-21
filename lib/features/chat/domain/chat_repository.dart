import 'chat_message.dart';
import 'conversation.dart';
import 'conversation_summary.dart';

abstract interface class ChatRepository {
  Stream<List<Conversation>> watchConversations();
  Stream<List<ConversationSummary>> watchConversationSummaries();
  Stream<List<ChatMessage>> watchMessages(String conversationId);
  Future<String> startDirectConversation(String targetUserId);
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  });
  Future<void> markConversationRead(String conversationId);
  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    required String text,
  });
}
