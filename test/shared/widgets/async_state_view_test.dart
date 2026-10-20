import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/shared/widgets/async_state_view.dart';
void main() { testWidgets('loading state has an accessible label', (tester) async { await tester.pumpWidget(const MaterialApp(home: AsyncStateView<String>.loading())); expect(find.bySemanticsLabel('Loading'), findsOneWidget); }); }
