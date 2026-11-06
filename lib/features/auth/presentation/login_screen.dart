import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/route_paths.dart';
import 'auth_providers.dart';

enum LoginMode { password, phoneOtp, emailOtp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _otpToken = TextEditingController();

  LoginMode _mode = LoginMode.password;
  bool _otpSent = false;
  var _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _otpToken.dispose();
    super.dispose();
  }

  Future<void> _submitPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text.trim(), password: _password.text);
      if (mounted) context.go(RoutePaths.chats);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = _loginErrorMessage(error));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to sign in. Check your details and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPhoneOtp() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty || !RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      setState(() => _error = 'Enter a valid international phone number (e.g. +923001234567).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPhoneOtp(phone: phone);
      if (mounted) {
        setState(() {
          _otpSent = true;
          _info = 'Verification code sent to $phone';
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not send verification code: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyPhoneOtp() async {
    final token = _otpToken.text.trim();
    if (token.isEmpty || token.length < 4) {
      setState(() => _error = 'Enter the 6-digit verification code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyPhoneOtp(
        phone: _phone.text.trim(),
        token: token,
      );
      if (mounted) context.go(RoutePaths.chats);
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Invalid verification code: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendEmailOtp() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailOtp(email: email);
      if (mounted) {
        setState(() {
          _otpSent = true;
          _info = 'Verification code sent to $email. Please check your inbox and Spam folder.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not send verification code: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyEmailOtp() async {
    final token = _otpToken.text.trim();
    if (token.isEmpty || token.length < 4) {
      setState(() => _error = 'Enter the 6-digit verification code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyEmailOtp(
        email: _email.text.trim(),
        token: token,
      );
      if (mounted) context.go(RoutePaths.chats);
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Invalid verification code: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sign in')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Sign in to Relay',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fast, secure messaging combining WhatsApp and WeChat',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<LoginMode>(
                      segments: const [
                        ButtonSegment(
                          value: LoginMode.password,
                          label: Text('Password'),
                          icon: Icon(Icons.lock_outline),
                        ),
                        ButtonSegment(
                          value: LoginMode.phoneOtp,
                          label: Text('Phone OTP'),
                          icon: Icon(Icons.phone_android),
                        ),
                        ButtonSegment(
                          value: LoginMode.emailOtp,
                          label: Text('Email OTP'),
                          icon: Icon(Icons.mail_outline),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _mode = selected.first;
                          _otpSent = false;
                          _error = null;
                          _info = null;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_mode == LoginMode.password) ...[
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter your email address.'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your password.'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submitPassword,
                        child: Text(_busy ? 'Signing in…' : 'Sign in'),
                      ),
                    ] else if (_mode == LoginMode.phoneOtp) ...[
                      if (!_otpSent) ...[
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number (with country code)',
                            hintText: '+923001234567',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We will send a 6-digit OTP code to verify your phone.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _busy ? null : _sendPhoneOtp,
                          icon: const Icon(Icons.send),
                          label: Text(_busy ? 'Sending OTP…' : 'Send verification code'),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _otpToken,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            labelText: 'Enter 6-digit OTP code',
                            hintText: '123456',
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _verifyPhoneOtp,
                          child: Text(_busy ? 'Verifying…' : 'Verify & Sign in'),
                        ),
                        TextButton(
                          onPressed: _busy ? null : () => setState(() => _otpSent = false),
                          child: const Text('Change phone number'),
                        ),
                      ],
                    ] else if (_mode == LoginMode.emailOtp) ...[
                      if (!_otpSent) ...[
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            hintText: 'user@example.com',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We will send a 6-digit OTP login code to your email inbox.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _busy ? null : _sendEmailOtp,
                          icon: const Icon(Icons.send),
                          label: Text(_busy ? 'Sending OTP…' : 'Send verification code'),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _otpToken,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            labelText: 'Enter 6-digit OTP code',
                            hintText: '123456',
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _verifyEmailOtp,
                          child: Text(_busy ? 'Verifying…' : 'Verify & Sign in'),
                        ),
                        TextButton(
                          onPressed: _busy ? null : () => setState(() => _otpSent = false),
                          child: const Text('Change email address'),
                        ),
                      ],
                    ],
                    if (_info case final info?)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          info,
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                      ),
                    if (_error case final error?)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => context.go(RoutePaths.register),
                      child: const Text('New to Relay? Create an account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

String _loginErrorMessage(AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('invalid login credentials') ||
      message.contains('invalid credentials')) {
    return 'Incorrect email or password.';
  }
  if (message.contains('email not confirmed')) {
    return 'Confirm your email, then try signing in again.';
  }
  if (message.contains('rate limit')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  return 'Unable to sign in. Check your connection and try again.';
}
