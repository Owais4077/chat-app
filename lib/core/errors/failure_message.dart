import 'app_failure.dart';

String failureMessage(AppFailure failure) => switch (failure) {
  UnauthorizedFailure() => 'Your session has expired. Please sign in again.',
  NetworkFailure() => 'Check your internet connection and try again.',
  ValidationFailure(:final message) => message,
  UnknownFailure() => 'Something went wrong. Please try again.',
};
