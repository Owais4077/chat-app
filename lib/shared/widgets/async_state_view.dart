import 'package:flutter/material.dart';
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView.loading({super.key}) : child = null;
  const AsyncStateView.content({super.key, required this.child});
  final Widget? child;
  @override Widget build(BuildContext context) => child ?? const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading'));
}
