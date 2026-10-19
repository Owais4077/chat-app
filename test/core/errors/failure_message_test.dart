import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/core/errors/app_failure.dart';
import 'package:relay_messenger/core/errors/failure_message.dart';

void main() {
  test('maps an unauthorized failure to a safe session-expired message', () {
    expect(
      failureMessage(const AppFailure.unauthorized()),
      'Your session has expired. Please sign in again.',
    );
  });
}
