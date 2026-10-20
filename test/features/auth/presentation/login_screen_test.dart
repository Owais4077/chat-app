import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/auth/domain/app_user.dart';
import 'package:relay_messenger/features/auth/domain/auth_repository.dart';
import 'package:relay_messenger/features/auth/presentation/auth_providers.dart';
import 'package:relay_messenger/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('blank login fields show validation without a sign-in request', (
    tester,
  ) async {
    final repository = _RecordingAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });
}

class _RecordingAuthRepository implements AuthRepository {
  var signInCalls = 0;

  @override
  Stream<AppUser?> authStateChanges() => const Stream.empty();

  @override
  AppUser? currentUser() => null;

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async => SignUpResult.authenticated;
}
