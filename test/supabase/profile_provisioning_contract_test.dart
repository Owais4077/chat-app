import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile provisioning migration creates a safe auth user trigger', () {
    final sql = File('supabase/migrations/202610210001_create_profile_on_signup.sql').readAsStringSync();

    expect(sql, contains('security definer'));
    expect(sql, contains('set search_path = public'));
    expect(sql, contains('insert into public.profiles'));
    expect(sql, contains('new.id'));
    expect(sql, contains('after insert on auth.users'));
  });
}
