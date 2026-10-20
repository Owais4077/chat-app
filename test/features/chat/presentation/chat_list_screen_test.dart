import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/presentation/chat_list_screen.dart';

void main() {
  testWidgets('shows an empty conversations state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatListScreen()));

    expect(find.text('No conversations yet'), findsOneWidget);
  });
}
