import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/202610220002_private_and_group_chat.sql',
  );

  test('private and group chat migration protects privileged RPCs', () {
    final sql = migration.readAsStringSync();

    expect(sql, contains('get_or_create_direct_conversation'));
    expect(sql, contains('create_group_conversation'));
    expect(sql, contains('add_group_member'));
    expect(sql, contains('remove_group_member'));
    expect(sql, contains('set_group_member_role'));
    expect(sql, contains('mark_conversation_read'));
    expect(sql, contains('get_conversation_summaries'));
    expect(sql, contains('security definer'));
    expect(sql, contains('set search_path = public'));
    expect(sql, contains('auth.uid()'));
    expect(sql, contains('target_user_id = auth.uid()'));
    expect(sql, contains('public.user_blocked'));
    expect(sql, contains('last owner'));
    expect(sql, contains('conversation_members'));
    expect(sql, contains('revoke all on function'));
    expect(sql, contains('grant execute on function'));
  });
}
