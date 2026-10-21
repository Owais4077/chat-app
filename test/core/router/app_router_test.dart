import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/core/router/app_router.dart';

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
}
