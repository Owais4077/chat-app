import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/domain/chat_message.dart';

void main() {
  test('maps a live Supabase text-message row to a sent chat message', () {
    final message = ChatMessage.fromSupabaseRow({
      'id': 'message-1',
      'conversation_id': 'conversation-1',
      'content': ' Hello from CHAT APP ',
      'created_at': '2026-10-21T20:00:00.000Z',
    });

    expect(message.id, 'message-1');
    expect(message.conversationId, 'conversation-1');
    expect(message.text, 'Hello from CHAT APP');
    expect(message.status, MessageStatus.sent);
    expect(message.createdAt, DateTime.utc(2026, 10, 21, 20));
  });
}
