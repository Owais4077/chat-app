import 'chat_message.dart';
import 'conversation.dart';
import 'conversation_summary.dart';

abstract class ChatRepository {
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
  Future<ChatMessage> sendMediaMessage({
    required String conversationId,
    required String mediaUrl,
    required MessageType type,
  }) async => sendTextMessage(conversationId: conversationId, text: mediaUrl);
  Future<List<GroupMember>> getGroupMembers(String conversationId);
  Future<void> addGroupMember({
    required String conversationId,
    required String userId,
  });
  Future<void> removeGroupMember({
    required String conversationId,
    required String userId,
  });
  Future<void> setGroupMemberRole({
    required String conversationId,
    required String userId,
    required GroupMemberRole role,
  });
}
