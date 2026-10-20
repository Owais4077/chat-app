import 'package:flutter/material.dart';
class EmptyState extends StatelessWidget { const EmptyState({super.key, required this.title}); final String title; @override Widget build(BuildContext context) => Center(child: Text(title)); }
