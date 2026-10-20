import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial migration declares messaging security boundaries', () {
    final migration = File('supabase/migrations/202610200001_initial_messaging_schema.sql')
        .readAsStringSync();

    expect(migration, contains('alter table public.messages enable row level security'));
    expect(migration, contains('conversation_member'));
    expect(migration, contains('create index messages_conversation_created_at_idx'));
  });
}
