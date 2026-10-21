import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone contacts migration keeps phone identities and contacts private', () {
    final sql = File(
      'supabase/migrations/202610220001_phone_contacts.sql',
    ).readAsStringSync();

    expect(sql, contains('create table public.phone_identities'));
    expect(sql, contains('phone_e164 text not null unique'));
    expect(sql, contains('alter table public.phone_identities enable row level security'));
    expect(sql, contains('create table public.contacts'));
    expect(sql, contains('unique (owner_id, phone_e164)'));
    expect(sql, contains('alter table public.contacts enable row level security'));
    expect(sql, contains('owner_id = auth.uid()'));
    expect(sql, contains('security definer'));
    expect(sql, contains('set search_path = public'));
    expect(sql, isNot(contains('profiles.phone_e164')));
  });
}
