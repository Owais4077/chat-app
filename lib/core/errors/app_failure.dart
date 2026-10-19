sealed class AppFailure {
  const AppFailure();

  const factory AppFailure.unauthorized() = UnauthorizedFailure;
  const factory AppFailure.network() = NetworkFailure;
  const factory AppFailure.validation(String message) = ValidationFailure;
  const factory AppFailure.unknown() = UnknownFailure;
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure();
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(this.message);

  final String message;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure();
}
