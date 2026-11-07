import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/conversation.dart';
import '../domain/conversation_summary.dart';

abstract interface class ChatDataSource {
  Stream<List<Map<String, dynamic>>> watchConversationRows();
  Stream<List<Map<String, dynamic>>> watchConversationSummaryRows();
  Stream<List<Map<String, dynamic>>> watchMessageRows(String conversationId);
  Future<String> createDirectConversation(String targetUserId);
  Future<String> createGroupConversation({
    required String name,
    required List<String> memberIds,
  });
  Future<void> markConversationRead(String conversationId);
  Future<Map<String, dynamic>> insertTextMessage({
    required String conversationId,
    required String text,
  });
  Future<Map<String, dynamic>> insertMediaMessage({
    required String conversationId,
    required String mediaUrl,
    required String type,
  });
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String conversationId);
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
    required String role,
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
  Stream<List<ConversationSummary>> watchConversationSummaries() =>
      _source.watchConversationSummaryRows().map(
        (rows) => rows
            .map(ConversationSummary.fromSupabaseRow)
            .toList(growable: false),
      );

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _source
        .watchMessageRows(conversationId)
        .map(
          (rows) =>
              rows.map(ChatMessage.fromSupabaseRow).toList(growable: false),
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

  @override
  Future<ChatMessage> sendMediaMessage({
    required String conversationId,
    required String mediaUrl,
    required MessageType type,
  }) async {
    final row = await _source.insertMediaMessage(
      conversationId: conversationId,
      mediaUrl: mediaUrl,
      type: type.name,
    );
    return ChatMessage.fromSupabaseRow(row);
  }

  @override
  Future<String> startDirectConversation(String targetUserId) {
    if (targetUserId.trim().isEmpty) {
      throw ArgumentError.value(
        targetUserId,
        'targetUserId',
        'must not be blank',
      );
    }
    return _source.createDirectConversation(targetUserId);
  }

  @override
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
    final normalizedMemberIds = memberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedMemberIds.isEmpty) {
      throw ArgumentError.value(
        memberIds,
        'memberIds',
        'must contain at least one member',
      );
    }
    return _source.createGroupConversation(
      name: normalizedName,
      memberIds: normalizedMemberIds,
    );
  }

  @override
  Future<void> markConversationRead(String conversationId) =>
      _source.markConversationRead(conversationId);

  @override
  Future<List<GroupMember>> getGroupMembers(String conversationId) async {
    final rows = await _source.fetchGroupMembers(conversationId);
    return rows.map(GroupMember.fromRow).toList(growable: false);
  }

  @override
  Future<void> addGroupMember({
    required String conversationId,
    required String userId,
  }) => _source.addGroupMember(conversationId: conversationId, userId: userId);

  @override
  Future<void> removeGroupMember({
    required String conversationId,
    required String userId,
  }) =>
      _source.removeGroupMember(conversationId: conversationId, userId: userId);

  @override
  Future<void> setGroupMemberRole({
    required String conversationId,
    required String userId,
    required GroupMemberRole role,
  }) => _source.setGroupMemberRole(
    conversationId: conversationId,
    userId: userId,
    role: role.name,
  );
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
  Stream<List<Map<String, dynamic>>> watchConversationSummaryRows() async* {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    yield await _fetchConversationSummaryRows();
    await for (final _
        in _client
            .from('conversation_members')
            .stream(primaryKey: const ['conversation_id', 'user_id'])
            .eq('user_id', userId)) {
      yield await _fetchConversationSummaryRows();
    }
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

  @override
  Future<Map<String, dynamic>> insertMediaMessage({
    required String conversationId,
    required String mediaUrl,
    required String type,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('A signed-in user is required.');
    final row = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'type': type,
          'content': mediaUrl,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<String> createDirectConversation(String targetUserId) async {
    final response = await _client.rpc(
      'get_or_create_direct_conversation',
      params: {'target_user_id': targetUserId},
    );
    return response as String;
  }

  @override
  Future<String> createGroupConversation({
    required String name,
    required List<String> memberIds,
  }) async {
    final response = await _client.rpc(
      'create_group_conversation',
      params: {'group_name': name, 'member_ids': memberIds},
    );
    return response as String;
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    await _client.rpc(
      'mark_conversation_read',
      params: {'target_conversation_id': conversationId},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGroupMembers(
    String conversationId,
  ) async {
    final response = await _client
        .from('conversation_members')
        .select('user_id, role, profiles(display_name)')
        .eq('conversation_id', conversationId);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> addGroupMember({
    required String conversationId,
    required String userId,
  }) async {
    await _client.rpc(
      'add_group_member',
      params: {
        'target_conversation_id': conversationId,
        'target_user_id': userId,
      },
    );
  }

  @override
  Future<void> removeGroupMember({
    required String conversationId,
    required String userId,
  }) async {
    await _client.rpc(
      'remove_group_member',
      params: {
        'target_conversation_id': conversationId,
        'target_user_id': userId,
      },
    );
  }

  @override
  Future<void> setGroupMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  }) async {
    await _client.rpc(
      'set_group_member_role',
      params: {
        'target_conversation_id': conversationId,
        'target_user_id': userId,
        'target_role': role,
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchConversationSummaryRows() async {
    final response = await _client.rpc('get_conversation_summaries');
    return List<Map<String, dynamic>>.from(response as List);
  }
}
