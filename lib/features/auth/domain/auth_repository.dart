import 'app_user.dart';

enum SignUpResult { authenticated, confirmationRequired }

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? currentUser();
  Future<void> signIn({required String email, required String password});
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  });
  Future<void> signOut();
}
