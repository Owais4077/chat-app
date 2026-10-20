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
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();

      expect(
        find.text('Check your email to confirm your account.'),
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
}
