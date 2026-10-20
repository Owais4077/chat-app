import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/main.dart';

void main() {
  testWidgets('application renders a MaterialApp from the root widget',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RelayApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
