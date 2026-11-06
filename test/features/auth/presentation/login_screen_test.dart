import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/auth/domain/app_user.dart';
import 'package:relay_messenger/features/auth/domain/auth_repository.dart';
import 'package:relay_messenger/features/auth/presentation/auth_providers.dart';
import 'package:relay_messenger/features/auth/presentation/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  testWidgets('shows a safe incorrect-email-or-password message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_RejectingAuthRepository()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'WrongPass1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('can switch to Phone OTP and request verification code', (
    tester,
  ) async {
    final repository = _RecordingAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Phone OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Send verification code'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '+923001234567');
    await tester.tap(find.text('Send verification code'));
    await tester.pumpAndSettle();

    expect(repository.lastSentPhone, '+923001234567');
    expect(find.text('Verify & Sign in'), findsOneWidget);
  });
}

class _RecordingAuthRepository implements AuthRepository {
  var signInCalls = 0;
  String? lastSentPhone;
  String? lastSentEmail;

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

  @override
  Future<void> sendEmailOtp({required String email}) async {
    lastSentEmail = email;
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {}

  @override
  Future<void> sendPhoneOtp({required String phone}) async {
    lastSentPhone = phone;
  }

  @override
  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {}
}

class _RejectingAuthRepository extends _RecordingAuthRepository {
  @override
  Future<void> signIn({required String email, required String password}) {
    throw const AuthException('Invalid login credentials');
  }
}
