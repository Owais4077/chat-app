sealed class AppFailure {
  const AppFailure();

  const factory AppFailure.unauthorized() = UnauthorizedFailure;
  const factory AppFailure.network([String? message]) = NetworkFailure;
  const factory AppFailure.validation(String message) = ValidationFailure;
  const factory AppFailure.unknown([String? message]) = UnknownFailure;

  String? get messageText => switch (this) {
    ValidationFailure(message: final m) => m,
    NetworkFailure(message: final m) => m,
    UnknownFailure(message: final m) => m,
    UnauthorizedFailure() => 'Unauthorized',
  };
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure();
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([this.message]);
  final String? message;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(this.message);
  final String message;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([this.message]);
  final String? message;
}
