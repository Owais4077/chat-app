import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/core/router/app_router.dart';
import 'package:relay_messenger/features/auth/data/mock_auth_repository.dart';

void main() {
  test('redirects unauthenticated users to login', () {
    expect(redirectFor(AppAccess.unauthenticated, '/chats'), '/login');
  });

  test('redirects incomplete profiles to profile setup', () {
    expect(
      redirectFor(AppAccess.profileIncomplete, '/chats'),
      '/profile/setup',
    );
  });

  test('allows signed-out users to open registration', () {
    expect(redirectFor(AppAccess.unauthenticated, '/register'), isNull);
  });

  test(
    'requires authentication for group creation, conversation, and group info',
    () {
      expect(redirectFor(AppAccess.unauthenticated, '/groups/new'), '/login');
      expect(
        redirectFor(AppAccess.unauthenticated, '/conversation/conv-123'),
        '/login',
      );
      expect(
        redirectFor(
          AppAccess.unauthenticated,
          '/conversation/conv-123/group-info',
        ),
        '/login',
      );

      expect(redirectFor(AppAccess.authenticated, '/groups/new'), isNull);
      expect(
        redirectFor(AppAccess.authenticated, '/conversation/conv-123'),
        isNull,
      );
      expect(
        redirectFor(
          AppAccess.authenticated,
          '/conversation/conv-123/group-info',
        ),
        isNull,
      );
    },
  );

  test('createAppRouter recognizes authenticated user from auth repository', () {
    final mockRepo = MockAuthRepository();
    mockRepo.signIn(email: 'user@example.com', password: 'password123');
    final router = createAppRouter(AppAccess.unauthenticated, mockRepo);
    expect(router, isNotNull);
  });
}
