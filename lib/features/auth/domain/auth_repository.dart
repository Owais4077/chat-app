import 'app_user.dart';

enum SignUpResult { authenticated, confirmationRequired }

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? currentUser();
  Future<void> signIn({required String email, required String password});
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  });
  Future<void> sendEmailOtp({required String email}) async {}
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {}
  Future<void> sendPhoneOtp({required String phone}) async {}
  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {}
  Future<void> signOut();
}
