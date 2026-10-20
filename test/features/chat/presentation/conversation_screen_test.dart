import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/features/chat/data/mock_chat_repository.dart';
import 'package:relay_messenger/features/chat/presentation/conversation_screen.dart';
void main() { testWidgets('sends typed message', (tester) async { await tester.pumpWidget(MaterialApp(home: ConversationScreen(repository: MockChatRepository(), conversationId: 'demo-conversation'))); await tester.enterText(find.byType(TextField), 'Hi there'); await tester.tap(find.bySemanticsLabel('Send message')); await tester.pump(); expect(find.text('Hi there'), findsOneWidget); }); }
