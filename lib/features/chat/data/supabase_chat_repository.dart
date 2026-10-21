import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/conversation.dart';

abstract interface class ChatDataSource {
  Stream<List<Map<String, dynamic>>> watchConversationRows();
  Stream<List<Map<String, dynamic>>> watchMessageRows(String conversationId);
  Future<Map<String, dynamic>> insertTextMessage({
    required String conversationId,
    required String text,
  });
}

class SupabaseChatRepository implements ChatRepository {
  const SupabaseChatRepository(this._source);

  final ChatDataSource _source;

  @override
  Stream<List<Conversation>> watchConversations() {
    return _source.watchConversationRows().map(
      (rows) => rows
          .map(
            (row) => Conversation(
              id: row['conversation_id'] as String,
              title: 'Conversation',
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _source.watchMessageRows(conversationId).map(
          (rows) => rows
              .map(ChatMessage.fromSupabaseRow)
              .toList(growable: false),
        );
  }

  @override
  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    required String text,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be blank');
    }
    final row = await _source.insertTextMessage(
      conversationId: conversationId,
      text: normalized,
    );
    return ChatMessage.fromSupabaseRow(row);
  }
}

class SupabaseChatDataSource implements ChatDataSource {
  const SupabaseChatDataSource(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<Map<String, dynamic>>> watchConversationRows() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _client
        .from('conversation_members')
        .stream(primaryKey: const ['conversation_id', 'user_id'])
        .eq('user_id', userId)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMessageRows(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: const ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  @override
  Future<Map<String, dynamic>> insertTextMessage({
    required String conversationId,
    required String text,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('A signed-in user is required.');
    final row = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'content': text,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }
}
