enum MessageStatus { sent, delivered, read }

enum MessageType { text, image, video, audio, document }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.status,
    required this.createdAt,
    this.senderId,
    this.type = MessageType.text,
    this.mediaUrl,
  });

  factory ChatMessage.fromSupabaseRow(Map<String, dynamic> row) {
    final typeStr = row['type'] as String? ?? 'text';
    final type = switch (typeStr) {
      'image' => MessageType.image,
      'video' => MessageType.video,
      'audio' => MessageType.audio,
      'document' => MessageType.document,
      _ => MessageType.text,
    };
    final content = (row['content'] as String? ?? '').trim();

    return ChatMessage(
      id: row['id'] as String,
      conversationId: row['conversation_id'] as String,
      senderId: row['sender_id'] as String?,
      text: content,
      type: type,
      mediaUrl: type != MessageType.text ? content : null,
      status: MessageStatus.sent,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final String id;
  final String conversationId;
  final String? senderId;
  final String text;
  final MessageType type;
  final String? mediaUrl;
  final MessageStatus status;
  final DateTime createdAt;
}
