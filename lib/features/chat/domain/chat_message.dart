enum MessageStatus { sent, delivered, read }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.status,
    required this.createdAt,
    this.senderId,
  });

  factory ChatMessage.fromSupabaseRow(Map<String, dynamic> row) {
    return ChatMessage(
      id: row['id'] as String,
      conversationId: row['conversation_id'] as String,
      senderId: row['sender_id'] as String?,
      text: (row['content'] as String).trim(),
      status: MessageStatus.sent,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final String id;
  final String conversationId;
  final String? senderId;
  final String text;
  final MessageStatus status;
  final DateTime createdAt;
}
