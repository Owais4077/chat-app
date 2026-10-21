import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import 'auth_providers.dart';

String registrationErrorMessage(Object error) {
  final message = error.toString().toLowerCase();
  if (message.contains('already registered') ||
      message.contains('already exists')) {
    return 'An account already exists for this email. Sign in instead.';
  }
  if (message.contains('password') && message.contains('least')) {
    return 'Use a stronger password and try again.';
  }
  if (message.contains('email') && message.contains('valid')) {
    return 'Enter a valid email address.';
  }
  if (message.contains('rate limit')) {
    return 'Too many attempts. Please wait a few minutes and try again.';
  }
  return 'Unable to create your account. Check your internet connection and try again.';
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .signUp(email: _email.text, password: _password.text);
      if (mounted) {
        setState(
          () => _message = result == SignUpResult.confirmationRequired
              ? 'Check your email to confirm your account.'
              : 'Account created.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = registrationErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create account')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create your CHAT APP account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter your email address.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'Use at least 8 characters.';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(v) ||
                        !RegExp(r'[a-z]').hasMatch(v) ||
                        !RegExp(r'\d').hasMatch(v)) {
                      return 'Use uppercase, lowercase letters, and a number.';
                    }
                    return null;
                  },
                ),
                if (_message case final message?)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(message),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Creating account…' : 'Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
