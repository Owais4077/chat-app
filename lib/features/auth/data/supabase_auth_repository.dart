import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<AppUser?> authStateChanges() => _client.auth.onAuthStateChange.map(
    (state) => _toAppUser(state.session?.user),
  );

  @override
  AppUser? currentUser() => _toAppUser(_client.auth.currentUser);

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    return response.session == null
        ? SignUpResult.confirmationRequired
        : SignUpResult.authenticated;
  }

  @override
  Future<void> sendEmailOtp({required String email}) async {
    await _client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
    );
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.email,
      email: email.trim(),
      token: token.trim(),
    );
  }

  @override
  Future<void> sendPhoneOtp({required String phone}) async {
    await _client.auth.signInWithOtp(
      phone: phone.trim(),
      shouldCreateUser: true,
    );
  }

  @override
  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone.trim(),
      token: token.trim(),
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  static AppUser? _toAppUser(User? user) =>
      user == null ? null : AppUser(id: user.id, email: user.email ?? '');
}
