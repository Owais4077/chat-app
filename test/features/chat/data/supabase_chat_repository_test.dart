import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/data/supabase_chat_repository.dart';
import 'package:relay_messenger/features/chat/domain/chat_message.dart';
import 'package:relay_messenger/features/chat/domain/conversation_summary.dart';

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

  test(
    'starts a direct conversation through the protected data source',
    () async {
      final source = _FakeChatDataSource();
      final repository = SupabaseChatRepository(source);

      final conversationId = await repository.startDirectConversation('user-2');

      expect(conversationId, 'conversation-2');
      expect(source.directTargetUserId, 'user-2');
    },
  );

  test('rejects a blank group name before calling Supabase', () async {
    final source = _FakeChatDataSource();
    final repository = SupabaseChatRepository(source);

    expect(
      () => repository.createGroup(name: '   ', memberIds: const ['user-2']),
      throwsArgumentError,
    );
    expect(source.createdGroupName, isNull);
  });

  test('maps live summary rows into conversation summaries', () async {
    final repository = SupabaseChatRepository(
      _FakeChatDataSource(
        summaryRows: Stream.value([
          {
            'conversation_id': 'conversation-1',
            'is_group': false,
            'title': 'Ayesha',
            'last_message_preview': 'Hi',
            'last_message_at': '2026-10-22T08:00:00.000Z',
            'unread_count': 1,
            'my_role': 'owner',
          },
        ]),
      ),
    );

    final summaries = await repository.watchConversationSummaries().first;

    expect(summaries.single.title, 'Ayesha');
    expect(summaries.single.myRole, GroupMemberRole.owner);
  });
}

class _FakeChatDataSource implements ChatDataSource {
  _FakeChatDataSource({
    Stream<List<Map<String, dynamic>>>? messageRows,
    Stream<List<Map<String, dynamic>>>? summaryRows,
  }) : _messageRows = messageRows ?? const Stream.empty(),
       _summaryRows = summaryRows ?? const Stream.empty();

  final Stream<List<Map<String, dynamic>>> _messageRows;
  final Stream<List<Map<String, dynamic>>> _summaryRows;
  String? insertedText;
  String? directTargetUserId;
  String? createdGroupName;

  @override
  Future<String> createDirectConversation(String targetUserId) async {
    directTargetUserId = targetUserId;
    return 'conversation-2';
  }

  @override
  Future<String> createGroupConversation({
    required String name,
    required List<String> memberIds,
  }) async {
    createdGroupName = name;
    return 'group-1';
  }

  @override
  Future<void> markConversationRead(String conversationId) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchGroupMembers(
    String conversationId,
  ) async => const [];

  @override
  Future<void> addGroupMember({
    required String conversationId,
    required String userId,
  }) async {}

  @override
  Future<void> removeGroupMember({
    required String conversationId,
    required String userId,
  }) async {}

  @override
  Future<void> setGroupMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  }) async {}

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
  Future<Map<String, dynamic>> insertMediaMessage({
    required String conversationId,
    required String mediaUrl,
    required String type,
  }) async {
    insertedText = mediaUrl;
    return {
      'id': 'message-3',
      'conversation_id': conversationId,
      'content': mediaUrl,
      'type': type,
      'created_at': '2026-10-21T20:00:00.000Z',
    };
  }

  @override
  Stream<List<Map<String, dynamic>>> watchConversationRows() =>
      const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> watchConversationSummaryRows() =>
      _summaryRows;

  @override
  Stream<List<Map<String, dynamic>>> watchMessageRows(String conversationId) =>
      _messageRows;
}
