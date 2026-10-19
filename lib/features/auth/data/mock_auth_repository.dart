import 'dart:async';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
class MockAuthRepository implements AuthRepository { final _controller = StreamController<AppUser?>.broadcast(); @override Stream<AppUser?> authStateChanges() => _controller.stream; @override Future<void> signIn({required String email, required String password}) async => _controller.add(AppUser(id: 'demo-user', email: email)); @override Future<void> signOut() async => _controller.add(null); }
