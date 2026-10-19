enum MessageStatus { sent, delivered, read }
class ChatMessage { const ChatMessage({required this.id, required this.conversationId, required this.text, required this.status, required this.createdAt}); final String id; final String conversationId; final String text; final MessageStatus status; final DateTime createdAt; }
