import 'package:flutter/material.dart';

class FeatureScreen extends StatelessWidget {
  const FeatureScreen({super.key, required this.title, this.message});
  final String title;
  final String? message;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text(message ?? title)),
  );
}
