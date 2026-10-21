import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/domain/conversation_summary.dart';

void main() {
  test('maps a safe conversation summary row', () {
    final summary = ConversationSummary.fromSupabaseRow({
      'conversation_id': 'conversation-1',
      'is_group': true,
      'title': 'Project Team',
      'last_message_preview': null,
      'last_message_at': '2026-10-22T08:00:00.000Z',
      'unread_count': 2,
      'my_role': 'admin',
    });

    expect(summary.id, 'conversation-1');
    expect(summary.isGroup, isTrue);
    expect(summary.title, 'Project Team');
    expect(summary.lastMessagePreview, '');
    expect(summary.unreadCount, 2);
    expect(summary.myRole, GroupMemberRole.admin);
  });
}
