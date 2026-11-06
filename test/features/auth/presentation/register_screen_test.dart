import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/auth/domain/app_user.dart';
import 'package:relay_messenger/features/auth/domain/auth_repository.dart';
import 'package:relay_messenger/features/auth/presentation/auth_providers.dart';
import 'package:relay_messenger/features/auth/presentation/register_screen.dart';

void main() {
  testWidgets(
    'registration explains email confirmation when Supabase requires it',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_ConfirmationRepository()),
          ],
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'new@relay.dev');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();

      expect(
        find.text('Check your email to confirm your account.'),
        findsOneWidget,
      );
    },
  );

  test('maps an already-registered email to safe account guidance', () {
    expect(
      registrationErrorMessage('User already registered'),
      'An account already exists for this email. Sign in instead.',
    );
  });

  test('explains when Supabase has disabled email sign-up', () {
    expect(
      registrationErrorMessage('Email signups are disabled'),
      'Email sign-up is disabled in Supabase. Enable the Email provider and try again.',
    );
  });

  testWidgets(
    'rejects passwords that do not meet the configured character policy',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_ConfirmationRepository()),
          ],
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'new@relay.dev');
      await tester.enterText(find.byType(TextFormField).at(1), 'lowercase1');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();

      expect(
        find.text('Use uppercase, lowercase letters, and a number.'),
        findsOneWidget,
      );
    },
  );
}

class _ConfirmationRepository implements AuthRepository {
  @override
  Stream<AppUser?> authStateChanges() => const Stream.empty();
  @override
  AppUser? currentUser() => null;
  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async => SignUpResult.confirmationRequired;
  @override
  Future<void> sendEmailOtp({required String email}) async {}
  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {}
  @override
  Future<void> sendPhoneOtp({required String phone}) async {}
  @override
  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {}
}
