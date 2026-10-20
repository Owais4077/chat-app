import 'dart:async';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  AppUser? currentUser() => _user;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _user = AppUser(id: 'demo-user', email: email.trim());
    _controller.add(_user);
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    await signIn(email: email, password: password);
    return SignUpResult.authenticated;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
