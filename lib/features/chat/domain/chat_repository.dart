import 'chat_message.dart';
import 'conversation.dart';
abstract interface class ChatRepository { Stream<List<Conversation>> watchConversations(); Stream<List<ChatMessage>> watchMessages(String conversationId); Future<ChatMessage> sendTextMessage({required String conversationId, required String text}); }
