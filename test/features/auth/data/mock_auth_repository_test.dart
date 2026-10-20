import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/auth/data/mock_auth_repository.dart';
import 'package:relay_messenger/features/auth/domain/app_user.dart';
import 'package:relay_messenger/features/auth/domain/auth_repository.dart';

void main() {
  test('sign in publishes an authenticated app user', () async {
    final repository = MockAuthRepository();
    final futureUser = repository.authStateChanges().first;

    await repository.signIn(email: 'demo@relay.dev', password: 'password123');

    expect(await futureUser, isA<AppUser>());
  });

  test(
    'sign up reports an authenticated session in the mock repository',
    () async {
      final repository = MockAuthRepository();

      final result = await repository.signUp(
        email: 'new@relay.dev',
        password: 'password123',
      );

      expect(result, SignUpResult.authenticated);
    },
  );
}
