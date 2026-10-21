import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/data/supabase_chat_repository.dart';
import 'package:relay_messenger/features/chat/domain/chat_message.dart';

void main() {
  test('maps watched Supabase rows into live chat messages', () async {
    final repository = SupabaseChatRepository(
      _FakeChatDataSource(
        messageRows: Stream.value([
          {
            'id': 'message-1',
            'conversation_id': 'conversation-1',
            'content': 'Hello',
            'created_at': '2026-10-21T20:00:00.000Z',
          },
        ]),
      ),
    );

    final messages = await repository.watchMessages('conversation-1').first;

    expect(messages.single.text, 'Hello');
    expect(messages.single.status, MessageStatus.sent);
  });

  test('trims text before inserting a live message', () async {
    final source = _FakeChatDataSource();
    final repository = SupabaseChatRepository(source);

    await repository.sendTextMessage(
      conversationId: 'conversation-1',
      text: '  Hello  ',
    );

    expect(source.insertedText, 'Hello');
  });
}

class _FakeChatDataSource implements ChatDataSource {
  _FakeChatDataSource({Stream<List<Map<String, dynamic>>>? messageRows})
    : _messageRows = messageRows ?? const Stream.empty();

  final Stream<List<Map<String, dynamic>>> _messageRows;
  String? insertedText;

  @override
  Future<Map<String, dynamic>> insertTextMessage({
    required String conversationId,
    required String text,
  }) async {
    insertedText = text;
    return {
      'id': 'message-2',
      'conversation_id': conversationId,
      'content': text,
      'created_at': '2026-10-21T20:00:00.000Z',
    };
  }

  @override
  Stream<List<Map<String, dynamic>>> watchConversationRows() =>
      const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> watchMessageRows(String conversationId) =>
      _messageRows;
}
